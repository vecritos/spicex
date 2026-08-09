#!/usr/bin/env python3

import argparse
import importlib.util
import json
import logging
import multiprocessing
import os
import queue
import resource
import signal
import sys
import threading
import time
from multiprocessing.connection import Connection

# =========================
# Config and constants
# =========================

DEFAULT_CHUNK_SIZE = 4 * 1024 * 1024  # 4MB
DEFAULT_WORKERS = os.cpu_count() or 4
QUEUE_MULTIPLIER = 2
TRANSFORM_TIMEOUT = 30  # seconds per chunk max runtime
MEMORY_LIMIT_MB = 512  # per-transform memory limit on Linux

STOP = "STOP"
ERROR = "ERROR"

# =========================
# Logging setup
# =========================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("chunkyboi")

# =========================
# Helper: load config
# =========================

def load_config(config_arg):
    if not config_arg:
        return {"password": None}
    if os.path.isfile(config_arg):
        with open(config_arg, "r") as f:
            try:
                return json.load(f)
            except Exception:
                # fallback: treat whole file as password string
                f.seek(0)
                return {"password": f.read().strip()}
    else:
        return {"password": config_arg}

# =========================
# Default transform
# =========================

def default_transform(data: bytes, config: dict) -> bytes:
    # Naive endian flip: reverse bytes
    return data[::-1]

# =========================
# Subprocess transform runner
# =========================

def set_resource_limits():
    """Apply memory and CPU limits on Linux."""
    if sys.platform.startswith("linux"):
        # Limit virtual memory
        mem_bytes = MEMORY_LIMIT_MB * 1024 * 1024
        resource.setrlimit(resource.RLIMIT_AS, (mem_bytes, mem_bytes))

        # Limit CPU time to TRANSFORM_TIMEOUT + 5 seconds grace
        cpu_seconds = TRANSFORM_TIMEOUT + 5
        resource.setrlimit(resource.RLIMIT_CPU, (cpu_seconds, cpu_seconds))

def transform_worker(
    transform_path: str,
    config_json: str,
    conn: Connection,
):
    """
    Worker subprocess:
    - Loads transform function dynamically
    - Applies resource limits
    - Reads chunks from conn.recv()
    - Applies transform(data, config)
    - Sends back (index, result_bytes) or error
    """
    try:
        set_resource_limits()
    except Exception as e:
        conn.send((ERROR, f"Resource limit setup failed: {e}"))
        conn.close()
        return

    # Load transform function
    try:
        spec = importlib.util.spec_from_file_location("user_transform", transform_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        transform = getattr(module, "transform")
    except Exception as e:
        conn.send((ERROR, f"Failed to load transform: {e}"))
        conn.close()
        return

    # Parse config once
    try:
        config = json.loads(config_json)
    except Exception as e:
        conn.send((ERROR, f"Failed to parse config JSON: {e}"))
        conn.close()
        return

    # Main loop: receive chunks, transform, send results
    try:
        while True:
            msg = conn.recv()
            if msg == STOP:
                break

            index, chunk = msg

            # Time-limited transform call
            start_time = time.monotonic()
            try:
                result = transform(chunk, config)
                if not isinstance(result, (bytes, bytearray)):
                    raise TypeError("Transform must return bytes")
            except Exception as e:
                conn.send((ERROR, f"Transform error on chunk {index}: {e}"))
                continue

            elapsed = time.monotonic() - start_time
            if elapsed > TRANSFORM_TIMEOUT:
                conn.send((ERROR, f"Transform timeout on chunk {index}"))
                continue

            conn.send((index, bytes(result)))

    except EOFError:
        pass  # main process closed connection
    except Exception as e:
        conn.send((ERROR, f"Worker fatal error: {e}"))
    finally:
        conn.close()

# =========================
# Controller process
# =========================

class TransformSandbox:
    def __init__(self, transform_path, config, workers):
        self.transform_path = transform_path
        self.config_json = json.dumps(config)
        self.workers = workers
        self.pool = []
        self.conns = []  # parent connections
        self.stop_event = threading.Event()

        # Queues for main thread
        self.work_queue = queue.Queue(maxsize=workers * QUEUE_MULTIPLIER)
        self.result_queue = queue.Queue(maxsize=workers * QUEUE_MULTIPLIER)

        # Ordering structures
        self.pending = {}
        self.next_index = 0

    def start(self):
        logger.info("Starting sandbox with %d workers", self.workers)
        for _ in range(self.workers):
            parent_conn, child_conn = multiprocessing.Pipe()
            p = multiprocessing.Process(
                target=transform_worker,
                args=(self.transform_path, self.config_json, child_conn),
                daemon=True,
            )
            p.start()
            self.pool.append(p)
            self.conns.append(parent_conn)

        # Start worker threads for sending/receiving data
        self.sender_thread = threading.Thread(target=self._sender_loop, daemon=True)
        self.receiver_thread = threading.Thread(target=self._receiver_loop, daemon=True)

        self.sender_thread.start()
        self.receiver_thread.start()

    def _sender_loop(self):
        """
        Sends chunks from work_queue to subprocesses round robin.
        """
        conn_count = len(self.conns)
        idx = 0
        try:
            while not self.stop_event.is_set():
                item = self.work_queue.get()
                if item == STOP:
                    for conn in self.conns:
                        conn.send(STOP)
                    return

                index, chunk = item
                conn = self.conns[idx % conn_count]
                conn.send((index, chunk))
                idx += 1
                self.work_queue.task_done()
        except Exception as e:
            logger.error("Sender loop error: %s", e)
            self.stop_event.set()

    def _receiver_loop(self):
        """
        Receives transformed chunks from subprocesses.
        """
        conn_count = len(self.conns)
        try:
            while not self.stop_event.is_set():
                for conn in self.conns:
                    if conn.poll(0.1):
                        msg = conn.recv()
                        if isinstance(msg, tuple) and len(msg) == 2:
                            if msg[0] == ERROR:
                                logger.error("Transform error: %s", msg[1])
                                self.stop_event.set()
                                return
                            else:
                                index, data = msg
                                self.result_queue.put((index, data))
        except Exception as e:
            logger.error("Receiver loop error: %s", e)
            self.stop_event.set()

    def put_chunk(self, index, chunk):
        self.work_queue.put((index, chunk))

    def get_result(self):
        try:
            return self.result_queue.get(timeout=1)
        except queue.Empty:
            return None

    def stop(self):
        self.stop_event.set()
        try:
            self.work_queue.put(STOP)
        except Exception:
            pass

        for conn in self.conns:
            try:
                conn.close()
            except Exception:
                pass

        for p in self.pool:
            if p.is_alive():
                p.terminate()
                p.join()

        logger.info("Sandbox stopped")

# =========================
# Writer thread to preserve order
# =========================

def ordered_writer(output_path, result_queue, stop_event, total_chunks):
    next_index = 0
    pending = {}

    with open(output_path, "wb") as out_fh:
        while not stop_event.is_set():
            try:
                item = result_queue.get(timeout=1)
            except queue.Empty:
                continue

            if item == STOP:
                break

            index, data = item
            pending[index] = data

            while next_index in pending:
                out_fh.write(pending.pop(next_index))
                next_index += 1
                if next_index == total_chunks:
                    stop_event.set()
                    break

# =========================
# Main CLI entrypoint
# =========================

def main():
    parser = argparse.ArgumentParser(description="chunkyboi with sandboxed transforms")
    parser.add_argument("input", help="Input file path")
    parser.add_argument("output", help="Output file path")
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=DEFAULT_CHUNK_SIZE,
        help="Chunk size in bytes (default: 4MB)",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=DEFAULT_WORKERS,
        help="Number of parallel transform worker processes",
    )
    parser.add_argument(
        "--transform",
        help="Path to user transform Python file (must define transform(data: bytes, config: dict) -> bytes)",
    )
    parser.add_argument(
        "--config",
        help="Config password string or path to JSON config file",
    )
    args = parser.parse_args()

    # Load config (password or JSON)
    config = load_config(args.config)

    # Use default transform if none provided
    transform_path = args.transform
    if not transform_path:
        logger.warning("No transform provided, using default endian-flip")

        # Write default transform to a temporary file for subprocess use
        import tempfile

        with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as tf:
            tf.write(
                "def transform(data, config):\n"
                "    return data[::-1]\n"
            )
            transform_path = tf.name

    sandbox = TransformSandbox(transform_path, config, args.workers)
    sandbox.start()

    total_chunks = 0
    stop_event = threading.Event()

    writer_thread = threading.Thread(
        target=ordered_writer,
        args=(args.output, sandbox.result_queue, stop_event, None),
        daemon=True,
    )
    writer_thread.start()

    try:
        with open(args.input, "rb") as in_fh:
            while True:
                chunk = in_fh.read(args.chunk_size)
                if not chunk:
                    break
                sandbox.put_chunk(total_chunks, chunk)
                total_chunks += 1

        # Pass total_chunks to writer so it knows when to stop
        stop_event.wait(timeout=0.1)
        writer_thread._args = (args.output, sandbox.result_queue, stop_event, total_chunks)

        sandbox.work_queue.put(STOP)
        sandbox.work_queue.join()
        stop_event.set()
        writer_thread.join()

    except KeyboardInterrupt:
        logger.error("Interrupted by user")
        stop_event.set()
    except Exception as e:
        logger.exception("Fatal error: %s", e)
        stop_event.set()
    finally:
        sandbox.stop()

        if os.path.exists(transform_path) and not args.transform:
            # Remove temp default transform file
            try:
                os.remove(transform_path)
            except Exception:
                pass

    logger.info("Processing complete")

if __name__ == "__main__":
    main()

