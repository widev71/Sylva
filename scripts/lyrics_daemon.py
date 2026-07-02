#!/usr/bin/env python3
import subprocess
import urllib.request
import urllib.parse
import json
import time
import sys
import re
import os

CACHE_FILE = os.path.expanduser("~/.cache/lyrics_cache.json")
os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)

def load_cache():
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except:
        return {}

def save_cache(cache):
    try:
        with open(CACHE_FILE, 'w') as f:
            json.dump(cache, f)
    except:
        pass

def get_player_meta():
    try:
        output = subprocess.check_output(["playerctl", "metadata", "--format", "{{title}}|{{artist}}|{{mpris:artUrl}}"], stderr=subprocess.DEVNULL)
        return output.decode('utf-8').strip()
    except:
        return ""

def get_player_position():
    try:
        output = subprocess.check_output(["playerctl", "position"], stderr=subprocess.DEVNULL)
        return float(output.decode('utf-8').strip())
    except:
        return 0.0

def download_album_art(url):
    if not url: return
    try:
        if url.startswith("file://"):
            subprocess.run(["cp", url.replace("file://", ""), "/tmp/album_art.jpg"], stderr=subprocess.DEVNULL)
        else:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            res = urllib.request.urlopen(req, timeout=5)
            with open("/tmp/album_art.jpg", "wb") as f:
                f.write(res.read())
    except:
        pass

def fetch_lyrics(title, artist):
    if not title or not artist:
        return []
    try:
        # Clean up title for better LRCLIB matching
        clean_title = re.sub(r'\(.*?\)', '', title)
        clean_title = re.sub(r'\[.*?\]', '', clean_title)
        clean_title = re.split(r'\s-\s', clean_title)[0].strip()

        # Use curl as backend — faster and avoids Python SSL timeout issues
        url = 'https://lrclib.net/api/get?track_name=' + urllib.parse.quote(clean_title) + '&artist_name=' + urllib.parse.quote(artist.strip())
        result = subprocess.run(
            ['curl', '-s', '--connect-timeout', '10', '--max-time', '20', '-H', 'User-Agent: Mozilla/5.0', url],
            capture_output=True, text=True, timeout=25
        )
        if result.returncode != 0 or not result.stdout.strip():
            return []

        data = json.loads(result.stdout)
        synced = data.get('syncedLyrics')

        if not synced:
            # Fallback: search API
            search_url = 'https://lrclib.net/api/search?q=' + urllib.parse.quote(clean_title + ' ' + artist.strip())
            result = subprocess.run(
                ['curl', '-s', '--connect-timeout', '10', '--max-time', '20', '-H', 'User-Agent: Mozilla/5.0', search_url],
                capture_output=True, text=True, timeout=25
            )
            if result.returncode != 0 or not result.stdout.strip():
                return []
            data = json.loads(result.stdout)
            if isinstance(data, list):
                for track in data:
                    if track.get('syncedLyrics'):
                        synced = track.get('syncedLyrics')
                        break

        if not synced:
            return []

        parsed = []
        for line in synced.split('\n'):
            match = re.match(r'\[(\d+):(\d+\.\d+)\](.*)', line)
            if match:
                m = int(match.group(1))
                s = float(match.group(2))
                text = match.group(3).strip()
                time_sec = m * 60 + s
                parsed.append((time_sec, text))
        return parsed
    except Exception as e:
        with open("/tmp/lyrics_fetch_error.log", "w") as f:
            f.write(str(e) + "\n")
        return []


import threading

# Shared state (daemon thread writes, main loop reads)
_lyrics_lock = threading.Lock()
_lyrics = []
_fetching = False

def _fetch_and_save(title, artist, art_url):
    """Run in a thread: check cache first, then fetch lyrics. Never blocks the main loop."""
    global _lyrics, _fetching
    try:
        if art_url:
            threading.Thread(target=download_album_art, args=(art_url,), daemon=True).start()

        cache_key = f"{title.lower().strip()}|{artist.lower().strip()}"
        cache = load_cache()

        # Cache hit → instant load, no network needed!
        if cache_key in cache:
            result = [(item['time'], item['text']) for item in cache[cache_key]]
        else:
            result = fetch_lyrics(title, artist)
            # Save to cache for next time
            if result:
                cache[cache_key] = [{'time': t, 'text': txt} for t, txt in result]
                # Keep cache max 200 songs
                if len(cache) > 200:
                    oldest_key = next(iter(cache))
                    del cache[oldest_key]
                save_cache(cache)

        with _lyrics_lock:
            _lyrics = result

        # Write lyrics to file (replaces the 'old lyrics' placeholder)
        with open("/tmp/lyrics_data.json", "w") as f:
            json.dump([{"time": t, "text": txt} for t, txt in result], f)

        if not result:
            with open("/tmp/lyrics_debug.log", "w") as f:
                f.write(f"No synced lyrics for: {title} | {artist}\n")
            with open("/tmp/current_lyric_index.txt", "w") as f:
                f.write("-1\n")
    except Exception as e:
        with open("/tmp/lyrics_fetch_error.log", "w") as f:
            f.write(str(e) + "\n")
    finally:
        _fetching = False


def main():
    global _lyrics, _fetching

    current_meta = ""
    last_printed_index = -2

    while True:
        meta = get_player_meta()

        if meta != current_meta:
            current_meta = meta
            last_printed_index = -2  # Force re-write on next index detection

            # ⚠️ KEY FIX: Don't clear lyrics_data.json immediately!
            # Keep old lyrics visible while new ones are loading.
            # Only reset the index so the position starts fresh.
            with open("/tmp/current_lyric_index.txt", "w") as f:
                f.write("-1\n")

            title, artist, art_url = "", "", ""
            if "|" in meta:
                parts = meta.split("|")
                if len(parts) >= 2:
                    title = parts[0]
                    artist = parts[1]
                    art_url = parts[2] if len(parts) >= 3 else ""

            if title and artist and not _fetching:
                _fetching = True
                threading.Thread(
                    target=_fetch_and_save,
                    args=(title, artist, art_url),
                    daemon=True
                ).start()
            elif not title:
                # No song playing — clear everything
                with _lyrics_lock:
                    _lyrics = []
                with open("/tmp/lyrics_data.json", "w") as f:
                    f.write("[]")

        # Update index using current lyrics snapshot (non-blocking)
        with _lyrics_lock:
            current_lyrics = list(_lyrics)

        if current_lyrics:
            pos = get_player_position()
            current_index = -1
            for i, (time_sec, text) in enumerate(reversed(current_lyrics)):
                if pos >= time_sec:
                    current_index = len(current_lyrics) - 1 - i
                    break

            if current_index != last_printed_index:
                with open("/tmp/current_lyric_index.txt", "w") as f:
                    f.write(str(current_index) + "\n")
                last_printed_index = current_index

        time.sleep(0.25)


if __name__ == '__main__':
    main()
