import os
import tempfile
import hashlib
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

# Global thread pool, initialized once with default count
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
    """
    Iteratively runs the pipeline for each byte to remove.
    Uses temp files for intermediate stages to avoid recursion.
    """
    current_input = input_path
    temp_file = None

    for stage_index, byte_val in enumerate(bytes_to_remove_list):
        print(f"Stage {stage_index+1}/{len(bytes_to_remove_list)}: removing byte {byte_val}")

        transform_fn = make_remove_transform(byte_val)

        # Use NamedTemporaryFile for intermediate output, delete=False to manage manually
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            temp_file = tmp.name

        run_pipeline(
            src_path=current_input,
            output_path=temp_file,
            transform_fn=transform_fn,
            chunk_size=chunk_size
        )

        # If not first stage, remove previous intermediate file to save space
        if current_input != input_path:
            try:
                os.remove(current_input)
            except OSError:
                pass

        current_input = temp_file

        # IDEA ONLY: Print approximate progress
        # In real usage, you could add timing, chunk counts, or estimated percentage here.
        sys.stdout.flush()

    # Final move to desired output path if needed
    if current_input != output_path:
        os.replace(current_input, output_path)
        print(f"Final output written to {output_path}")

if __name__ == "__main__":
    import atexit

    # Initialize global thread pool with configurable max workers
    init_global_thread_pool(max_workers=4)

    # Register cleanup function to run on program exit
    atexit.register(cleanup_global_thread_pool)

    # Example bytes to remove list
    bytes_to_remove = [b'a', b'b', b'c']

    # Run the iterative multi-stage pipeline
    iterative_multi_stage_pipeline(
        input_path="source.bin",
        output_path="final_output.bin",
        bytes_to_remove_list=bytes_to_remove,
        chunk_size=4 * 1024 * 1024
    )

    print("Processing complete.")

