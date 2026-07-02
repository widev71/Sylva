import QtQuick
import Quickshell
import Quickshell.Io

// Reads ~/.config/hypr/settings.json and watches for changes
Item {
    id: root

    property bool showHelpIcon: true
    property int workspaceCount: 8


    Process {
        id: settingsReader
        running: true
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let txt = this.text.trim();
                    if (txt.length > 0 && txt !== "{}") {
                        let parsed = JSON.parse(txt);

                        if (parsed.topbarHelpIcon !== undefined &&
                            root.showHelpIcon !== parsed.topbarHelpIcon) {
                            root.showHelpIcon = parsed.topbarHelpIcon;
                        }

                        if (parsed.workspaceCount !== undefined &&
                            root.workspaceCount !== parsed.workspaceCount) {
                            root.workspaceCount = parsed.workspaceCount;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: settingsWatcher
        running: true
        command: [
            "bash", "-c",
            "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; " +
            "inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                settingsReader.running = false;
                settingsReader.running = true;
                settingsWatcher.running = false;
                settingsWatcher.running = true;
            }
        }
    }
}
