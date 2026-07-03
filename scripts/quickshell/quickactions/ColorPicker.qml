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
    property real baseL: s(150)

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
    property color cPeach: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.peach : "#fab387"

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

                Text { text: "\uF1FC"; font.family: root.iconFont; font.pixelSize: root.s(16); color: root.cPeach }
                Text { text: "Color Picker"; font.family: "Inter"; font.bold: true; font.pixelSize: root.s(14); color: root.cText; Layout.fillWidth: true }
            }
        }

        // Action Area
        Rectangle {
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.s(15)
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: root.s(8)
                color: ma.containsMouse ? root.cSurface0 : root.cBase
                border.width: 1
                border.color: root.cSurface1
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: root.s(10)
                    
                    Text { 
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uF1FB"
                        font.family: root.iconFont
                        font.pixelSize: root.s(32)
                        color: ma.containsMouse ? root.cMauve : root.cPeach
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Click to pick a color"
                        font.family: "Inter"
                        font.pixelSize: root.s(13)
                        color: root.cText
                    }
                }
                
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/color_picker.sh"]);
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                    }
                }
            }
        }
    }
}
