import argparse
import os
from pathlib import Path

GB = 1024 ** 3  # gibibytes (GiB)


def get_file_size_gb(path: Path) -> float:
    """Return file size in gigabytes using os.stat."""
    return os.stat(path).st_size / GB


def get_directory_size_gb(path: Path) -> float:
    """Recursively calculate directory size in gigabytes."""
    total_bytes = 0

    for root, _, files in os.walk(path):
        for name in files:
            try:
                file_path = Path(root) / name
                total_bytes += os.stat(file_path).st_size
            except FileNotFoundError:
                # File may disappear during traversal
                pass

    return total_bytes / GB


def main():
    parser = argparse.ArgumentParser(description="Calculate file or directory size in GB")
    parser.add_argument("path", help="File or directory path")

    args = parser.parse_args()
    path = Path(args.path)

    if not path.exists():
        raise SystemExit("Path does not exist")

    if path.is_file():
        size_gb = get_file_size_gb(path)
        print(f"{path} : {size_gb:.3f} GB")

    elif path.is_dir():
        size_gb = get_directory_size_gb(path)
        print(f"{path} : {size_gb:.3f} GB")


if __name__ == "__main__":
    main()

