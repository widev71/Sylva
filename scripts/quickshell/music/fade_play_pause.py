#!/usr/bin/env python3
import subprocess
import time
import sys
import fcntl

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except Exception:
        return ""

def get_volume(player_arg):
    out = run_cmd(f"playerctl {player_arg} volume")
    try:
        return float(out)
    except:
        return 1.0

def set_volume(vol, player_arg):
    run_cmd(f"playerctl {player_arg} volume {vol}")

def fade_play_pause(player_arg="", duration_ms=400, steps=20):
    lock_file = open('/tmp/fade_play_pause.lock', 'w')
    try:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return

    status = run_cmd(f"playerctl {player_arg} status")
    if not status:
        return

    orig_vol = get_volume(player_arg)
    if orig_vol == 0:
        orig_vol = 1.0

    sleep_time = (duration_ms / 1000.0) / steps

    if status == "Playing":
        # Fade out
        for i in range(steps):
            vol = orig_vol * (1 - (i+1)/steps)
            set_volume(vol, player_arg)
            time.sleep(sleep_time)
        run_cmd(f"playerctl {player_arg} pause")
        time.sleep(0.1) # Small delay to ensure pause registers before restoring volume
        # Restore original volume for next play
        set_volume(orig_vol, player_arg)
    else:
        # Fade in
        set_volume(0, player_arg)
        run_cmd(f"playerctl {player_arg} play")
        for i in range(steps):
            vol = orig_vol * ((i+1)/steps)
            set_volume(vol, player_arg)
            time.sleep(sleep_time)
        set_volume(orig_vol, player_arg)

if __name__ == "__main__":
    player_arg = ""
    if len(sys.argv) >= 3 and sys.argv[1] == "-p":
        player_arg = f"-p '{sys.argv[2]}'"
        
    fade_play_pause(player_arg)
