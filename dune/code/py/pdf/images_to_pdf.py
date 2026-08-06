import os
import argparse
from PIL import Image, ExifTags
from datetime import datetime

SUPPORTED_EXTENSIONS = (".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp")

def get_image_date(path):
    """
    Priority:
    1. EXIF DateTimeOriginal
    2. File modified time
    """
    try:
        img = Image.open(path)
        exif = img._getexif()

        if exif:
            for tag, value in exif.items():
                if ExifTags.TAGS.get(tag) == "DateTimeOriginal":
                    return datetime.strptime(value, "%Y:%m:%d %H:%M:%S").timestamp()
    except Exception:
        pass

    return os.path.getmtime(path)

def main(input_dir, output_pdf):
    images = []

    for file in os.listdir(input_dir):
        if file.lower().endswith(SUPPORTED_EXTENSIONS):
            full_path = os.path.join(input_dir, file)
            images.append((full_path, get_image_date(full_path)))

    if not images:
        raise RuntimeError("No image files found.")

    images.sort(key=lambda x: x[1])

    pil_images = []
    for path, _ in images:
        img = Image.open(path).convert("RGB")
        pil_images.append(img)

    pil_images[0].save(
        output_pdf,
        save_all=True,
        append_images=pil_images[1:]
    )

    print(f"PDF created: {output_pdf}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert images to a single PDF ordered by date")
    parser.add_argument("input_dir", help="Directory containing images")
    parser.add_argument("output_pdf", help="Output PDF file")

    args = parser.parse_args()
    main(args.input_dir, args.output_pdf)

