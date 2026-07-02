import QtQuick
import Quickshell

// Keyboard layout pill — click to switch to next layout
Rectangle {
    id: root

    required property var mocha
    required property string kbLayout
    required property bool showLayout
    required property var s

    property bool isHovered: kbMouse.containsMouse

    color: isHovered
        ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6)
        : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
    radius: s(10)
    height: s(34)
    clip: true

    property real targetWidth: kbRow.implicitWidth + s(24)
    width: targetWidth
    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
    Behavior on color { ColorAnimation { duration: 200 } }

    property bool _init: false
    Timer { running: root.showLayout && !root._init; interval: 0; onTriggered: root._init = true }
    opacity: _init ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    transform: Translate {
        y: root._init ? 0 : s(15)
        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
    }

    Row {
        id: kbRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: s(12)
        spacing: s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰌌"
            font.family: "Iosevka Nerd Font"; font.pixelSize: s(16)
            color: root.isHovered ? mocha.text : mocha.overlay2
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.kbLayout
            font.family: "JetBrains Mono"; font.pixelSize: s(13); font.weight: Font.Black
            color: mocha.text
        }
    }

    MouseArea {
        id: kbMouse; anchors.fill: parent; hoverEnabled: true
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"])
    }
}
