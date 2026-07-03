#!/bin/bash

# ==============================================================================
# Ranjau 10 Aplikasi (Window Bomb)
# ==============================================================================

handle() {
  if [[ ${1:0:10} == "openwindow" ]]; then
    # Hitung jumlah jendela yang terbuka
    count=$(hyprctl clients -j | jq 'length')
    
    if [[ "$count" -ge 11 ]]; then
      # KABOOM! Terlalu banyak aplikasi
      notify-send -u critical "💣 KABOOM! 💥" "Terlalu banyak aplikasi (Maks 10)! Jendela meledak!"
      
      # Ambil daftar semua jendela beserta status floating-nya
      clients=$(hyprctl clients -j | jq -r '.[] | "\(.address) \(.floating)"')
      
      echo "$clients" | while read -r addr floating; do
        # Jika belum melayang (floating = false), paksa jadi melayang
        if [[ "$floating" == "false" ]]; then
          hyprctl dispatch togglefloating address:$addr
        fi
        
        # Hitung koordinat acak di layar (asumsi resolusi sekitar 1920x1080)
        ex=$(( RANDOM % 1400 + 50 ))
        ey=$(( RANDOM % 800 + 50 ))
        
        # Lemparkan jendela ke titik acak secara bersamaan
        hyprctl dispatch movewindowpixel "exact $ex $ey,address:$addr" &
      done
    fi
  fi
}

# Mendengarkan event dari Hyprland secara real-time
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
