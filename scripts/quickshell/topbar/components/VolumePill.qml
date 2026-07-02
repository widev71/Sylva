import QtQuick
import Quickshell

// Volume pill — peach gradient when sound is active
Rectangle {
    id: root

    required property var mocha
    required property string volIcon
    required property string volPercent
    required property bool isSoundActive
    required property bool showLayout
    required property int  initDelay
    required property var s

    property bool isHovered: volMouse.containsMouse

    color: isHovered
        ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6)
        : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
    radius: s(10); height: s(34); clip: true
    Behavior on color { ColorAnimation { duration: 200 } }

    // Active gradient fill
    Rectangle {
        anchors.fill: parent; radius: s(10)
        opacity: root.isSoundActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: mocha.peach }
            GradientStop { position: 1.0; color: Qt.lighter(mocha.peach, 1.3) }
        }
    }

    property real targetWidth: volRow.implicitWidth + s(24)
    width: targetWidth
    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    property bool _init: false
    Timer { running: root.showLayout && !root._init; interval: root.initDelay; onTriggered: root._init = true }
    opacity: _init ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    transform: Translate {
        y: root._init ? 0 : s(15)
        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
    }

    Row {
        id: volRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: s(12)
        spacing: s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.volIcon
            font.family: "Iosevka Nerd Font"; font.pixelSize: s(16)
            color: root.isSoundActive ? mocha.base : mocha.subtext0
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.volPercent
            font.family: "JetBrains Mono"; font.pixelSize: s(13); font.weight: Font.Black
            color: root.isSoundActive ? mocha.base : mocha.text
        }
    }

    MouseArea {
        id: volMouse; anchors.fill: parent; hoverEnabled: true
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle volume"])
    }
}
