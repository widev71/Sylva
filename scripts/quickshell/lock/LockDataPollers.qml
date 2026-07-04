import QtQuick
import Quickshell
import Quickshell.Io

// All data pollers for the lock screen: chassis, user, keyboard, battery,
// weather, uptime, system stats, and now-playing music.
Item {
    id: root

    required property var paths

    // ── Exposed state ─────────────────────────────────────────────────
    property string batPct:      "100"
    property string batStatus:   "AC"
    property string currentUser: "User"
    property string faceIconPath: ""
    property string kbLayout:    "US"
    property string weatherIcon: ""
    property string weatherTemp: "--°C"
    property string weatherDesc: "Unknown"
    property string weatherHigh: "--°C"
    property string weatherLow:  "--°C"
    property color  weatherHex:  "#cdd6f4"
    property string uptimeStr:   "--"
    property bool   isDesktop:   false

    property real   cpuPct:  0
    property real   ramPct:  0
    property real   diskPct: 0
    property real   tempVal: 0

    property string musicTitle:  ""
    property string musicArtist: ""
    property string musicArtPath: ""
    property bool   musicPlaying: false
    property bool   musicActive:  false
    property real   musicProgress: 0.0
    property string musicPositionStr: "00:00"
    property string musicLengthStr: "00:00"
    property real   musicLengthSecs: 0.0

    // ── Chassis ───────────────────────────────────────────────────────
    Process {
        running: true
        command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1>/dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.isDesktop = (this.text.trim() === "desktop")
        }
    }

    // ── User info ─────────────────────────────────────────────────────
    Process {
        command: ["bash", "-c",
            "USER_VAR=$(whoami); ICON_PATH=\"\"; if [ -f ~/.face.icon ]; then ICON_PATH=$(readlink -f ~/.face.icon); elif [ -f ~/.face ]; then ICON_PATH=$(readlink -f ~/.face); fi; echo -n \"$USER_VAR|$ICON_PATH\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("|");
                if (parts.length > 0 && parts[0] !== "") root.currentUser = parts[0];
                if (parts.length > 1 && parts[1].trim() !== "") {
                    let p = parts[1].trim();
                    root.faceIconPath = p.startsWith("file://") ? p : "file://" + p;
                }
            }
        }
        Component.onCompleted: running = true
    }

    // ── Keyboard layout ───────────────────────────────────────────────
    Process {
        id: kbPoller
        command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let layout = this.text.trim();
                if (layout !== "" && layout !== "null") root.kbLayout = layout;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbPoller.running = true }

    // ── Battery ───────────────────────────────────────────────────────
    Process {
        id: batPoller
        running: !root.isDesktop
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '100'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'AC'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 2) { root.batPct = lines[0] || "100"; root.batStatus = lines[1] || "Unknown"; }
            }
        }
    }
    Timer { interval: 5000; running: !root.isDesktop; repeat: true; triggeredOnStart: true; onTriggered: batPoller.running = true }

    // ── Weather ───────────────────────────────────────────────────────
    Process {
        id: weatherPoller
        property string scriptPath: Qt.resolvedUrl("../calendar/weather.sh").toString().replace(/^file:\/\//, "")
        command: ["bash", "-c", '"' + scriptPath + '" --current-icon; "' + scriptPath + '" --current-temp; "' + scriptPath + '" --current-description; "' + scriptPath + '" --high; "' + scriptPath + '" --low; "' + scriptPath + '" --current-hex']
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 1) root.weatherIcon = lines[0] || "";
                if (lines.length >= 2) root.weatherTemp = lines[1] || "--°C";
                if (lines.length >= 3) root.weatherDesc = lines[2] || "Unknown";
                if (lines.length >= 4) root.weatherHigh = lines[3] || "--°C";
                if (lines.length >= 5) root.weatherLow  = lines[4] || "--°C";
                if (lines.length >= 6) root.weatherHex  = lines[5] || "#cdd6f4";
            }
        }
    }
    Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

    // ── Uptime ────────────────────────────────────────────────────────
    Process {
        id: uptimePoller
        command: ["bash", "-c", "uptime -p | sed 's/up //'"]
        stdout: StdioCollector {
            onStreamFinished: { let t = this.text.trim(); if (t !== "") root.uptimeStr = t; }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: uptimePoller.running = true }

    // ── System stats ──────────────────────────────────────────────────
    Process {
        id: sysStatsPoller
        command: ["bash", "-c", [
            "cpu=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | tr -d '%us,' | head -n1);",
            "ram=$(free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}');",
            "disk=$(df / | awk 'NR==2{printf \"%.0f\", $3/$2*100}');",
            "temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -n1 | awk '{printf \"%.0f\", $1/1000}' || echo '0');",
            "echo \"$cpu|$ram|$disk|$temp\""
        ].join(" ")]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("|");
                if (parts.length >= 4) {
                    root.cpuPct  = parseFloat(parts[0]) || 0;
                    root.ramPct  = parseFloat(parts[1]) || 0;
                    root.diskPct = parseFloat(parts[2]) || 0;
                    root.tempVal = parseFloat(parts[3]) || 0;
                }
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: sysStatsPoller.running = true }

    // ── Music ─────────────────────────────────────────────────────────
    Process {
        id: musicPoller
        command: ["bash", "-c", [
            "DATA=$(timeout 1 playerctl metadata --format '{{status}}|{{title}}|{{artist}}|{{mpris:artUrl}}|{{position}}|{{mpris:length}}|{{duration(position)}}|{{duration(mpris:length)}}' 2>/dev/null);",
            "if [ -n \"$DATA\" ]; then echo \"$DATA\"; else echo 'Stopped|||||||'; fi"
        ].join(" ")]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("|");
                let status = parts[0] || "Stopped";
                root.musicActive  = (status === "Playing" || status === "Paused");
                root.musicPlaying = (status === "Playing");
                
                let newTitle = parts[1] || "";
                let newArtist = parts[2] || "";
                let newArt = parts[3] || "";
                
                if (root.musicTitle !== newTitle || root.musicArtist !== newArtist) {
                    root.musicTitle   = newTitle;
                    root.musicArtist  = newArtist;
                    if (newArt !== "") {
                        root.musicArtPath = "file:///tmp/album_art.jpg?v=" + new Date().getTime();
                    } else {
                        root.musicArtPath = "";
                    }
                }

                let pos = parseFloat(parts[4]) || 0;
                let len = parseFloat(parts[5]) || 0;
                root.musicLengthSecs = len / 1000000.0;
                if (len > 0) {
                    root.musicProgress = pos / len;
                } else {
                    root.musicProgress = 0;
                }
                
                let pStr = parts[6] || "";
                let lStr = parts[7] || "";
                root.musicPositionStr = pStr !== "" ? pStr : "00:00";
                root.musicLengthStr = lStr !== "" ? lStr : "00:00";
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: musicPoller.running = true }

    Process { id: musicPlayCmd;  command: ["playerctl", "play-pause"] }
    Process { id: musicNextCmd;  command: ["playerctl", "next"] }
    Process { id: musicPrevCmd;  command: ["playerctl", "previous"] }

    function playPause() { musicPlayCmd.running = true; }
    function next()      { musicNextCmd.running = true; }
    function prev()      { musicPrevCmd.running = true; }
    Process {
        id: musicSeekCmd
        property real targetSec: 0
        command: ["playerctl", "position", targetSec.toString()]
    }
    function seekMusic(percent) {
        musicSeekCmd.targetSec = percent * root.musicLengthSecs;
        musicSeekCmd.running = true;
    }

    // ── Synchronized Lyrics ───────────────────────────────────────────
    property int currentLyricIndex: -1
    property var lyricsList: []
    
    property string currentSongKey: ""

    FileView {
        id: lyricsStateFile
        path: "/tmp/lyrics_state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let txt = text().trim();
            if (txt === "") return;
            try {
                let obj = JSON.parse(txt);
                
                // Only update the model if the song has changed to prevent UI stutter!
                if (root.currentSongKey !== obj.song) {
                    root.currentSongKey = obj.song || "";
                    root.lyricsList = obj.lines || [];
                }
                
                root.currentLyricIndex = obj.index ?? -1;
            } catch(e) {}
        }
    }
}
