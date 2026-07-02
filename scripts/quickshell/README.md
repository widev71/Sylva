# 🐚 Quickshell Config — Witya's Desktop Shell

> Konfigurasi shell berbasis [Quickshell](https://quickshell.org/) untuk Hyprland, ditulis dalam QML.
> Arsitektur: **Orchestrator + Component Pattern** — setiap file maks ~200 baris.

---

## 📁 Struktur Folder

```
quickshell/
├── Shell.qml                  # Entry point utama
├── TopBar.qml                 # Orchestrator top bar
├── Floating.qml               # Orchestrator floating sidebar
├── Lock.qml                   # Orchestrator lock screen
├── Main.qml                   # Main popup/widget dispatcher
├── main/                      # ← SUDAH DIREFAKTOR ✅
│   ├── NotificationDaemon.qml     # D-Bus server + OSD popup overlay
│   └── PreloadDaemon.qml          # Widget preloader + settings.json watcher
├── Config.qml                 # Global config
├── Scaler.qml                 # Responsive scaling helper
├── Caching.qml                # Path/cache helper
├── MatugenColors.qml          # Catppuccin Mocha color theme
├── SysData.qml                # Shared system data
│
├── topbar/                    # ← SUDAH DIREFAKTOR ✅
│   ├── logic/                 # Data layer (no UI)
│   │   ├── AudioWatcher.qml       # Volume + battery poller
│   │   ├── ChassisDetector.qml    # Desktop vs laptop detect
│   │   ├── MusicLogic.qml         # MPRIS + album art
│   │   ├── NetworkWatcher.qml     # WiFi + Bluetooth
│   │   ├── RecordingWatcher.qml   # Screen recording PID
│   │   ├── SettingsWatcher.qml    # settings.json watcher
│   │   ├── UpdateWatcher.qml      # Update available flag
│   │   ├── WeatherClock.qml       # Clock + weather + typewriter
│   │   ├── WidgetWatcher.qml      # Active widget tracker
│   │   └── WorkspaceLogic.qml     # Workspace state + model
│   └── components/            # UI layer (pure visual)
│       ├── BatteryPill.qml        # Battery status pill
│       ├── BtPill.qml             # Bluetooth pill
│       ├── CenterClock.qml        # Clock + date + weather center
│       ├── KbPill.qml             # Keyboard layout pill
│       ├── LeftPanel.qml          # Help/Search/Settings buttons
│       ├── MediaBox.qml           # Album art + controls
│       ├── RecordingButton.qml    # Blinking record indicator
│       ├── SystemTrayBox.qml      # System tray icons
│       ├── TodoNotifRow.qml       # Todo + notification pills
│       ├── VolumePill.qml         # Volume pill
│       ├── WifiPill.qml           # WiFi/Ethernet pill
│       └── WorkspaceBar.qml       # Workspace pills
│
├── floating/                  # ← SUDAH DIREFAKTOR ✅
│   └── components/
│       ├── EdgeTriggers.qml       # 1px hot zones kiri/kanan/bawah
│       ├── ExpandedContent.qml    # Grid blocks + module loaders
│       ├── PeekBar.qml            # Drag handle peek
│       ├── SidebarControls.qml    # Expand + Pin buttons
│       └── TabPills.qml           # Tab pills + active highlight
│
├── lock/                      # ← SUDAH DIREFAKTOR ✅
│   ├── LockBackground.qml         # Wallpaper blur + orbit orbs
│   ├── LockCenterPanel.qml        # Clock + avatar + password
│   ├── LockDataPollers.qml        # Semua data pollers
│   ├── LockIntroAnimation.qml     # Ring burst intro
│   ├── LockLeftPanel.qml          # Telemetry + now playing
│   ├── LockPowerMenu.qml          # Power button + menu
│   └── LockRightPanel.qml         # CPU/RAM/Temp/Disk stats
│
├── applauncher/               # App launcher popup
├── battery/                   # Battery detail popup
├── calendar/                  # Calendar + weather popup
├── clipboard/                 # Clipboard manager
├── focustime/                 # Pomodoro / focus timer
├── github/                    # GitHub desktop integration
├── guide/                     # Shortcut guide panel
├── movies/                    # 🗑️ DELETED
├── music/                     # Music player popup
├── network/                   # Network popup (WiFi/BT)
├── notifications/             # Notification center + popups
├── screenshot/                # ← SUDAH DIREFAKTOR ✅
│   ├── CornerHandles.qml          # 4 corner resize handles
│   ├── QrResultPopup.qml          # QR bounding boxes + popup cards
│   ├── SelectionOverlay.qml       # Dim rects + selection tint
│   ├── TabSwitcher.qml            # Screenshot/video mode pill
│   └── ToolbarPanel.qml           # Bottom toolbar (audio + capture circle)
│
├── quickactions/              # Floating sidebar modules
│   ├── DrawAction.qml             # Drawing pad
│   ├── SystemUsage.qml            # Real-time sys stats
│   └── Timer.qml                  # Countdown timer
├── settings/                  # Settings popup
│   ├── SettingsPopup.qml          # Orchestrator (tab nav + keyboard + search)
│   ├── SettingsGeneralTab.qml     # Tab: Umum (lang, wallpaper, layout, scale)
│   ├── SettingsWeatherTab.qml     # Tab: Cuaca (API key, city, provider)
│   ├── SettingsKeybindTab.qml     # Tab: Pintasan (keybind editor)
│   ├── SettingsMonitorsTab.qml    # Tab: Monitor (resolution, rate, transform)
│   ├── SettingsStartupTab.qml     # Tab: Autostart (startup command editor)
│   └── SettingsProfileTab.qml     # Tab: Profil (user info)
├── stewart/                   # Stewart widget
├── todo/                      # Todo list popup
├── updater/                   # System updater popup
├── volume/                    # Volume OSD popup
├── wallpaper/                 # Wallpaper picker
└── watchers/                  # Bash watcher scripts
    ├── audio_fetch.sh / audio_wait.sh
    ├── battery_fetch.sh / battery_wait.sh
    ├── bt_fetch.sh / bt_wait.sh
    ├── kb_fetch.sh / kb_wait.sh
    └── network_fetch.sh / network_wait.sh
```

---

## 🎯 Status Refactor

| File | Sebelum | Sesudah | Status |
|------|---------|---------|--------|
| `TopBar.qml` | 1654 baris | 343 baris + 22 komponen | ✅ Done |
| `Floating.qml` | 1270 baris | 526 baris + 5 komponen | ✅ Done |
| `Lock.qml` | 1032 baris | 300 baris + 7 komponen | ✅ Done |
| `ScreenshotOverlay.qml` | 998 baris | 410 baris + 5 komponen | ✅ Done |
| `Main.qml` | 541 baris | 280 baris + 2 komponen | ✅ Done |
| `Config.qml` | 467 baris | — | 🔲 Antrian |
| `settings/SettingsPopup.qml` | 4785 baris | 3791 baris + 6 komponen | ✅ Done |
| `network/NetworkPopup.qml` | 2556 baris | — | ⏭️ Skip (terlalu coupled) |
| `guide/GuidePopup.qml` | 2034 baris | — | 👤 User akan refactor |
| `wallpaper/WallpaperPicker.qml` | 1826 baris | — | ⏭️ Skip (monolitik) |
| `movies/MovieWidget.qml` | 1818 baris | Dihapus | 🗑️ Deleted |
| `calendar/CalendarPopup.qml` | 1600 baris | — | ⏭️ Skip (monolitik) |
| `battery/BatteryPopupAlt.qml` | 1555 baris | — | ⏭️ Skip (monolitik) |
| `focustime/FocusTimePopup.qml` | 1539 baris | — | ⏭️ Skip (monolitik) |
| `music/MusicPopup.qml` | 1404 baris | — | ⏭️ Skip (monolitik) |

---

## 🏗️ Pola Arsitektur

### Aturan utama

- **Maks 200 baris per file** (orchestrator boleh hingga ~350 karena layout math)
- **Logic ≠ UI** — pisahkan data polling dari visual
- **`required property`** untuk semua dependensi eksternal
- **Signal** untuk komunikasi dari child ke parent (bukan direct binding ke parent id)

### Pattern: Orchestrator + Component

```
ParentOrchestrator.qml          ← state, math, timers, IPC
├── logic/
│   ├── DataWatcher.qml         ← Process + StdioCollector
│   └── StateLogic.qml          ← kalkulasi murni
└── components/
    ├── VisualA.qml             ← required property, signal
    └── VisualB.qml             ← required property, signal
```

### Pattern: Data Watcher

```qml
Item {
    // 1. Expose typed properties
    property string value: ""

    // 2. Poller process
    Process {
        id: poller
        command: ["bash", "-c", "~/.config/hypr/scripts/watchers/fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim()
                if (txt !== "") root.value = txt
                waiter.running = false
                waiter.running = true
            }
        }
    }

    // 3. inotifywait watcher → re-trigger poller
    Process {
        id: waiter
        command: ["bash", "-c", "~/.config/hypr/scripts/watchers/wait.sh"]
        onExited: { poller.running = false; poller.running = true }
    }
}
```

### Pattern: UI Component

```qml
Rectangle {
    id: root

    // Semua dependensi via required property
    required property var  mocha
    required property real someValue
    required property var  s        // scale function

    // Signal naik ke parent
    signal actionTriggered

    // Tidak ada referensi ke id luar (parent.id, dll)
}
```

---

## 🔄 Cara Update Dokumentasi

Ketika kamu selesai merefaktor satu file baru, update bagian **Status Refactor** di atas:

1. Ubah `🔲 Next` / `🔲 Antrian` → `✅ Done`
2. Isi kolom **Sesudah** dengan jumlah baris orchestrator + jumlah komponen
3. Tambah folder baru ke **Struktur Folder** jika ada direktori baru

**Contoh update satu baris:**

```diff
- | `ScreenshotOverlay.qml` | 998 baris  | —                           | 🔲 Next    |
+ | `ScreenshotOverlay.qml` | 998 baris  | 180 baris + 6 komponen      | ✅ Done    |
```

---

## ⚡ IPC Commands

```bash
# Reload TopBar
quickshell ipc -p ~/.config/hypr/scripts/quickshell/Shell.qml call topbar forceReload

# Reload Floating sidebar
quickshell ipc -p ~/.config/hypr/scripts/quickshell/Shell.qml call floating forceReload

# Toggle update badge
quickshell ipc -p ~/.config/hypr/scripts/quickshell/Shell.qml call topbar toggleUpdate

# Set floating sidebar tab (0-indexed)
quickshell ipc -p ~/.config/hypr/scripts/quickshell/Shell.qml call floating setIndex 1
```

---

## 🔬 Cara Test Setelah Refactor

```bash
# 1. Lint semua file baru
for f in path/to/new/*.qml; do
  result=$(qmllint "$f" 2>&1)
  [ -n "$result" ] && echo "❌ $f: $result" || echo "✅ $(basename $f)"
done

# 2. Reload via IPC
quickshell ipc -p ~/.config/hypr/scripts/quickshell/Shell.qml call <target> forceReload

# 3. Verifikasi IPC targets masih terdaftar
quickshell ipc -p ~/.config/hypr/scripts/quickshell/Shell.qml show
```

---

## 🎨 Color Palette (Catppuccin Mocha)

Semua warna diakses via `mocha.<name>` dari `MatugenColors`:

| Token | Hex | Digunakan untuk |
|-------|-----|-----------------|
| `mocha.base` | `#1e1e2e` | Background panel |
| `mocha.mauve` | `#cba6f7` | Accent utama, border aktif |
| `mocha.text` | `#cdd6f4` | Teks utama |
| `mocha.subtext0` | `#a6adc8` | Teks sekunder |
| `mocha.surface0` | `#313244` | Background pill |
| `mocha.green` | `#a6e3a1` | Charging, update badge |
| `mocha.red` | `#f38ba8` | Error, recording, power |
| `mocha.blue` | `#89b4fa` | WiFi connected, time |
| `mocha.peach` | `#fab387` | Volume aktif |

---

## 📝 Catatan Sesi

- **Backup** selalu dibuat sebelum overwrite (`*.qml.bak`, `*.bak2`, dll)
- **`qmllint`** dijalankan tiap selesai refaktor — zero errors adalah syarat lanjut
- Refaktor dilakukan bersama Antigravity AI (Gemini) secara pair-programming
