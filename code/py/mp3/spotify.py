import argparse
import re
import shutil
import subprocess
from pathlib import Path


DOWNLOAD_ROOT = Path("downloads")


def sanitize_filename(name: str) -> str:
    """
    Make a playlist title safe for use as a directory name.
    """
    name = re.sub(r'[<>:"/\\|?*]', "_", name)
    name = re.sub(r"[\x00-\x1f]", "_", name)
    name = name.rstrip(". ")

    if not name:
        name = "Unknown Playlist"

    return name


def get_playlist_title(playlist_url: str) -> str:
    """
    Ask spotdl for the playlist metadata and extract its title.

    spotdl is used here rather than making a separate Spotify API
    request, so the downloader remains dependent only on spotdl.
    """
    try:
        result = subprocess.run(
            ["spotdl", "save", playlist_url],
            check=True,
            text=True,
            capture_output=True
        )

        # spotdl's output may vary between versions, so try to
        # identify the playlist name from common output formats.
        output = result.stdout + result.stderr

        for line in output.splitlines():
            line = line.strip()

            if "Playlist:" in line:
                title = line.split("Playlist:", 1)[1].strip()

                if title:
                    return sanitize_filename(title)

    except subprocess.CalledProcessError:
        pass

    # Fallback if metadata extraction fails.
    return "Unknown Playlist"


def download_spotify_playlist(playlist_url: str):
    """
    Downloads a complete Spotify playlist as MP3 files with metadata.

    Each playlist is placed in a directory named after the playlist.
    """

    if not shutil.which("spotdl"):
        raise EnvironmentError(
            "spotdl CLI tool not found. "
            "Please run 'pip install spotdl' first."
        )

    print(f"\nInitializing download for: {playlist_url}")

    playlist_title = get_playlist_title(playlist_url)

    output_directory = DOWNLOAD_ROOT / playlist_title
    output_directory.mkdir(
        parents=True,
        exist_ok=True
    )

    print(f"Playlist: {playlist_title}")
    print(f"Output:   {output_directory}")

    try:
        subprocess.run(
            [
                "spotdl",
                "download",
                playlist_url,
                "--output",
                str(output_directory),
            ],
            check=True,
            text=True,
            capture_output=False
        )

        print(
            f"\n✨ Playlist download successfully completed: "
            f"{playlist_title}"
        )

        return True

    except subprocess.CalledProcessError as e:
        print(
            f"\n❌ An error occurred downloading "
            f"'{playlist_title}': {e}"
        )

        return False


def read_playlist_file(filename: str):
    """
    Read line-delimited playlist URLs.

    Blank lines are ignored.
    Lines beginning with '#' are treated as comments.
    """
    path = Path(filename)

    if not path.is_file():
        raise FileNotFoundError(
            f"Playlist file not found: {filename}"
        )

    urls = []

    with path.open("r", encoding="utf-8") as f:
        for line_number, line in enumerate(f, start=1):
            url = line.strip()

            if not url:
                continue

            if url.startswith("#"):
                continue

            if not url.startswith(
                "https://open.spotify.com/playlist/"
            ):
                print(
                    f"⚠️ Skipping invalid URL on line "
                    f"{line_number}: {url}"
                )
                continue

            urls.append(url)

    return urls


def main():
    parser = argparse.ArgumentParser(
        description="Download Spotify playlists using spotdl."
    )

    mode = parser.add_mutually_exclusive_group(
        required=True
    )

    mode.add_argument(
        "--url",
        action="store_true",
        help="Prompt for a single Spotify playlist URL."
    )

    mode.add_argument(
        "--file",
        metavar="FILENAME",
        help="Download all playlist URLs contained in a file."
    )

    args = parser.parse_args()

    # --------------------------------------------------------
    # Single URL mode
    # --------------------------------------------------------

    if args.url:
        playlist_url = input(
            "Enter target playlist URL: "
        ).strip()

        if not playlist_url:
            print("❌ No URL provided.")
            return

        download_spotify_playlist(playlist_url)
        return

    # --------------------------------------------------------
    # File mode
    # --------------------------------------------------------

    if args.file:
        urls = read_playlist_file(args.file)

        if not urls:
            print("❌ No valid playlist URLs found.")
            return

        print(
            f"\nFound {len(urls)} playlist URL(s)."
        )

        successful = 0
        failed = 0

        for number, playlist_url in enumerate(
            urls,
            start=1
        ):
            print("\n" + "=" * 70)
            print(
                f"Playlist {number}/{len(urls)}"
            )
            print("=" * 70)

            try:
                success = download_spotify_playlist(
                    playlist_url
                )

                if success:
                    successful += 1
                else:
                    failed += 1

            except Exception as e:
                print(
                    f"❌ Failed to process "
                    f"{playlist_url}: {e}"
                )
                failed += 1

        print("\n" + "=" * 70)
        print("DOWNLOAD SUMMARY")
        print("=" * 70)
        print(f"Total:     {len(urls)}")
        print(f"Successful: {successful}")
        print(f"Failed:     {failed}")
        print(f"Output:     {DOWNLOAD_ROOT.resolve()}")


if __name__ == "__main__":
    main()