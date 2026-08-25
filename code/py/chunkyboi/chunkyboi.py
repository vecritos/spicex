#!/usr/bin/env python3

import argparse
import importlib.util
import json
import os
import sys
import tempfile
import hashlib
from concurrent.futures import ThreadPoolExecutor, as_completed
import atexit

# -----------------------------
# Global thread pool
# -----------------------------

GLOBAL_THREAD_POOL = None

def init_global_thread_pool(max_workers: int):
    global GLOBAL_THREAD_POOL
    if GLOBAL_THREAD_POOL:
        GLOBAL_THREAD_POOL.shutdown(wait=True)
    GLOBAL_THREAD_POOL = ThreadPoolExecutor(max_workers=max_workers)

def cleanup_global_thread_pool():
    global GLOBAL_THREAD_POOL
    if GLOBAL_THREAD_POOL:
        GLOBAL_THREAD_POOL.shutdown(wait=True)
        GLOBAL_THREAD_POOL = None

# -----------------------------
# Utilities
# -----------------------------

def sha256_digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def load_transform(path: str):
    spec = importlib.util.spec_from_file_location("user_transform", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load transform file: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    if not hasattr(module, "transform"):
        raise RuntimeError("Transform file must define: transform(data: bytes, config: dict)")

    return module.transform

def load_config(value: str | None) -> dict:
    if value is None:
        return {}

    # If file exists, treat as config file
    if os.path.isfile(value):
        with open(value, "r", encoding="utf-8") as f:
            cfg = json.load(f)
        if not isinstance(cfg, dict):
            raise RuntimeError("Config file must contain a JSON object")
        return cfg

    # Otherwise treat as password/string
    return {"password": value}

# -----------------------------
# Chunk processing
# -----------------------------

def process_chunk_to_temp(index, data, temp_dir, transform_fn, config):
    transformed = transform_fn(data, config)
    digest = sha256_digest(transformed)

    path = os.path.join(temp_dir, f"chunk_{index:08d}.tmp")
    with open(path, "wb") as f:
        f.write(transformed)

    return index, path, len(transformed), digest

def parallel_transform(src_path, temp_dir, chunk_size, transform_fn, config):
    if GLOBAL_THREAD_POOL is None:
        raise RuntimeError("Thread pool not initialized")

    futures = []
    results = []

    with open(src_path, "rb") as src:
        idx = 0
        while True:
            chunk = src.read(chunk_size)
            if not chunk:
                break
            futures.append(
                GLOBAL_THREAD_POOL.submit(
                    process_chunk_to_temp,
                    idx,
                    chunk,
                    temp_dir,
                    transform_fn,
                    config,
                )
            )
            idx += 1

        for f in as_completed(futures):
            results.append(f.result())

    return results

def merge_and_validate(output_path, temp_chunks):
    temp_chunks.sort(key=lambda x: x[0])
    offset = 0
    metadata = []

    with open(output_path, "wb") as out:
        for idx, path, length, expected_hash in temp_chunks:
            with open(path, "rb") as f:
                while buf := f.read(1024 * 1024):
                    out.write(buf)
            metadata.append((offset, length, expected_hash))
            offset += length

    with open(output_path, "rb") as out:
        for offset, length, expected_hash in metadata:
            out.seek(offset)
            data = out.read(length)
            if sha256_digest(data) != expected_hash:
                raise RuntimeError("Integrity check failed")

# -----------------------------
# Pipeline
# -----------------------------

def run_pipeline(input_path, output_path, transform_fn, config, chunk_size):
    with tempfile.TemporaryDirectory() as tmp:
        chunks = parallel_transform(
            input_path,
            tmp,
            chunk_size,
            transform_fn,
            config,
        )
        merge_and_validate(output_path, chunks)

# -----------------------------
# Default transform (endianness flip)
# -----------------------------

def default_transform(data: bytes, config: dict) -> bytes:
    return data[::-1]

# -----------------------------
# CLI
# -----------------------------

def main():
    parser = argparse.ArgumentParser(
        description="chunkyboi – chunked binary transform engine"
    )

    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--transform", help="Path to transform .py file")
    parser.add_argument("--config", help="Password or config file")
    parser.add_argument("--chunk-size", type=int, default=4 * 1024 * 1024)
    parser.add_argument("--threads", type=int, default=4)

    args = parser.parse_args()

    init_global_thread_pool(args.threads)
    atexit.register(cleanup_global_thread_pool)

    config = load_config(args.config)

    if args.transform:
        transform_fn = load_transform(args.transform)
    else:
        print("Transform not provided, running default endian transform")
        transform_fn = default_transform

    run_pipeline(
        input_path=args.input,
        output_path=args.output,
        transform_fn=transform_fn,
        config=config,
        chunk_size=args.chunk_size,
    )

    print("Processing complete")

if __name__ == "__main__":
    main()

