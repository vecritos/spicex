import argparse
import os
from pathlib import Path
from PIL import Image


# supported image formats
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"}


def get_creation_time(path: Path):
    """
    Returns creation time if available, otherwise fallback to modified time.
    Works across platforms.
    """
    stat = path.stat()
    # On Windows: st_ctime is creation time
    # On Unix: creation time may not exist, then st_ctime is metadata change
    return stat.st_ctime


def convert_images_to_pdf(input_dir, output_pdf):
    input_path = Path(input_dir)

    if not input_path.exists() or not input_path.is_dir():
        raise NotADirectoryError(f"Input directory does not exist: {input_dir}")

    # filter images only
    files = [
        f for f in input_path.iterdir()
        if f.is_file() and f.suffix.lower() in IMAGE_EXTS
    ]

    if not files:
        raise ValueError("No supported image files found in input directory.")

    # sort by creation timestamp
    files.sort(key=get_creation_time)

    images = []

    for f in files:
        try:
            img = Image.open(f)
            # must convert to RGB for PDF
            if img.mode != "RGB":
                img = img.convert("RGB")
            images.append(img)
            print(f"Added: {f.name}")
        except Exception as e:
            print(f"Skipping {f.name} due to error: {e}")

    if not images:
        raise ValueError("No valid images could be opened for PDF creation.")

    # first image + rest appended
    first_image = images[0]
    rest = images[1:]

    first_image.save(
        output_pdf,
        save_all=True,
        append_images=rest
    )

    print(f"\nPDF created: {output_pdf}")


def main():
    parser = argparse.ArgumentParser(
        description="Sort image files by creation time and combine them into a single PDF."
    )

    parser.add_argument("input_dir", help="Directory containing image files")
    parser.add_argument("output_pdf", help="Output PDF file path")

    args = parser.parse_args()

    convert_images_to_pdf(args.input_dir, args.output_pdf)


if __name__ == "__main__":
    main()

