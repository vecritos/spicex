#!/usr/bin/env python3

import os
import sys
import argparse
import logging
import threading
import importlib.util
import json
from concurrent.futures import ThreadPoolExecutor, as_completed

# Optional config formats
try:
    import yaml
except ImportError:
    yaml = None

try:
    import tomllib
except ImportError:
    tomllib = None


# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("chunkyboi")


# ─────────────────────────────────────────────
# Global thread pool
# ─────────────────────────────────────────────

_executor = None
_executor_lock = threading.Lock()


def init_thread_pool(max_workers: int):
    global _executor
    with _executor_lock:
        if _executor is None:
            _executor = ThreadPoolExecutor(max_workers=max_workers)
            logger.info("Thread pool initialized (%d workers)", max_workers)


def shutdown_thread_pool():
    global _executor
    with _executor_lock:
        if _executor:
            _executor.shutdown(wait=True)
            _executor = None
            logger.info("Thread pool shut down")


# ─────────────────────────────────────────────
# Config resolution
# ─────────────────────────────────────────────

def load_config(config_arg: str) -> dict:
    """
    --config behavior:
      • if path exists → load config file
      • else → treat value as password string
    """

    if os.path.isfile(config_arg):
        ext = os.path.splitext(config_arg)[1].lower()

        with open(config_arg, "rb") as f:
            if ext == ".json":
                cfg = json.load(f)
            elif ext in (".yaml", ".yml"):
                if not yaml:
                    raise RuntimeError("pyyaml not installed")
                cfg = yaml.safe_load(f)
            elif ext == ".toml":
                if not tomllib:
                    raise RuntimeError("tomllib not available")
                cfg = tomllib.load(f)
            else:
                raise ValueError(f"Unsupported config format: {ext}")

        cfg = dict(cfg or {})
        cfg.setdefault("password", None)

        logger.info("Loaded config file: %s", config_arg)
        return cfg

    logger.info("Using --config value as password")
    return {
        "password": config_arg
    }


# ─────────────────────────────────────────────
# Default transform (naïve endian flip)
# ─────────────────────────────────────────────

def default_transform(
    data: bytes,
    *,
    config: dict,
    chunk_index: int,
    is_first: bool,
    is_last: bool,
):
    # Naïve endian transform: reverse byte order of the chunk
    return data[::-1]


# ─────────────────────────────────────────────
# Transform loader
# ─────────────────────────────────────────────

def load_transform_or_default(path: str | None):
    if not path:
        logger.warning(
            "Transform not provided, running default endian-flip transform"
        )
        return default_transform

    if not os.path.isfile(path):
        raise FileNotFoundError(f"Transform file not found: {path}")

    spec = importlib.util.spec_from_file_location("user_transform", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    if not hasattr(module, "transform"):
        raise RuntimeError(
            "Transform file must define: transform(data: bytes, **kwargs) -> bytes"
        )

    logger.info("Loaded transform: %s", path)
    return module.transform


# ─────────────────────────────────────────────
# Chunk processing
# ─────────────────────────────────────────────

def process_chunk(
    index: int,
    data: bytes,
    transform_fn,
    config: dict,
    is_first: bool,
    is_last: bool,
):
    try:
        output = transform_fn(
            data,
            config=config,
            chunk_index=index,
            is_first=is_first,
            is_last=is_last,
        )

        if not isinstance(output, (bytes, bytearray)):
            raise TypeError("transform() must return bytes")

        return index, bytes(output)

    except Exception as e:
        raise RuntimeError(f"Transform failed on chunk {index}") from e


# ─────────────────────────────────────────────
# Pipeline
# ─────────────────────────────────────────────

def run_pipeline(
    input_path: str,
    output_path: str,
    transform_fn,
    config: dict,
    chunk_size: int,
):
    if _executor is None:
        raise RuntimeError("Thread pool not initialized")

    futures = {}
    total_chunks = 0

    # Dispatch phase (streamed)
    with open(input_path, "rb") as src:
        index = 0
        while True:
            chunk = src.read(chunk_size)
            if not chunk:
                break

            fut = _executor.submit(
                process_chunk,
                index,
                chunk,
                transform_fn,
                config,
                index == 0,
                False,  # naive last flag
            )
            futures[fut] = index
            index += 1

        total_chunks = index

    # Collect results
    results = [None] * total_chunks
    for fut in as_completed(futures):
        idx, out = fut.result()
        results[idx] = out

    # Write deterministically
    with open(output_path, "wb") as out:
        for block in results:
            out.write(block)

    logger.info(
        "Completed: %s → %s (%d chunks)",
        input_path,
        output_path,
        total_chunks,
    )


# ─────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="chunkyboi — parallel binary transformation engine"
    )

    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--transform",
        required=False,
        help="Path to Python transform file (optional)",
    )
    parser.add_argument("--config", required=True)
    parser.add_argument("--chunk-size", type=int, default=4 * 1024 * 1024)
    parser.add_argument("--workers", type=int, default=os.cpu_count() or 4)

    args = parser.parse_args()

    try:
        init_thread_pool(args.workers)

        config = load_config(args.config)
        transform_fn = load_transform_or_default(args.transform)

        run_pipeline(
            input_path=args.input,
            output_path=args.output,
            transform_fn=transform_fn,
            config=config,
            chunk_size=args.chunk_size,
        )

    except Exception as e:
        logger.critical("Fatal error: %s", e, exc_info=True)
        sys.exit(1)

    finally:
        shutdown_thread_pool()


if __name__ == "__main__":
    main()

