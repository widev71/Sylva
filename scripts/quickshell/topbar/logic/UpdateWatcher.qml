import QtQuick
import Quickshell
import Quickshell.Io

// Watches the updater cache dir for a pending update flag
Item {
    id: root

    required property var paths
    property bool updateAvailable: false

    Process {
        id: updatePoller
        running: true
        command: [
            "bash", "-c",
            "if [ -f " + root.paths.getCacheDir("updater") + "/update_pending ]; then echo '1'; else echo '0'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.updateAvailable = (this.text.trim() === "1");
            }
        }
    }

    Process {
        id: updateWatcher
        running: true
        command: [
            "bash", "-c",
            "inotifywait -qq -e create,delete,close_write " +
            root.paths.getCacheDir("updater") + "/ 2>/dev/null || sleep 5"
        ]
        onExited: {
            updatePoller.running = false;
            updatePoller.running = true;
            running = false;
            running = true;
        }
    }
}
