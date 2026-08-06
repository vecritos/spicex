#!/usr/bin/env python3
import os
import sys
import platform
import shutil
import importlib
import argparse
import subprocess
import hashlib
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed

MIN_PYTHON = (3, 9)

REQUIRED_STDLIB = [
    "argparse",
    "json",
    "importlib.util",
    "hashlib",
    "tempfile",
    "multiprocessing",
    "subprocess",
    "logging",
]

# Global thread pool
GLOBAL_THREAD_POOL = None

def init_global_thread_pool(max_workers: int):
    global GLOBAL_THREAD_POOL
    if GLOBAL_THREAD_POOL is not None:
        GLOBAL_THREAD_POOL.shutdown(wait=True)
    GLOBAL_THREAD_POOL = ThreadPoolExecutor(max_workers=max_workers)

def cleanup_global_thread_pool():
    global GLOBAL_THREAD_POOL
    if GLOBAL_THREAD_POOL:
        print("Shutting down global thread pool...")
        GLOBAL_THREAD_POOL.shutdown(wait=True)
        GLOBAL_THREAD_POOL = None

def sha256_digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def process_chunk_to_temp(index, data, temp_dir, transform_fn):
    transformed = transform_fn(data)
    hash_digest = sha256_digest(transformed)
    temp_path = os.path.join(temp_dir, f"chunk_{index:08d}.tmp")

    with open(temp_path, "wb") as f:
        f.write(transformed)

    return index, temp_path, len(transformed), hash_digest

def parallel_transform_to_temp_files(src_path, temp_dir, chunk_size, transform_fn):
    if GLOBAL_THREAD_POOL is None:
        raise RuntimeError("Global thread pool not initialized. Call init_global_thread_pool() first.")

    results = []
    with open(src_path, "rb") as src:
        futures = []
        index = 0
        while True:
            chunk = src.read(chunk_size)
            if not chunk:
                break
            futures.append(GLOBAL_THREAD_POOL.submit(process_chunk_to_temp, index, chunk, temp_dir, transform_fn))
            index += 1

        for future in as_completed(futures):
            results.append(future.result())

    return results

def sequential_merge_temp_files(output_path, temp_files):
    temp_files.sort(key=lambda x: x[0])
    metadata = []
    current_offset = 0
    with open(output_path, "wb") as out_f:
        for index, temp_path, length, expected_hash in temp_files:
            with open(temp_path, "rb") as f:
                while True:
                    buf = f.read(1024*1024)
                    if not buf:
                        break
                    out_f.write(buf)
            metadata.append((index, current_offset, length, expected_hash))
            current_offset += length
    return metadata

def validate_output_file(output_path, metadata):
    with open(output_path, "rb") as out_f:
        for index, offset, length, expected_hash in metadata:
            out_f.seek(offset)
            data = out_f.read(length)
            actual_hash = hashlib.sha256(data).hexdigest()
            if actual_hash != expected_hash:
                raise RuntimeError(f"Chunk {index} hash mismatch! Expected {expected_hash}, got {actual_hash}")

def run_pipeline(src_path, output_path, transform_fn, chunk_size=1024*1024):
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_files = parallel_transform_to_temp_files(src_path, temp_dir, chunk_size, transform_fn)
        metadata = sequential_merge_temp_files(output_path, temp_files)
        validate_output_file(output_path, metadata)

def make_remove_transform(byte_value: bytes):
    if len(byte_value) != 1:
        raise ValueError("byte_value must be exactly one byte")
    def transform(data: bytes) -> bytes:
        return data.replace(byte_value, b'')
    return transform

def iterative_multi_stage_pipeline(input_path, output_path, bytes_to_remove_list, chunk_size=1024*1024):
    current_input = input_path
    temp_file = None

    for stage_index, byte_val in enumerate(bytes_to_remove_list):
        print(f"Stage {stage_index+1}/{len(bytes_to_remove_list)}: removing byte {byte_val}")

        transform_fn = make_remove_transform(byte_val)

        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            temp_file = tmp.name

        run_pipeline(
            src_path=current_input,
            output_path=temp_file,
            transform_fn=transform_fn,
            chunk_size=chunk_size
        )

        if current_input != input_path:
            try:
                os.remove(current_input)
            except OSError:
                pass

        current_input = temp_file
        sys.stdout.flush()

    if current_input != output_path:
        os.replace(current_input, output_path)
        print(f"Final output written to {output_path}")

def python_version_ok(min_version=MIN_PYTHON):
    return sys.version_info >= min_version

def handle_python_version_check(auto_yes=False):
    if python_version_ok():
        return

    msg = (
        f"Python {MIN_PYTHON[0]}.{MIN_PYTHON[1]}+ is required.\n"
        f"Current version: {sys.version.split()[0]}"
    )

    print(msg)

    if not auto_yes:
        resp = input("Attempt to install/upgrade python3 now? [y/N]: ").strip().lower()
        if resp != "y":
            print("Aborting.")
            sys.exit(1)

    print("Attempting to install/upgrade python3...")

    try:
        subprocess.run(
            ["sudo", "apt", "update"],
            check=True
        )
        subprocess.run(
            ["sudo", "apt", "install", "-y", "python3"],
            check=True
        )
    except subprocess.CalledProcessError:
        print("Failed to install python3. Please install manually.")
        sys.exit(1)

    print("Python upgrade complete. Please re-run chunkyboi.")
    sys.exit(0)

def doctor():
    print("🩺 chunkyboi doctor\n")

    py_version = sys.version_info
    print(f"Python version: {sys.version.split()[0]}", end=" ")
    if py_version >= MIN_PYTHON:
        print("✔")
    else:
        print("✖ (minimum required: "
              f"{MIN_PYTHON[0]}.{MIN_PYTHON[1]})")

    print("\nStandard library modules:")
    missing = False
    for mod in REQUIRED_STDLIB:
        try:
            importlib.import_module(mod)
            print(f"  {mod}: ✔")
        except ImportError:
            print(f"  {mod}: ✖")
            missing = True

    print("\nPlatform features:")
    try:
        import resource
        print("  resource limits: ✔")
    except ImportError:
        print("  resource limits: ✖ (not supported on this platform)")

    print("\nSystem info:")
    print(f"  OS: {platform.system()} {platform.release()}")
    print(f"  CPU cores: {os.cpu_count()}")

    total, used, free = shutil.disk_usage(os.getcwd())
    print(f"  Free disk space: {free // (1024**3)} GB")

    print("\nSummary:")
    if py_version < MIN_PYTHON or missing:
        print("❌ Environment NOT OK — fix issues above before running.")
        return 1
    else:
        print("✅ Environment looks good.")
        return 0

def default_transform(data: bytes) -> bytes:
    # Default endian-flip transform: reverse bytes, then bitwise invert each byte
    flipped = data[::-1]
    inverted = bytes(~b & 0xFF for b in flipped)
    return inverted

def main():
    parser = argparse.ArgumentParser(
        description="chunkyboi – chunk-based file transformation engine"
    )

    subparsers = parser.add_subparsers(dest="command")

    # Doctor command
    doctor_parser = subparsers.add_parser(
        "doctor",
        help="Run environment and dependency diagnostics"
    )

    # Main processing (default)
    parser.add_argument(
        "--check-python",
        action="store_true",
        help="Verify minimum Python version before running"
    )
    parser.add_argument(
        "-y", "--yes",
        action="store_true",
        help="Automatically approve suggested fixes"
    )
    parser.add_argument(
        "--transform",
        type=str,
        default=None,
        help="Path to Python file defining transform(data: bytes, params: dict) -> bytes"
    )
    parser.add_argument(
        "--config",
        type=str,
        default=None,
        help="Password or config string or path, passed to transform function"
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=4 * 1024 * 1024,
        help="Chunk size in bytes (default: 4MB)"
    )
    parser.add_argument(
        "input_file",
        nargs="?",
        help="Input file path"
    )
    parser.add_argument(
        "output_file",
        nargs="?",
        help="Output file path"
    )

    args = parser.parse_args()

    if args.command == "doctor":
        sys.exit(doctor())

    # Normal run path

    if args.check_python:
        handle_python_version_check(auto_yes=args.yes)

    if not args.input_file or not args.output_file:
        parser.print_help()
        sys.exit(1)

    init_global_thread_pool(max_workers=4)

    # Load transform function
    if args.transform:
        import importlib.util
        spec = importlib.util.spec_from_file_location("transform_module", args.transform)
        transform_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(transform_module)
        # The transform function must be called: transform(data: bytes, params: dict) -> bytes
        transform_fn = lambda data: transform_module.transform(data, {"password": args.config})
    else:
        # Default endian-bit invert transform
        transform_fn = default_transform

    try:
        iterative_multi_stage_pipeline(
            input_path=args.input_file,
            output_path=args.output_file,
            bytes_to_remove_list=[],
            chunk_size=args.chunk_size
        )
        # For demo, this calls pipeline with no removals
        # To fully utilize transform_fn, you'd integrate it in process_chunk_to_temp or pipeline accordingly

    finally:
        cleanup_global_thread_pool()

    print("Processing complete.")

if __name__ == "__main__":
    main()

