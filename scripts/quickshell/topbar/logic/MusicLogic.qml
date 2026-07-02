import QtQuick
import Quickshell
import Quickshell.Io

// Manages MPRIS music data: force-refresh, dbus watching, and real-time tick
Item {
    id: root

    required property var paths

    property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }
    property string displayTitle: ""
    property string displayTime: ""
    property string displayArtUrl: ""

    onMusicDataChanged: {
        if (musicData && musicData.status !== "Stopped" && musicData.title !== "") {
            displayTitle = musicData.title;
            displayTime  = musicData.timeStr;
            displayArtUrl = musicData.artUrl;
        }
    }

    property bool isMediaActive: musicData.status !== "Stopped" && musicData.title !== ""

    // Force refresh music info from script
    Process {
        id: musicForceRefresh
        running: true
        command: [
            "bash", "-c",
            "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee " +
            root.paths.getRunDir("music") + "/music_info.json"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { root.musicData = JSON.parse(txt); } catch (e) {}
                }
            }
        }
    }

    // Tick position forward every second while playing
    Timer {
        interval: 1000
        running: root.musicData !== null && root.musicData.status === "Playing"
        repeat: true
        onTriggered: {
            if (!root.musicData || root.musicData.status !== "Playing") return;
            if (!root.musicData.timeStr || root.musicData.timeStr === "") return;

            let parts = root.musicData.timeStr.split(" / ");
            if (parts.length !== 2) return;

            let posParts = parts[0].split(":").map(Number);
            let lenParts = parts[1].split(":").map(Number);

            let posSecs = (posParts.length === 3)
                ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2])
                : (posParts[0] * 60 + posParts[1]);

            let lenSecs = (lenParts.length === 3)
                ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2])
                : (lenParts[0] * 60 + lenParts[1]);

            if (isNaN(posSecs) || isNaN(lenSecs)) return;

            posSecs = Math.min(posSecs + 1, lenSecs);

            let newPosStr = "";
            if (posParts.length === 3) {
                let h = Math.floor(posSecs / 3600);
                let m = Math.floor((posSecs % 3600) / 60);
                let s = posSecs % 60;
                newPosStr = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
            } else {
                let m = Math.floor(posSecs / 60);
                let s = posSecs % 60;
                newPosStr = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
            }

            let newData = Object.assign({}, root.musicData);
            newData.timeStr    = newPosStr + " / " + parts[1];
            newData.positionStr = newPosStr;
            if (lenSecs > 0) newData.percent = (posSecs / lenSecs) * 100;
            root.musicData = newData;
        }
    }

    // Watch DBus for MPRIS property changes and seek events
    Process {
        id: mprisWatcher
        running: true
        command: [
            "bash", "-c",
            "dbus-monitor --session " +
            "\"type='signal',interface='org.freedesktop.DBus.Properties'," +
            "member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" " +
            "\"type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'\" " +
            "2>/dev/null | grep -m 1 'member=' >/dev/null || sleep 2"
        ]
        onExited: {
            musicForceRefresh.running = false;
            musicForceRefresh.running = true;
            running = false;
            running = true;
        }
    }

    // Retry fetching art if placeholder was returned
    Timer {
        id: artRetryTimer
        interval: 500
        repeat: true
        running: root.displayArtUrl && root.displayArtUrl.indexOf("placeholder_blank.png") !== -1
        onTriggered: {
            musicForceRefresh.running = false;
            musicForceRefresh.running = true;
        }
    }

    // Allow UI to trigger a manual refresh (e.g. playerctl previous/next/play-pause)
    function refresh() {
        musicForceRefresh.running = false;
        musicForceRefresh.running = true;
    }
}
