import QtQuick
import Quickshell
import Quickshell.Io

// Watches whether a screen recording is currently active
Item {
    id: root

    required property var paths
    property bool isRecording: false

    Process {
        id: recPoller
        command: [
            "bash", "-c",
            "if [ -s " + root.paths.getCacheDir("recording") + "/rec_pid ] && " +
            "kill -0 $(cat " + root.paths.getCacheDir("recording") + "/rec_pid) 2>/dev/null; " +
            "then echo '1'; else echo '0'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isRecording = (this.text.trim() === "1");
            }
        }
    }

    Process {
        id: recWatcher
        running: true
        command: [
            "bash", "-c",
            "inotifywait -qq -e create,delete,modify,close_write " +
            root.paths.getCacheDir("recording") + "/ 2>/dev/null || sleep 2"
        ]
        onExited: {
            recPoller.running = false;
            recPoller.running = true;
            running = false;
            running = true;
        }
    }
}
