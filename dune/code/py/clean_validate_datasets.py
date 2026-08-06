import os
import csv
import hashlib
import numpy as np
import soundfile as sf
import librosa

DATASET_DIR = "dataset"
INPUT_WAV_DIR = os.path.join(DATASET_DIR, "wavs")
OUTPUT_DIR = "dataset_clean"
OUTPUT_WAV_DIR = os.path.join(OUTPUT_DIR, "wavs")

META_IN = os.path.join(DATASET_DIR, "metadata.csv")
META_OUT = os.path.join(OUTPUT_DIR, "metadata.csv")

TARGET_SR = 22050
MIN_DURATION = 2.5
MAX_DURATION = 9.0

TARGET_LUFS_DB = -23
CLIP_THRESHOLD = 0.99

os.makedirs(OUTPUT_WAV_DIR, exist_ok=True)


def normalize_loudness(audio):
    rms = np.sqrt(np.mean(audio**2))
    if rms == 0:
        return audio
    db = 20 * np.log10(rms)
    gain = TARGET_LUFS_DB - db
    factor = 10 ** (gain / 20)
    return audio * factor


def trim_silence(audio):
    trimmed, _ = librosa.effects.trim(audio, top_db=40)
    return trimmed


def audio_hash(audio):
    return hashlib.md5(audio.tobytes()).hexdigest()


def process_file(in_path):
    audio, sr = sf.read(in_path)

    if len(audio.shape) > 1:
        audio = np.mean(audio, axis=1)

    if sr != TARGET_SR:
        audio = librosa.resample(audio, orig_sr=sr, target_sr=TARGET_SR)
        sr = TARGET_SR

    audio = trim_silence(audio)
    audio = normalize_loudness(audio)

    peak = np.max(np.abs(audio))
    if peak > CLIP_THRESHOLD:
        audio = audio / peak * 0.98

    duration = len(audio) / sr
    return audio, sr, duration


def main():
    seen = set()
    total_duration = 0
    kept = 0
    dropped = 0

    with open(META_IN, "r", encoding="utf-8") as f:
        rows = list(csv.reader(f, delimiter="|"))

    with open(META_OUT, "w", encoding="utf-8", newline="") as out_f:
        writer = csv.writer(out_f, delimiter="|")

        for row in rows:
            if len(row) != 2:
                dropped += 1
                continue

            wav_name, text = row
            in_path = os.path.join(INPUT_WAV_DIR, wav_name)

            if not os.path.exists(in_path):
                dropped += 1
                continue

            try:
                audio, sr, duration = process_file(in_path)
            except:
                dropped += 1
                continue

            if duration < MIN_DURATION or duration > MAX_DURATION:
                dropped += 1
                continue

            h = audio_hash(audio)
            if h in seen:
                dropped += 1
                continue

            seen.add(h)

            out_path = os.path.join(OUTPUT_WAV_DIR, wav_name)
            sf.write(out_path, audio, sr)

            writer.writerow([wav_name, text.strip()])

            total_duration += duration
            kept += 1

    print("\nDATASET SUMMARY")
    print("Clips kept:", kept)
    print("Clips dropped:", dropped)
    print("Total hours:", round(total_duration / 3600, 2))


if __name__ == "__main__":
    main()
