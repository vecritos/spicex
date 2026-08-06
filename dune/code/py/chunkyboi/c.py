#!/usr/bin/env python3

import os
import sys
import argparse
import logging
import threading
import importlib.util
from concurrent.futures import ThreadPoolExecutor, as_completed

# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("chunkyboi")

# ─────────────────────────────────────────────
# Thread pool (global but controlled)
# ─────────────────────────────────────────────

_executor = None
_executor_lock = threading.Lock()


def init_global_thread_pool(max_workers: int):
    global _executor
    with _executor_lock:
        if _executor is None:
            _executor = ThreadPoolExecutor(max_workers=max_workers)
            logger.info("Thread pool initialized (%d workers)", max_workers)


def cleanup_global_thread_pool():
    global _executor
    with _executor_lock:
        if _executor:
            _executor.shutdown(wait=True)
            _executor = None
            logger.info("Thread pool shut down")


# ─────────────────────────────────────────────
# Transform loader (behavior injection)
# ─────────────────────────────────────────────

def load_transform_from_file(path: str):
    if not os.path.isfile(path):
        raise FileNotFoundError(f"Transform file not found: {path}")

    spec = importlib.util.spec_from_file_location("user_transform", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    if not hasattr(module, "transform"):
        raise AttributeError(
            f"{path} must define: transform(data: bytes) -> bytes"
        )

    transform_fn = module.transform

    # Sanity check
    test_out = transform_fn(b"test")
    if not isinstance(test_out, (bytes, bytearray)):
        raise TypeError("transform() must return bytes")

    logger.info("Loaded transform from %s", path)
    return transform_fn


# ─────────────────────────────────────────────
# Chunk processing
# ─────────────────────────────────────────────

def process_chunk(index: int, data: bytes, transform_fn):
    try:
        transformed = transform_fn(data)
        return index, transformed
    except Exception as e:
        raise RuntimeError(f"Transform failed on chunk {index}") from e


# ─────────────────────────────────────────────
# Pipeline
# ─────────────────────────────────────────────

def run_pipeline(
    src_path: str,
    output_path: str,
    transform_fn,
    chunk_size: int,
):
    if _executor is None:
        raise RuntimeError("Thread pool not initialized")

    futures = {}
    total_chunks = 0

    with open(src_path, "rb") as f:
        chunk_index = 0
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break

            fut = _executor.submit(
                process_chunk,
                chunk_index,
                chunk,
                transform_fn,
            )
            futures[fut] = chunk_index
            chunk_index += 1

        total_chunks = chunk_index

    logger.info("Dispatched %d chunks", total_chunks)

    # Collect results
    results = [None] * total_chunks

    for fut in as_completed(futures):
        idx, transformed = fut.result()
        results[idx] = transformed

    # Write output in order
    with open(output_path, "wb") as out:
        for block in results:
            out.write(block)

    logger.info("Wrote output to %s", output_path)


# ─────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="chunkyboi – parallel binary transformer"
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Input binary file",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output binary file",
    )
    parser.add_argument(
        "--transform",
        required=True,
        help="Path to Python transform file",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=4 * 1024 * 1024,
        help="Chunk size in bytes (default: 4MB)",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=os.cpu_count() or 4,
        help="Number of worker threads",
    )

    args = parser.parse_args()

    try:
        init_global_thread_pool(args.workers)

        transform_fn = load_transform_from_file(args.transform)

        run_pipeline(
            src_path=args.input,
            output_path=args.output,
            transform_fn=transform_fn,
            chunk_size=args.chunk_size,
        )

    except Exception as e:
        logger.critical("Fatal error: %s", e, exc_info=True)
        sys.exit(1)

    finally:
        cleanup_global_thread_pool()


if __name__ == "__main__":
    main()

