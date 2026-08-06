#!/bin/bash

echo "Setting up environment..."

pip install google-api-python-client google-auth python-dotenv pandas tqdm ffmpeg-python

echo "Writing Python script..."

cat << 'EOF' > youtube_content_check.py
import os
import json
from pathlib import Path
from googleapiclient.discovery import build
import ffmpeg

API_KEY = os.getenv("YOUTUBE_API_KEY")

if not API_KEY:
    print("Set YOUTUBE_API_KEY environment variable.")
    exit()

youtube = build("youtube", "v3", developerKey=API_KEY)

VIDEO_IDS = [
    # put your video IDs here
    "VIDEO_ID_1",
    "VIDEO_ID_2"
]

metadata = []

def check_video(video_id):
    resp = youtube.videos().list(
        part="snippet,status,contentDetails",
        id=video_id
    ).execute()

    if not resp["items"]:
        return None

    item = resp["items"][0]

    data = {
        "video_id": video_id,
        "title": item["snippet"]["title"],
        "channel": item["snippet"]["channelTitle"],
        "published": item["snippet"]["publishedAt"],
        "privacy_status": item["status"]["privacyStatus"],
        "embeddable": item["status"]["embeddable"],
        "url": f"https://youtube.com/watch?v={video_id}"
    }

    return data


print("Checking videos...")

for vid in VIDEO_IDS:
    info = check_video(vid)
    if info:
        metadata.append(info)

print("Writing metadata file...")

with open("video_metadata.json", "w") as f:
    json.dump(metadata, f, indent=2)

print("Metadata saved to video_metadata.json")

convert = input("Convert MP4 files in a directory to MP3? (y/n): ")

if convert.lower() == "y":

    directory = input("Enter directory containing MP4 files: ")
    path = Path(directory)

    if not path.exists():
        print("Directory not found.")
        exit()

    mp4_files = list(path.glob("*.mp4"))

    if not mp4_files:
        print("No MP4 files found.")
        exit()

    for video in mp4_files:
        mp3_path = video.with_suffix(".mp3")

        (
            ffmpeg
            .input(str(video))
            .output(str(mp3_path), audio_bitrate="192k", vn=None)
            .overwrite_output()
            .run(quiet=True)
        )

        print(f"Converted {video.name} -> {mp3_path.name}")

print("Done.")
EOF

echo "Script created: youtube_content_check.py"

echo "Run it with:"
echo "python youtube_content_check.py"
