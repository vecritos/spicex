import os
import random
from concurrent.futures import ThreadPoolExecutor

# ============================================================
# NAIVE ARCHITECTURE ASSUMPTIONS (CHANGE HERE IF YOU CARE LATER)
# ============================================================

ENDIANNESS = "little"   # naive assumption: modern machines
WORD_SIZE = 4           # bytes (32-bit words)

# ============================================================

def invert_word_naive(word: int) -> int:
    """Invert bits of a machine-native word."""
    return word ^ ((1 << (WORD_SIZE * 8)) - 1)

def randomize_word_naive(word: int, rng: random.Random) -> int:
    """XOR word with random bits (NOT crypto)."""
    return word ^ rng.getrandbits(WORD_SIZE * 8)

def transform_bytes_naive(data: bytes, transform_fn, rng=None) -> bytes:
    out = bytearray(len(data))

    full_words = len(data) // WORD_SIZE
    remainder = len(data) % WORD_SIZE

    for i in range(full_words):
        start = i * WORD_SIZE
        chunk = data[start:start + WORD_SIZE]

        # 🔴 NAIVE ENDIAN INTERPRETATION (centralized)
        word = int.from_bytes(chunk, ENDIANNESS)

        if rng:
            word = transform_fn(word, rng)
        else:
            word = transform_fn(word)

        out[start:start + WORD_SIZE] = word.to_bytes(WORD_SIZE, ENDIANNESS)

    # Naively copy tail bytes untouched
    if remainder:
        out[-remainder:] = data[-remainder:]

    return bytes(out)

def copy_chunk(src, dst, offset, size, transform_fn, seed=None):
    rng = random.Random(seed + offset if seed is not None else None)

    with open(src, "rb") as fsrc, open(dst, "r+b") as fdst:
        fsrc.seek(offset)
        fdst.seek(offset)

        data = fsrc.read(size)
        data = transform_bytes_naive(data, transform_fn, rng)
        fdst.write(data)

def parallel_copy(
    src_path,
    dst_path,
    num_chunks=8,
    transform_fn=invert_word_naive,
    seed=None
):
    file_size = os.path.getsize(src_path)
    chunk_size = file_size // num_chunks

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
                    transform_fn,
                    seed
                )
            )

        for f in futures:
            f.result()

    print("Copy complete (naive endian assumptions)")


