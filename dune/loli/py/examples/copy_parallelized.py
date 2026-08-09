import os
from concurrent.futures import ThreadPoolExecutor

def copy_chunk(src, dst, offset, size):
    with open(src, "rb") as fsrc, open(dst, "r+b") as fdst:
        fsrc.seek(offset)
        fdst.seek(offset)
        fdst.write(fsrc.read(size))

def parallel_copy(src_path, dst_path, num_chunks=8):
    file_size = os.path.getsize(src_path)
    chunk_size = file_size // num_chunks

    # Create destination file with correct size
    with open(dst_path, "wb") as f:
        f.truncate(file_size)

    tasks = []
    with ThreadPoolExecutor(max_workers=num_chunks) as executor:
        for i in range(num_chunks):
            offset = i * chunk_size
            size = chunk_size if i < num_chunks - 1 else file_size - offset
            tasks.append(
                executor.submit(copy_chunk, src_path, dst_path, offset, size)
            )

        for t in tasks:
            t.result()  # propagate errors

    print("Copy complete")

if __name__ == "__main__":
    parallel_copy(
        src_path="source.bin",
        dst_path="destination.bin",
        num_chunks=8
    )
