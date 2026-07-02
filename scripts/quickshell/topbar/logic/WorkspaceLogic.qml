import QtQuick
import Quickshell
import Quickshell.Io

// Manages workspace daemon, reads workspaces.json, and watches for changes
Item {
    id: root

    required property var paths
    property int workspaceCount: 8

    // The workspace ListModel — bind to this in UI
    property alias model: workspacesModel

    ListModel {
        id: workspacesModel
        property int activeIndex: 0
    }

    // Restart the workspace script daemon when workspaceCount changes
    onWorkspaceCountChanged: {
        wsDaemon.running = false;
        wsDaemon.running = true;
    }

    Process {
        id: wsDaemon
        command: ["bash", "-c", "~/.config/hypr/scripts/workspaces.sh"]
        running: true
    }

    Process {
        id: wsReader
        running: true
        command: ["cat", root.paths.getRunDir("workspaces") + "/workspaces.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt === "") return;
                try {
                    let newData = JSON.parse(txt);

                    while (workspacesModel.count < newData.length)
                        workspacesModel.append({ "wsId": "", "wsState": "" });
                    while (workspacesModel.count > newData.length)
                        workspacesModel.remove(workspacesModel.count - 1);

                    let newActive = -1;
                    for (let i = 0; i < newData.length; i++) {
                        if (newData[i].state === "active") newActive = i;
                        if (workspacesModel.get(i).wsState !== newData[i].state)
                            workspacesModel.setProperty(i, "wsState", newData[i].state);
                        if (workspacesModel.get(i).wsId !== newData[i].id.toString())
                            workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                    }

                    if (newActive !== -1 && workspacesModel.activeIndex !== newActive)
                        workspacesModel.activeIndex = newActive;

                } catch (e) {}
            }
        }
    }

    Process {
        id: wsWatcher
        running: true
        command: [
            "bash", "-c",
            "inotifywait -qq -e close_write,modify " +
            root.paths.getRunDir("workspaces") + "/workspaces.json"
        ]
        onExited: {
            wsReader.running = false;
            wsReader.running = true;
            running = false;
            running = true;
        }
    }
}
