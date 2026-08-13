# tests/test_chunkyboi_basic.py

import tempfile
from pathlib import Path

from chunkyboi import process_file


def replace_a_with_x(chunk: bytes, *, password=None, **kwargs) -> bytes:
    return chunk.replace(b"a", b"X")


def test_chunk_and_transform_basic():
    # Build input: ababababababab (26 bytes)
    input_bytes = b"".join(b"a" + b"b" for _ in range(13))
    expected_output = b"".join(b"X" + b"b" for _ in range(13))

    with tempfile.TemporaryDirectory() as tmpdir:
        input_path = Path(tmpdir) / "input.bin"
        output_path = Path(tmpdir) / "output.bin"

        input_path.write_bytes(input_bytes)

        process_file(
            input_path=input_path,
            output_path=output_path,
            transform=replace_a_with_x,
            config={"password": None},
        )

        result = output_path.read_bytes()

    assert result == expected_output

