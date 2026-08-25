import os
import argparse
from PIL import Image
from pillow_heif import register_heif_opener

# Enable HEIF/HEIC support in Pillow
register_heif_opener()


def convert_heic_to_jpg(heic_path, output_dir=None, quality=95):
    """
    Convert a single HEIC/HEIF image to JPG.

    Args:
        heic_path: Path to the input HEIC/HEIF file.
        output_dir: Optional directory for the converted JPG.
                    Defaults to the input file's directory.
        quality: JPEG quality from 1-100.

    Returns:
        Path to the converted JPG, or None if conversion failed.
    """
    if not os.path.isfile(heic_path):
        print(f"Error: File not found at '{heic_path}'")
        return None

    if not heic_path.lower().endswith((".heic", ".heif")):
        print(f"Error: '{heic_path}' is not a HEIC/HEIF file.")
        return None

    file_dir, file_name = os.path.split(heic_path)
    base_name, _ = os.path.splitext(file_name)
    jpg_name = f"{base_name}.jpg"

    save_dir = output_dir if output_dir else file_dir

    if save_dir:
        os.makedirs(save_dir, exist_ok=True)

    jpg_path = os.path.join(save_dir, jpg_name)

    try:
        with Image.open(heic_path) as image:
            image.convert("RGB").save(jpg_path, "JPEG", quality=quality)

        print(f"Converted: {heic_path} -> {jpg_path}")
        return jpg_path

    except Exception as e:
        print(f"Error converting '{heic_path}': {e}")
        return None


def convert_directory(directory_path, output_dir=None, quality=95):
    """
    Convert all HEIC/HEIF files in a directory to JPG.

    Args:
        directory_path: Directory containing HEIC/HEIF files.
        output_dir: Optional output directory. Defaults to the input directory.
        quality: JPEG quality from 1-100.
    """
    if not os.path.isdir(directory_path):
        print(f"Error: The directory '{directory_path}' does not exist.")
        return

    converted = 0
    failed = 0

    for filename in sorted(os.listdir(directory_path)):
        if not filename.lower().endswith((".heic", ".heif")):
            continue

        heic_path = os.path.join(directory_path, filename)

        if convert_heic_to_jpg(heic_path, output_dir, quality):
            converted += 1
        else:
            failed += 1

    print(f"Batch conversion completed: {converted} converted, {failed} failed.")


def main():
    parser = argparse.ArgumentParser(
        description="Convert HEIC/HEIF images to JPG."
    )

    input_group = parser.add_mutually_exclusive_group(required=True)

    input_group.add_argument(
        "--file",
        metavar="FILENAME",
        help="Convert a single HEIC/HEIF file."
    )

    input_group.add_argument(
        "--directory",
        metavar="DIRECTORY",
        help="Convert all HEIC/HEIF files in a directory."
    )

    parser.add_argument(
        "--output",
        metavar="DIRECTORY",
        help="Optional output directory. Defaults to the input file/directory."
    )

    parser.add_argument(
        "--quality",
        type=int,
        default=95,
        choices=range(1, 101),
        metavar="1-100",
        help="JPEG quality from 1 to 100. Default: 95."
    )

    args = parser.parse_args()

    if args.file:
        convert_heic_to_jpg(
            args.file,
            output_dir=args.output,
            quality=args.quality
        )

    elif args.directory:
        convert_directory(
            args.directory,
            output_dir=args.output,
            quality=args.quality
        )


if __name__ == "__main__":
    main()
