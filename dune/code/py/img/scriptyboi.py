#!/usr/bin/env python3

import argparse
import sys
import hashlib
from PIL import Image, PngImagePlugin
from PIL.ExifTags import TAGS


# ----------------- Utilities -----------------

def sha256_pixels(img):
    """Hash only pixel data (for forensic integrity checks)."""
    h = hashlib.sha256()
    h.update(bytes(img.tobytes()))
    return h.hexdigest()


def parse_key_values(pairs):
    meta = {}
    for p in pairs:
        if "=" not in p:
            raise ValueError(f"Invalid KEY=VALUE pair: {p}")
        k, v = p.split("=", 1)
        meta[k] = v
    return meta


# ----------------- Core Functions -----------------

def list_metadata(path, verbose=False):
    img = Image.open(path)

    print(f"\n[File]")
    print(f"  Path   : {path}")
    print(f"  Format : {img.format}")
    print(f"  Size   : {img.size}")
    print(f"  Mode   : {img.mode}")

    if verbose:
        print(f"  Pixels SHA256 : {sha256_pixels(img)}")

    exif = img.getexif()
    if exif:
        print("\n[EXIF]")
        for tag_id, val in exif.items():
            tag = TAGS.get(tag_id, tag_id)
            print(f"  {tag}: {val}")
    else:
        print("\n[EXIF]")
        print("  <none>")

    if hasattr(img, "text") and img.text:
        print("\n[PNG Text]")
        for k, v in img.text.items():
            print(f"  {k}: {v}")
    elif img.format == "PNG":
        print("\n[PNG Text]")
        print("  <none>")


def wipe_metadata(path, output=None):
    img = Image.open(path)
    before = sha256_pixels(img)

    clean = Image.new(img.mode, img.size)
    clean.putdata(list(img.getdata()))

    out = output if output else path
    clean.save(out)

    after = sha256_pixels(clean)

    print("[Metadata Wipe]")
    print(f"  Output file        : {out}")
    print(f"  Pixel hash match   : {before == after}")
    print(f"  SHA256 (pixels)    : {after}")


def remove_keys(path, keys, output=None):
    img = Image.open(path)

    if img.format == "PNG":
        pnginfo = PngImagePlugin.PngInfo()
        for k, v in img.text.items():
            if k not in keys:
                pnginfo.add_text(k, v)

        out = output if output else path
        img.save(out, pnginfo=pnginfo)

    elif img.format in ("JPEG", "JPG"):
        exif = img.getexif()
        to_delete = []

        for tag_id, tag_name in TAGS.items():
            if tag_name in keys and tag_id in exif:
                to_delete.append(tag_id)

        for tid in to_delete:
            del exif[tid]

        out = output if output else path
        img.save(out, exif=exif)

    else:
        raise ValueError("Unsupported format")

    print("[Selective Removal]")
    print(f"  Removed keys : {', '.join(keys)}")
    print(f"  Output file  : {out}")


def add_metadata(path, pairs, output=None):
    img = Image.open(path)
    meta = parse_key_values(pairs)

    if img.format == "PNG":
        pnginfo = PngImagePlugin.PngInfo()
        for k, v in img.text.items():
            pnginfo.add_text(k, v)
        for k, v in meta.items():
            pnginfo.add_text(k, v)

        out = output if output else path
        img.save(out, pnginfo=pnginfo)

    elif img.format in ("JPEG", "JPG"):
        exif = img.getexif()
        for k, v in meta.items():
            exif[k] = v  # nonstandard but valid container-wise

        out = output if output else path
        img.save(out, exif=exif)

    else:
        raise ValueError("Unsupported format")

    print("[Metadata Injection]")
    for k, v in meta.items():
        print(f"  {k} = {v}")
    print(f"  Output file : {out}")


# ----------------- CLI -----------------

def main():
    parser = argparse.ArgumentParser(
        prog="scriptyboi",
        formatter_class=argparse.RawTextHelpFormatter,
        description="""
Forensic & anti-forensic image metadata tool.

Primary use cases:
  • Digital forensics (inspect without modifying)
  • Evidence sanitization
  • Metadata attribution / watermarking
  • Pixel-integrity verification

Supported formats:
  PNG, JPG, JPEG
""",
        epilog="""
Examples:
  Inspect metadata (safe):
    python3 scriptyboi.py -l image.png

  Verbose inspection with pixel hash:
    python3 scriptyboi.py -l image.jpg -v

  Full metadata wipe (pixel-preserving):
    python3 scriptyboi.py -w image.png

  Wipe metadata to a new file:
    python3 scriptyboi.py -w image.jpg -o clean.jpg

  Remove specific keys:
    python3 scriptyboi.py -r image.png Author Software

  Add metadata:
    python3 scriptyboi.py -a image.png Author=David CaseID=042

Notes:
  • Pixel hashes allow proof of non-destructive edits
  • PNG metadata is reliable and portable
  • JPEG custom EXIF may not display in all tools
"""
    )

    parser.add_argument("-l", "--list", metavar="IMAGE", help="List all metadata")
    parser.add_argument("-w", "--wipe", metavar="IMAGE", help="Remove ALL metadata")
    parser.add_argument("-r", "--remove", nargs="+", metavar=("IMAGE", "KEY"),
                        help="Remove specific metadata keys")
    parser.add_argument("-a", "--add", nargs="+", metavar=("IMAGE", "KEY=VALUE"),
                        help="Add metadata entries")

    parser.add_argument("-o", "--output", help="Write result to a new file")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Verbose output (includes pixel hash)")

    args = parser.parse_args()

    try:
        if args.list:
            list_metadata(args.list, args.verbose)

        elif args.wipe:
            wipe_metadata(args.wipe, args.output)

        elif args.remove:
            remove_keys(args.remove[0], args.remove[1:], args.output)

        elif args.add:
            add_metadata(args.add[0], args.add[1:], args.output)

        else:
            parser.print_help()

    except Exception as e:
        print(f"[ERROR] {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

