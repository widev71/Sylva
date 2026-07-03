//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    // =========================================================
    // --- MODULE CAPABILITIES EXPORT
    // =========================================================
    property int requestedLayoutTemplate: 1
    property bool isActiveTab: typeof isCurrentTarget !== "undefined" ? isCurrentTarget : true
    property string iconFont: "Font Awesome 6 Free Solid" 
    property string safeActiveEdge: typeof activeEdge !== "undefined" ? activeEdge : "left"

    function s(val) { return typeof scaleFunc === "function" ? scaleFunc(val) : val; }

    property real baseW: s(400) 
    property real baseL: s(340)

    property real preferredWidth: safeActiveEdge === "bottom" ? baseL + 50 : baseW
    property real preferredExtraLength: safeActiveEdge === "bottom" ? baseW : baseL

    property real counterRotation: {
        if (safeActiveEdge === "right") return 180;
        if (safeActiveEdge === "bottom") return 90;
        return 0; 
    }

    property color cBase: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.base : "#1e1e2e"
    property color cMantle: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mantle : "#181825"
    property color cSurface0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface0 : "#313244"
    property color cSurface1: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface1 : "#45475a"
    property color cText: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.text : "#cdd6f4"
    property color cSubtext0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.subtext0 : "#a6adc8"
    property color cYellow: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.yellow : "#f9e2af"
    property color cMauve: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mauve : "#cba6f7"

    // Intercept keyboard shortcuts if typing
    property var interceptedShortcuts: {
        if (noteInput.activeFocus) {
            return ["Return", "Enter", "Left", "Right", "Up", "Down"];
        }
        return [];
    }

    Item {
        id: orientedRoot
        anchors.centerIn: parent
        width: (root.counterRotation % 180 !== 0) ? parent.height : parent.width
        height: (root.counterRotation % 180 !== 0) ? parent.width : parent.height
        rotation: root.counterRotation
        clip: true

        Rectangle { anchors.fill: parent; color: root.cMantle; radius: root.s(10); z: -1 }

        // Header
        Rectangle {
            id: header
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: root.s(45)
            color: root.cSurface0
            radius: root.s(10)
            
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: root.s(10); color: root.cSurface0 }
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.cSurface1 }

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.s(10)
                anchors.leftMargin: root.s(15)
                anchors.rightMargin: root.s(15)
                spacing: root.s(10)

                Text { text: "\uF249"; font.family: root.iconFont; font.pixelSize: root.s(16); color: root.cYellow }
                Text { text: "Sticky Notes"; font.family: "Inter"; font.bold: true; font.pixelSize: root.s(14); color: root.cText; Layout.fillWidth: true }
                
                Text {
                    text: root.isSaving ? "Saving..." : (root.initialLoaded ? "Saved" : "Loading...")
                    font.family: "Inter"; font.pixelSize: root.s(11); color: root.cSubtext0
                }
            }
        }

        // Notes Area
        Flickable {
            id: flickable
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.s(15)
            contentWidth: width
            contentHeight: noteInput.paintedHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { 
                active: true
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: root.s(4); radius: root.s(2)
                    color: root.cSurface1
                }
            }

            TextArea {
                id: noteInput
                width: parent.width
                color: root.cText
                font.family: "Inter"
                font.pixelSize: root.s(14)
                wrapMode: Text.Wrap
                background: Item {} // Transparent
                selectionColor: root.cSurface1
                selectedTextColor: root.cYellow
                placeholderText: "Jot down some quick ideas here..."
                placeholderTextColor: root.cSubtext0
                
                onTextChanged: {
                    if (root.initialLoaded && !root.isSaving) {
                        saveTimer.restart()
                    }
                }
            }
        }
    }

    property bool initialLoaded: false
    property bool isSaving: false

    Process {
        id: fileReader
        command: ["bash", "-c", "touch ~/.cache/qs_notes.txt && cat ~/.cache/qs_notes.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text;
                if (txt.endsWith('\n')) txt = txt.substring(0, txt.length - 1);
                noteInput.text = txt;
                root.initialLoaded = true;
            }
        }
    }

    Process {
        id: fileWriter
        running: false
        onExited: root.isSaving = false
    }

    Timer {
        id: saveTimer
        interval: 1000
        repeat: false
        onTriggered: {
            root.isSaving = true;
            let tempFile = "/tmp/qs_notes_temp.txt"
            let content = noteInput.text.replace(/'/g, "'\\''"); // Escape single quotes
            let writeCmd = `echo '${content}' > ${tempFile} && mv ${tempFile} ~/.cache/qs_notes.txt`;
            fileWriter.command = ["bash", "-c", writeCmd];
            fileWriter.running = true;
        }
    }

    Component.onCompleted: fileReader.running = true
}
