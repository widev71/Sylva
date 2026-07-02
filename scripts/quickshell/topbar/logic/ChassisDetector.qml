import QtQuick
import Quickshell
import Quickshell.Io

// Detects whether the system is a desktop (no battery) or laptop
Item {
    id: root

    property bool isDesktop: false

    Process {
        id: chassisDetector
        running: true
        command: [
            "bash", "-c",
            "if ls /sys/class/power_supply/BAT* 1>/dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isDesktop = (this.text.trim() === "desktop");
            }
        }
    }
}
