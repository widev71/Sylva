import QtQuick
import Quickshell

// Blinking recording indicator button — visible only while recording
Rectangle {
    id: root

    required property var mocha
    required property bool isRecording
    required property var s

    property bool isHovered: recMouse.containsMouse

    color: isHovered
        ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95)
        : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
    radius: s(14)
    border.width: 1
    border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
    height: s(48)
    clip: true

    property real targetWidth: isRecording ? height : 0
    width: targetWidth
    visible: targetWidth > 0 || opacity > 0
    opacity: isRecording ? 1.0 : 0.0

    Behavior on width   { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on opacity { NumberAnimation { duration: 300 } }
    Behavior on color   { ColorAnimation  { duration: 200 } }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    Text {
        anchors.centerIn: parent
        text: ""
        font.family: "Iosevka Nerd Font"; font.pixelSize: s(20)
        color: mocha.red

        SequentialAnimation on opacity {
            running: root.isRecording && !root.isHovered; loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on scale {
            running: root.isRecording && !root.isHovered; loops: Animation.Infinite
            NumberAnimation { to: 1.15; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 600; easing.type: Easing.InOutSine }
        }
    }

    MouseArea {
        id: recMouse; anchors.fill: parent; hoverEnabled: true
        onClicked: {
            root.isRecording = false;
            Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/screenshot.sh"]);
        }
    }
}
