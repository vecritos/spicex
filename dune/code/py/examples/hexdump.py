def hexdump_stream(path, width=16, chunk_size=1024 * 1024):
    offset = 0
    with open(path, "rb") as f:
        while chunk := f.read(chunk_size):
            for i in range(0, len(chunk), width):
                line = chunk[i:i+width]
                hex_bytes = " ".join(f"{b:02x}" for b in line)
                print(f"{offset:08x}  {hex_bytes}")
                offset += len(line)

hexdump_stream("bigfile.bin")
