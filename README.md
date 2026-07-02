# 🍃 Sylva - Hyprland Dotfiles

Sylva adalah konfigurasi Hyprland dengan UI/UX yang modern dan dinamis, dibangun menggunakan **Quickshell**.

## 📦 Dependencies (Kebutuhan Sistem)

Sebelum menginstal, pastikan kamu menggunakan **Arch Linux** (atau distro turunannya). Berikut adalah package yang dibutuhkan:

### Core & UI
- `hyprland` - Window Manager utama
- `quickshell` - Framework untuk UI (TopBar, Popups, dll) - *Install dari AUR (`quickshell` / `quickshell-git`)*
- `matugen` - Color scheme generator otomatis berbasis wallpaper - *Install dari AUR (`matugen` / `matugen-bin`)*
- `swayosd` - OSD popups untuk indikator volume dan brightness - *Install dari AUR (`swayosd` / `swayosd-git`)*

### Sistem & Utilities
- `hypridle` & `hyprlock` - Untuk screen lock & idle daemon
- `playerctl` - Mengontrol media playback
- `cliphist` & `wl-clipboard` - Clipboard manager
- `network-manager-applet` - Network applet (dibutuhkan untuk nmcli)
- `grim` & `slurp` - Tools untuk mengambil screenshot
- `imagemagick` - Image processing (untuk efek blur dan manipulasi gambar)
- `zbar` - QR code reader (fitur scan dari screenshot)
- `jq` - JSON parser di command line
- `inotify-tools` - Digunakan untuk memantau perubahan file (script watchers)
- `pipewire` - Audio server (membutuhkan `pw-play` untuk sound effects UI)

Kamu bisa menginstal semua package di atas sekaligus menggunakan AUR helper seperti `paru` atau `yay`:

```bash
paru -S --needed hyprland quickshell-git matugen-bin swayosd-git playerctl cliphist wl-clipboard hypridle hyprlock network-manager-applet grim slurp imagemagick zbar jq inotify-tools pipewire
```

## 🚀 Instalasi

1. **Clone Repository ini** tepat di folder config kamu:
   ```bash
   git clone https://github.com/widev71/Sylva.git ~/.config/hypr
   ```

2. **Masuk ke folder Hyprland**:
   ```bash
   cd ~/.config/hypr
   ```

3. **Jalankan Script Installer**:
   ```bash
   bash install.sh
   ```
   *Script ini akan membantu mengatur hak akses script, membuat template `settings.json` yang aman, mengecek sisa dependencies, dan memasang pengaman Git agar data pribadimu tidak bocor ke publik.*

4. **Edit Pengaturan Pribadi (Opsional)**:
   Buka file `~/.config/hypr/settings.json` untuk memasukkan username sosial mediamu, mengatur monitor, sensitivitas touchpad, dll. *(Jangan khawatir, file ini otomatis di-ignore oleh Git).*

5. **Selesai!** Restart Hyprland atau Logout/Login kembali.

## ⌨️ Shortcut Dasar (Keybindings)

Sebagian besar shortcut UI menggunakan tombol `Super` (Windows/Command):

- `Super + H` : Buka Guide / Shortcut Help
- `Super + D` : Buka App Launcher
- `Super + W` : Ganti Wallpaper
- `Super + Q` : Buka Music Player
- `Super + C` : Clipboard Manager
- `Super + B` : Battery Status
- `Super + S` : Calendar
- `Super + N` : Network Manager
- `Super + V` : Volume Mixer
- `Super + Shift + S` : Buka Settings
- `Super + Shift + T` : Buka Pomodoro / Focus Time

*(Catatan: Untuk melihat daftar keybind dan kustomisasi penuh, tekan `Super + H` di desktop untuk membuka panel interaktif).*
