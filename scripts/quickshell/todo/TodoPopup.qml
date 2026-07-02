import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

PanelWindow {
    id: window
    WlrLayershell.namespace: "qs-todo"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property var layoutData: null
    property real uiScale: 1.0
    function s(val) { return Math.round(val * uiScale) }
    
    anchors { top: true; left: true; bottom: false; right: false }
    width: layoutData ? layoutData.w : s(400)
    height: layoutData ? layoutData.h : s(600)
    margins.left: layoutData ? layoutData.rx : 0
    margins.top: layoutData ? layoutData.ry : 0
    
    MatugenColors { id: theme }

    property var todos: []
    property bool isExpanded: false

    IpcHandler {
        target: "todo"
        function toggle() {
            window.isExpanded = !window.isExpanded;
            if (window.isExpanded) {
                introCore = 0;
                introAnim.restart();
                readProc.running = true;
            }
        }
        function close() { window.isExpanded = false; }
    }

    property real introCore: 0
    NumberAnimation { id: introAnim; target: window; property: "introCore"; from: 0; to: 1; duration: 400; easing.type: Easing.OutExpo }
    
    Process {
        id: readProc; running: false
        command: ["bash", "-c", "cat ~/.todo.json 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { window.todos = JSON.parse(this.text || "[]") } catch(e) { window.todos = [] }
                todoModel.clear()
                for (let i=0; i<window.todos.length; i++) todoModel.append({ text: window.todos[i] })
            }
        }
    }
    
    Process {
        id: writeProc; running: false
        property string jsonStr: "[]"
        command: ["bash", "-c", "echo '" + jsonStr.replace(/'/g, "'\\''") + "' > ~/.todo.json"]
    }
    
    function saveTodos() {
        let arr = []
        for (let i=0; i<todoModel.count; i++) arr.push(todoModel.get(i).text)
        writeProc.jsonStr = JSON.stringify(arr)
        writeProc.running = false
        writeProc.running = true
    }

    Item {
        id: coreRoot
        anchors.fill: parent
        visible: window.isExpanded || introAnim.running
        opacity: introCore
        transform: Translate { y: s(30) * (1 - introCore) }

        // Blur backdrop
        Rectangle {
            id: bgMask
            anchors.fill: parent
            radius: s(24)
            color: "black"
            visible: false
        }
        MultiEffect {
            source: bgMask
            anchors.fill: parent
            maskEnabled: true
            maskSource: bgMask
            blurEnabled: true
            blurMax: 32
            blur: 1.0
            brightness: -0.1
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.75)
            radius: s(24)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: s(24)
                spacing: s(16)
                
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: ""; color: theme.green; font.family: "Iosevka Nerd Font"; font.pixelSize: s(24) }
                    Text { text: "To-Do List"; font.pixelSize: s(20); color: theme.text; font.weight: Font.Black; font.family: "JetBrains Mono"; Layout.fillWidth: true }
                    Rectangle {
                        width: s(32); height: s(32); radius: s(16); color: closeMa.containsMouse ? Qt.rgba(1,0,0,0.5) : "transparent"
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { text: ""; color: theme.red; font.family: "Iosevka Nerd Font"; font.pixelSize: s(18); anchors.centerIn: parent }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.isExpanded = false; cursorShape: Qt.PointingHandCursor }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.1) }
                
                ListView {
                    id: listView
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: ListModel { id: todoModel }
                    spacing: s(8)
                    clip: true
                    delegate: Rectangle {
                        width: listView.width; height: s(48); color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.6); radius: s(12)
                        border.color: Qt.rgba(1,1,1,0.05); border.width: 1
                        scale: itemMa.containsMouse ? 1.02 : 1.0
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: s(12)
                            Text { text: ""; color: theme.green; font.family: "Iosevka Nerd Font"; font.pixelSize: s(14) }
                            Text { text: model.text; color: theme.text; Layout.fillWidth: true; font.family: "JetBrains Mono"; font.weight: Font.Medium; elide: Text.ElideRight }
                            Text { 
                                text: ""; color: delMa.containsMouse ? theme.red : theme.subtext0; font.family: "Iosevka Nerd Font"; font.pixelSize: s(16)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                MouseArea { id: delMa; anchors.fill: parent; anchors.margins: -s(8); hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { todoModel.remove(index); saveTodos() } }
                            }
                        }
                        MouseArea { id: itemMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
                    }
                }
                
                TextField {
                    id: inputField
                    Layout.fillWidth: true; height: s(48)
                    placeholderText: "Add a new task... (Press Enter)"
                    color: theme.text
                    background: Rectangle { color: theme.surface1; radius: s(12); border.color: inputField.activeFocus ? theme.green : "transparent"; border.width: 1 }
                    font.family: "JetBrains Mono"; font.pixelSize: s(14); font.weight: Font.Medium
                    leftPadding: s(16); rightPadding: s(16)
                    onAccepted: {
                        if (text.trim() !== "") {
                            todoModel.append({ text: text.trim() })
                            saveTodos()
                            text = ""
                        }
                    }
                }
            }
        }
    }
}
