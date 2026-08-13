#!/usr/bin/env python3

import argparse
import importlib.util
import logging
import os
import queue
import signal
import sys
import threading

# =========================
# Configuration
# =========================

DEFAULT_CHUNK_SIZE = 4 * 1024 * 1024  # 4 MB
DEFAULT_WORKERS = os.cpu_count() or 4
QUEUE_MULTIPLIER = 2  # controls backpressure

STOP = object()

# =========================
# Logging
# =========================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

log = logging.getLogger("chunkyboi")

# =========================
# Transform loading
# =========================

def load_transform(path):
    if not path:
        log.warning("Transform not provided, running default endian transform")
        return default_transform

    spec = importlib.util.spec_from_file_location("user_transform", path)
    if not spec or not spec.loader:
        raise RuntimeError("Invalid transform module")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    if not hasattr(module, "transform"):
        raise RuntimeError("Transform module must expose transform(data: bytes, config: dict)")

    return module.transform

# =========================
# Default transform
# =========================

def default_transform(data: bytes, config: dict) -> bytes:
    # endian flip = reverse byte order
    return data[::-1]

# =========================
# Worker thread
# =========================

def worker_loop(work_q, result_q, transform, config, stop_event):
    try:
        while not stop_event.is_set():
            item = work_q.get()
            if item is STOP:
                work_q.put(STOP)
                return

            index, data = item
            try:
                out = transform(data, config)
                result_q.put((index, out))
            except Exception as e:
                result_q.put(("ERROR", e))
                stop_event.set()
                return
            finally:
                work_q.task_done()
    except Exception as e:
        result_q.put(("ERROR", e))
        stop_event.set()

# =========================
# Ordered streaming writer
# =========================

def writer_loop(result_q, out_fh, stop_event):
    next_index = 0
    pending = {}

    while not stop_event.is_set():
        item = result_q.get()

        if item is STOP:
            break

        if item[0] == "ERROR":
            stop_event.set()
            raise item[1]

        index, data = item
        pending[index] = data

        while next_index in pending:
            out_fh.write(pending.pop(next_index))
            next_index += 1

# =========================
# Main
# =========================

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--chunk-size", type=int, default=DEFAULT_CHUNK_SIZE)
    parser.add_argument("--workers", type=int, default=DEFAULT_WORKERS)
    parser.add_argument("--transform")
    parser.add_argument("--config")

    args = parser.parse_args()

    config = {}
    if args.config:
        if os.path.isfile(args.config):
            with open(args.config, "r") as fh:
                config["password"] = fh.read().strip()
        else:
            config["password"] = args.config

    transform = load_transform(args.transform)

    work_q = queue.Queue(maxsize=args.workers * QUEUE_MULTIPLIER)
    result_q = queue.Queue(maxsize=args.workers * QUEUE_MULTIPLIER)
    stop_event = threading.Event()

    def shutdown(*_):
        log.error("Shutdown triggered")
        stop_event.set()
        work_q.put(STOP)
        result_q.put(STOP)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    workers = []
    for _ in range(args.workers):
        t = threading.Thread(
            target=worker_loop,
            args=(work_q, result_q, transform, config, stop_event),
            daemon=True
        )
        t.start()
        workers.append(t)

    try:
        with open(args.input, "rb") as in_fh, open(args.output, "wb") as out_fh:
            writer = threading.Thread(
                target=writer_loop,
                args=(result_q, out_fh, stop_event),
                daemon=True
            )
            writer.start()

            index = 0
            while not stop_event.is_set():
                chunk = in_fh.read(args.chunk_size)
                if not chunk:
                    break
                work_q.put((index, chunk))
                index += 1

            work_q.put(STOP)
            work_q.join()
            result_q.put(STOP)
            writer.join()

    except Exception as e:
        log.exception("Fatal error")
        sys.exit(1)

    log.info("Processing complete")

if __name__ == "__main__":
    main()

