# tests/test_chunkyboi_iterative.py

import tempfile
from pathlib import Path

from chunkyboi import process_file


def invert_bits(chunk: bytes, *, password=None, **kwargs) -> bytes:
    return bytes((~b & 0xFF) for b in chunk)


def test_iterative_transform_stability():
    # Same ababab pattern
    input_bytes = b"".join(b"a" + b"b" for _ in range(13))

    with tempfile.TemporaryDirectory() as tmpdir:
        input_path = Path(tmpdir) / "input.bin"
        mid_path = Path(tmpdir) / "mid.bin"
        output_path = Path(tmpdir) / "output.bin"

        input_path.write_bytes(input_bytes)

        # First pass
        process_file(
            input_path=input_path,
            output_path=mid_path,
            transform=invert_bits,
            config={"password": "irrelevant"},
        )

        # Second pass (invert twice → original)
        process_file(
            input_path=mid_path,
            output_path=output_path,
            transform=invert_bits,
            config={"password": "irrelevant"},
        )

        result = output_path.read_bytes()

    assert result == input_bytes

