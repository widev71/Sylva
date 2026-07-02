import QtQuick
import Quickshell
import Quickshell.Io

// Watches which widget panel is currently open (via current_widget file)
Item {
    id: root

    required property var paths
    required property string activeWidget

    signal widgetChanged(string newWidget)

    Process {
        id: widgetPoller
        running: true
        command: ["bash", "-c", "cat " + root.paths.runDir + "/current_widget 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (root.activeWidget !== txt) root.widgetChanged(txt);
            }
        }
    }

    Process {
        id: widgetWatcher
        running: true
        command: [
            "bash", "-c",
            "while [ ! -f " + root.paths.runDir + "/current_widget ]; do sleep 1; done; " +
            "inotifywait -qq -e modify,close_write " + root.paths.runDir + "/current_widget"
        ]
        onExited: {
            widgetPoller.running = false;
            widgetPoller.running = true;
            running = false;
            running = true;
        }
    }
}
