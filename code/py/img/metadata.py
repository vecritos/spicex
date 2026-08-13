#!/usr/bin/env python3

# comment for reasons

import argparse
import sys
from PIL import Image
from PIL.ExifTags import TAGS

def list_metadata(image_path):
    try:
        img = Image.open(image_path)

        print(f"[+] File: {image_path}")
        print(f"[+] Format: {img.format}")
        print(f"[+] Size: {img.size}")
        print(f"[+] Mode: {img.mode}\n")

        # EXIF metadata (JPEG mostly)
        exif = img.getexif()
        if exif:
            print("[+] EXIF Metadata:")
            for tag_id, value in exif.items():
                tag = TAGS.get(tag_id, tag_id)
                print(f"  {tag}: {value}")
        else:
            print("[-] No EXIF metadata found.")

        # PNG text metadata
        if hasattr(img, "text") and img.text:
            print("\n[+] PNG Text Metadata:")
            for k, v in img.text.items():
                print(f"  {k}: {v}")

    except Exception as e:
        print(f"[!] Error reading metadata: {e}")
        sys.exit(1)


def delete_metadata(image_path):
    try:
        img = Image.open(image_path)

        # Create a clean image without metadata
        data = list(img.getdata())
        clean = Image.new(img.mode, img.size)
        clean.putdata(data)

        # Preserve format
        clean.save(image_path)

        print(f"[+] Metadata removed from {image_path}")

    except Exception as e:
        print(f"[!] Error deleting metadata: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="scriptyboi — image metadata inspector & nuker"
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-l", "--list", metavar="IMAGE", help="List metadata")
    group.add_argument("-d", "--delete", metavar="IMAGE", help="Delete metadata")

    args = parser.parse_args()

    if args.list:
        list_metadata(args.list)
    elif args.delete:
        delete_metadata(args.delete)


if __name__ == "__main__":
    main()


