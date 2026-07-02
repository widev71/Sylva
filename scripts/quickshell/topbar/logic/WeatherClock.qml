import QtQuick
import Quickshell
import Quickshell.Io

// Provides current time, date (with typewriter animation), and weather data
Item {
    id: root

    property string timeStr: ""
    property string fullDateStr: ""
    property int    typeInIndex: 0
    property string dateStr: fullDateStr.substring(0, typeInIndex)

    property string weatherIcon: ""
    property string weatherTemp: "--°"
    property string weatherHex: "#f9e2af"   // fallback yellow

    // Set to true externally once startup is ready to begin typewriter
    property bool startupReady: false

    // ── Clock ─────────────────────────────────────────────────────────
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.timeStr     = Qt.formatDateTime(d, "HH:mm:ss");
            root.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
            if (root.typeInIndex >= root.fullDateStr.length)
                root.typeInIndex = root.fullDateStr.length;
        }
    }

    Timer {
        id: typewriterTimer
        interval: 40
        running: root.startupReady && root.typeInIndex < root.fullDateStr.length
        repeat: true
        onTriggered: root.typeInIndex += 1
    }

    // ── Weather ───────────────────────────────────────────────────────
    Process {
        id: weatherPoller
        command: [
            "bash", "-c",
            "echo \"$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)\"\n" +
            "echo \"$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)\"\n" +
            "echo \"$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    root.weatherIcon = lines[0];
                    root.weatherTemp = lines[1];
                    root.weatherHex  = lines[2] || root.weatherHex;
                }
            }
        }
    }

    // Refresh weather every 2.5 minutes
    Timer {
        interval: 150000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            weatherPoller.running = false;
            weatherPoller.running = true;
        }
    }
}
