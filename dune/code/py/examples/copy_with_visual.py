import sys
import time
import string

def printable(b):
    return chr(b) if 32 <= b < 127 else "."

def copy_with_visual(src, dst):
    with open(src, "rb") as fin, open(dst, "wb") as fout:
        while True:
            chunk = fin.read(16)
            if not chunk:
                break

            # Visual output
            hex_part = " ".join(f"{b:02x}" for b in chunk)
            ascii_part = "".join(printable(b) for b in chunk)
            print(f"{hex_part:<48} | {ascii_part}", flush=True)

            # Actual copy
            fout.write(chunk)
            fout.flush()

            # Optional slowdown for effect
            time.sleep(0.02)

if __name__ == "__main__":
    copy_with_visual(sys.argv[1], sys.argv[2])
