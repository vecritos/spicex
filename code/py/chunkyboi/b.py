import os
import tempfile
import hashlib
import sys
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed

# ----------------------------
# Logging setup
# ----------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("chunkyboi")

# ----------------------------
# Global thread pool
# ----------------------------
GLOBAL_THREAD_POOL = None

def init_global_thread_pool(max_workers: int):
    global GLOBAL_THREAD_POOL
    if GLOBAL_THREAD_POOL is not None:
        GLOBAL_THREAD_POOL.shutdown(wait=True)
    GLOBAL_THREAD_POOL = ThreadPoolExecutor(max_workers=max_workers)
    logger.info("Initialized global thread pool with %d workers", max_workers)

def cleanup_global_thread_pool():
    global GLOBAL_THREAD_POOL
    if GLOBAL_THREAD_POOL:
        logger.info("Shutting down global thread pool")
        GLOBAL_THREAD_POOL.shutdown(wait=True)
        GLOBAL_THREAD_POOL = None

# ----------------------------
# Helpers
# ----------------------------
def sha256_digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def process_chunk_to_temp(index, data, temp_dir, transform_fn):
    transformed = transform_fn(data)
    hash_digest = sha256_digest(transformed)
    temp_path = os.path.join(temp_dir, f"chunk_{index:08d}.tmp")

    with open(temp_path, "wb") as f:
        f.write(transformed)

    return index, temp_path, len(transformed), hash_digest

# ----------------------------
# Parallel transform stage
# ----------------------------
def parallel_transform_to_temp_files(src_path, temp_dir, chunk_size, transform_fn):
    if GLOBAL_THREAD_POOL is None:
        raise RuntimeError("Global thread pool not initialized")

    results = []
    futures = []

    logger.info("Starting parallel transform: %s", src_path)

    try:
        with open(src_path, "rb") as src:
            index = 0
            while True:
                chunk = src.read(chunk_size)
                if not chunk:
                    break
                futures.append(
                    GLOBAL_THREAD_POOL.submit(
                        process_chunk_to_temp,
                        index,
                        chunk,
                        temp_dir,
                        transform_fn,
                    )
                )
                index += 1

        for future in as_completed(futures):
            try:
                results.append(future.result())
            except Exception as e:
                logger.error("Chunk processing failed: %s", e, exc_info=True)
                for f in futures:
                    f.cancel()
                raise

    except Exception:
        logger.error("Aborting parallel transform")
        raise

    logger.info("Completed parallel transform (%d chunks)", len(results))
    return results

# ----------------------------
# Merge + validation
# ----------------------------
def sequential_merge_temp_files(output_path, temp_files):
    temp_files.sort(key=lambda x: x[0])
    metadata = []
    current_offset = 0

    logger.info("Merging chunks into %s", output_path)

    with open(output_path, "wb") as out_f:
        for index, temp_path, length, expected_hash in temp_files:
            with open(temp_path, "rb") as f:
                while True:
                    buf = f.read(1024 * 1024)
                    if not buf:
                        break
                    out_f.write(buf)

            metadata.append((index, current_offset, length, expected_hash))
            current_offset += length

    return metadata

def validate_output_file(output_path, metadata):
    logger.info("Validating output file")

    with open(output_path, "rb") as out_f:
        for index, offset, length, expected_hash in metadata:
            out_f.seek(offset)
            data = out_f.read(length)
            actual_hash = hashlib.sha256(data).hexdigest()
            if actual_hash != expected_hash:
                raise RuntimeError(
                    f"Chunk {index} hash mismatch: expected {expected_hash}, got {actual_hash}"
                )

    logger.info("Validation successful")

# ----------------------------
# Pipeline
# ----------------------------
def run_pipeline(src_path, output_path, transform_fn, chunk_size):
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_files = parallel_transform_to_temp_files(
            src_path, temp_dir, chunk_size, transform_fn
        )
        metadata = sequential_merge_temp_files(output_path, temp_files)
        validate_output_file(output_path, metadata)

# ----------------------------
# Transform factory
# ----------------------------
def make_remove_transform(byte_value: bytes):
    if len(byte_value) != 1:
        raise ValueError("byte_value must be exactly one byte")

    def transform(data: bytes) -> bytes:
        return data.replace(byte_value, b"")

    return transform

# ----------------------------
# Iterative multi-stage pipeline
# ----------------------------
def iterative_multi_stage_pipeline(
    input_path,
    output_path,
    bytes_to_remove_list,
    chunk_size,
):
    current_input = input_path

    for stage_index, byte_val in enumerate(bytes_to_remove_list, start=1):
        logger.info(
            "Stage %d/%d: removing byte %r",
            stage_index,
            len(bytes_to_remove_list),
            byte_val,
        )

        transform_fn = make_remove_transform(byte_val)

        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            next_output = tmp.name

        try:
            run_pipeline(
                src_path=current_input,
                output_path=next_output,
                transform_fn=transform_fn,
                chunk_size=chunk_size,
            )
        except Exception:
            logger.error("Stage %d failed, aborting pipeline", stage_index)
            try:
                os.remove(next_output)
            except OSError:
                pass
            raise

        if current_input != input_path:
            try:
                os.remove(current_input)
            except OSError:
                pass

        current_input = next_output

    if current_input != output_path:
        os.replace(current_input, output_path)

    logger.info("Final output written to %s", output_path)

# ----------------------------
# Main
# ----------------------------
if __name__ == "__main__":
    import atexit

    try:
        init_global_thread_pool(max_workers=4)
        atexit.register(cleanup_global_thread_pool)

        bytes_to_remove = [b"a", b"b", b"c"]

        iterative_multi_stage_pipeline(
            input_path="source.bin",
            output_path="final_output.bin",
            bytes_to_remove_list=bytes_to_remove,
            chunk_size=4 * 1024 * 1024,
        )

        logger.info("Processing complete")

    except Exception as e:
        logger.critical("Fatal error: %s", e, exc_info=True)
        sys.exit(1)

