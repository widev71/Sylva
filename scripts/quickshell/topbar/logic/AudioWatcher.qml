import QtQuick
import Quickshell
import Quickshell.Io

// Polls keyboard layout, audio state, and battery via watcher scripts
Item {
    id: root

    property string kbLayout: "us"
    property string volPercent: "0%"
    property string volIcon: "󰕾"
    property bool   isMuted: false
    property string batPercent: "100%"
    property string batIcon: "󰁹"
    property string batStatus: "Unknown"

    // Emits true once first KB poll completes (used for startup readiness)
    signal fastPollerLoaded

    // ── Keyboard ────────────────────────────────────────────────────
    Process {
        id: kbPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && root.kbLayout !== txt) root.kbLayout = txt;
                kbWaiter.running = false;
                kbWaiter.running = true;
                root.fastPollerLoaded();
            }
        }
    }
    Process {
        id: kbWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_wait.sh"]
        onExited: { kbPoller.running = false; kbPoller.running = true; }
    }

    // ── Audio ────────────────────────────────────────────────────────
    Process {
        id: audioPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        let newVol = data.volume.toString() + "%";
                        if (root.volPercent !== newVol) root.volPercent = newVol;
                        if (root.volIcon !== data.icon) root.volIcon = data.icon;
                        let newMuted = (data.is_muted === "true");
                        if (root.isMuted !== newMuted) root.isMuted = newMuted;
                    } catch (e) {}
                }
                audioWaiter.running = false;
                audioWaiter.running = true;
            }
        }
    }
    Process {
        id: audioWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]
        onExited: { audioPoller.running = false; audioPoller.running = true; }
    }

    // ── Battery ──────────────────────────────────────────────────────
    Process {
        id: batteryPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        let newBat = data.percent.toString() + "%";
                        if (root.batPercent !== newBat) root.batPercent = newBat;
                        if (root.batIcon !== data.icon) root.batIcon = data.icon;
                        if (root.batStatus !== data.status) root.batStatus = data.status;
                    } catch (e) {}
                }
                batteryWaiter.running = false;
                batteryWaiter.running = true;
            }
        }
    }
    Process {
        id: batteryWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]
        onExited: { batteryPoller.running = false; batteryPoller.running = true; }
    }
}
