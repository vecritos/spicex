import os
import random
from concurrent.futures import ThreadPoolExecutor

def invert_bits(data: bytes) -> bytes:
    # Bitwise NOT on every byte
    return bytes(b ^ 0xFF for b in data)

def randomize_bits(data: bytes, seed=None) -> bytes:
    rng = random.Random(seed)
    return bytes(b ^ rng.getrandbits(8) for b in data)

def copy_chunk(src, dst, offset, size, modifier):
    with open(src, "rb") as fsrc, open(dst, "r+b") as fdst:
        fsrc.seek(offset)
        fdst.seek(offset)

        data = fsrc.read(size)
        if modifier:
            data = modifier(data)

        fdst.write(data)

def parallel_copy(
    src_path,
    dst_path,
    num_chunks=8,
    modifier=None
):
    file_size = os.path.getsize(src_path)
    chunk_size = file_size // num_chunks

    # Preallocate destination file
    with open(dst_path, "wb") as f:
        f.truncate(file_size)

    with ThreadPoolExecutor(max_workers=num_chunks) as executor:
        futures = []
        for i in range(num_chunks):
            offset = i * chunk_size
            size = chunk_size if i < num_chunks - 1 else file_size - offset

            futures.append(
                executor.submit(
                    copy_chunk,
                    src_path,
                    dst_path,
                    offset,
                    size,
                    modifier
                )
            )

        for f in futures:
            f.result()

    print("Copy complete")

if __name__ == "__main__":
    # Example 1: invert every bit
    parallel_copy(
        "source.bin",
        "inverted.bin",
        num_chunks=8,
        modifier=invert_bits
    )

    # Example 2: random bit flipping (deterministic per run)
    parallel_copy(
        "source.bin",
        "randomized.bin",
        num_chunks=8,
        modifier=lambda d: randomize_bits(d, seed=1234)
    )
