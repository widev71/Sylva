<div align="center">
  <h1>🍃 Sylva</h1>
  <p><strong>A Modern, Dynamic, and Glassmorphic Hyprland Configuration</strong></p>
  <p>Built with <a href="https://github.com/outfoxxed/quickshell">Quickshell</a> for an unparalleled UI/UX experience on Wayland.</p>
</div>

---

## ✨ Features

Sylva transforms your Hyprland setup into a premium desktop experience.

- 🎨 **Dynamic Colors**: Powered by `matugen`, your entire system theme adapts instantly when you change your wallpaper.
- 🪟 **Glassmorphism Design**: Beautiful frosted glass effects, subtle drop shadows, and customizable opacity rules for a truly modern aesthetic.
- 🚀 **Quickshell UI**: Lightning-fast QML-based widgets including a TopBar, Control Center, App Launcher, and floating popups.
- 🎵 **Integrated Media Player**: Rich music controls and lyrics support directly on your desktop.
- 📸 **Advanced Screenshot Tool**: Built-in screenshot utility with selection overlays, countdowns, and instant QR code scanning.
- 🍅 **Focus Mode**: Built-in Pomodoro timer to keep you productive.
- 🔒 **Custom Lockscreen**: Secure and beautiful lockscreen powered by Quickshell.

## 📦 Dependencies

To get the full Sylva experience, you need the following packages installed. (Arch Linux is highly recommended).

### Core & UI
*   `hyprland` - The main Wayland compositor.
*   `quickshell-git` (AUR) - The core UI framework powering Sylva.
*   `matugen-bin` (AUR) - Automatic color scheme generation from wallpapers.
*   `swayosd-git` (AUR) - On-screen display for volume and brightness.

### System Utilities
*   `hypridle` & `hyprlock` - Idle daemon and secure lock screen fallback.
*   `playerctl` - Media player control.
*   `cliphist` & `wl-clipboard` - Advanced clipboard management.
*   `network-manager-applet` - Network management tray (nmcli backend).
*   `grim` & `slurp` - Wayland screenshot utilities.
*   `imagemagick` - Image processing for dynamic UI blurs.
*   `zbar` - QR code reader for the screenshot tool.
*   `jq` & `inotify-tools` - JSON parsing and file watching scripts.
*   `pipewire` & `pw-play` - Audio server and sound effects.

**One-liner installation (using `paru` atau `yay`):**
```bash
paru -S --needed hyprland quickshell-git matugen-bin swayosd-git playerctl cliphist wl-clipboard hypridle hyprlock network-manager-applet grim slurp imagemagick zbar jq inotify-tools pipewire
```

## 🚀 Installation

1. **Clone the Repository** directly into your config directory:
   ```bash
   git clone https://github.com/widev71/Sylva.git ~/.config/hypr
   ```
2. **Navigate to the directory**:
   ```bash
   cd ~/.config/hypr
   ```
3. **Run the Setup Script**:
   ```bash
   bash install.sh
   ```
   *This script sets up script permissions, generates a safe `settings.json`, verifies dependencies, and configures Git to prevent accidental commits of personal data.*
4. **Personalize (Optional)**:
   Edit `~/.config/hypr/settings.json` to configure your monitors, touchpad sensitivity, and social links. *(This file is git-ignored automatically).*
5. **Reload**: Restart Hyprland or log out and log back in to apply everything!

## ⌨️ Keybindings

Most UI elements are bound to the `Super` (Windows/Command) key. 

| Shortcut | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>H</kbd> | Open Interactive Guide / Help Panel |
| <kbd>Super</kbd> + <kbd>D</kbd> | Open App Launcher |
| <kbd>Super</kbd> + <kbd>W</kbd> | Wallpaper Picker |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Music Player / Lyrics |
| <kbd>Super</kbd> + <kbd>C</kbd> | Clipboard Manager |
| <kbd>Super</kbd> + <kbd>B</kbd> | Battery Status |
| <kbd>Super</kbd> + <kbd>S</kbd> | Calendar |
| <kbd>Super</kbd> + <kbd>N</kbd> | Network Manager |
| <kbd>Super</kbd> + <kbd>V</kbd> | Volume Mixer |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Open Settings Panel |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>T</kbd> | Start Focus Time / Pomodoro |

## 🛠️ Configuration & Tweaks

Sylva is designed to be easily tweaked! Check the `config/` directory for split configuration files:
*   `settings.conf`: Edit your gaps, rounding, opacity, and blur settings here.
*   `rules.conf`: Define window rules, floating apps, and layer rules.
*   `keybinds.conf`: Add or modify your custom shortcuts.

---
<div align="center">
  <p>Made with ❤️ by the Sylva community.</p>
</div>
