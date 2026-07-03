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
    property real baseL: s(380)

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
    property color cMauve: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mauve : "#cba6f7"
    property color cBlue: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.blue : "#89b4fa"

    ListModel { id: clipModel }

    Process {
        id: clipFetcher
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", "0", "15", Quickshell.env("HOME") + "/.cache/quickshell/clipboard"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let items = JSON.parse(this.text);
                    clipModel.clear();
                    for (let i = 0; i < items.length; i++) {
                        clipModel.append(items[i]);
                    }
                } catch(e) {}
            }
        }
    }
    
    // Refresh when tab becomes active
    onIsActiveTabChanged: {
        if (isActiveTab) clipFetcher.running = true;
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

                Text { text: "\uF0EA"; font.family: root.iconFont; font.pixelSize: root.s(16); color: root.cBlue }
                Text { text: "Clipboard"; font.family: "Inter"; font.bold: true; font.pixelSize: root.s(14); color: root.cText; Layout.fillWidth: true }
                
                Text {
                    text: "\uF2F1"
                    font.family: root.iconFont
                    font.pixelSize: root.s(14)
                    color: maRefresh.containsMouse ? root.cMauve : root.cSubtext0
                    MouseArea {
                        id: maRefresh; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: clipFetcher.running = true
                    }
                }
            }
        }

        ListView {
            id: listView
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.s(15)
            clip: true
            model: clipModel
            spacing: root.s(8)
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { 
                active: true
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: root.s(4); radius: root.s(2)
                    color: root.cSurface1
                }
            }
            
            delegate: Rectangle {
                width: listView.width
                height: root.s(60)
                color: ma.containsMouse ? root.cSurface0 : "transparent"
                radius: root.s(8)
                border.width: 1
                border.color: ma.containsMouse ? root.cSurface1 : "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.s(10)
                    spacing: root.s(12)
                    
                    Rectangle {
                        width: root.s(32); height: root.s(32); radius: root.s(6)
                        color: root.cSurface1
                        Text { 
                            anchors.centerIn: parent
                            text: model.type === "image" ? "\uF03E" : "\uF036"
                            font.family: root.iconFont; font.pixelSize: root.s(14); color: root.cText 
                        }
                    }
                    
                    Text {
                        text: model.type === "image" ? "[Image Data]" : model.content.replace(/\n/g, " ")
                        font.family: "Inter"
                        font.pixelSize: root.s(13)
                        color: root.cText
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }
                }
                
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", "cliphist decode " + model.id + " | wl-copy && notify-send -a Quickshell -i edit-copy 'Copied to Clipboard' 'Item has been copied'"]);
                    }
                }
            }
        }
    }
}
