import QtQuick
import Quickshell

// Bluetooth pill — hidden on desktop, mauve gradient when connected
Rectangle {
    id: root

    required property var mocha
    required property string btIcon
    required property string btDevice
    required property bool isBtOn
    required property bool isDesktop
    required property bool showLayout
    required property int  initDelay
    required property var s

    property bool isHovered: btMouse.containsMouse
    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

    color: isHovered
        ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6)
        : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
    radius: s(10); height: s(34); clip: true
    Behavior on color { ColorAnimation { duration: 200 } }

    // BT-on gradient fill
    Rectangle {
        anchors.fill: parent; radius: s(10)
        opacity: root.isBtOn ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: mocha.mauve }
            GradientStop { position: 1.0; color: Qt.lighter(mocha.mauve, 1.3) }
        }
    }

    property real targetWidth: root.isDesktop ? 0 : (btRow.implicitWidth + s(24))
    width: targetWidth
    visible: targetWidth > 0
    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }


    property bool _init: false
    Timer { running: root.showLayout && !root._init; interval: root.initDelay; onTriggered: root._init = true }
    opacity: _init ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    transform: Translate {
        y: root._init ? 0 : s(15)
        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
    }

    Row {
        id: btRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: s(12)
        spacing: s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.btIcon
            font.family: "Iosevka Nerd Font"; font.pixelSize: s(16)
            color: root.isBtOn ? mocha.base : mocha.subtext0
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.btDevice
            visible: text !== ""
            font.family: "Inter"; font.pixelSize: s(13); font.weight: Font.Black
            color: root.isBtOn ? mocha.base : mocha.text
            width: Math.min(implicitWidth, s(100)); elide: Text.ElideRight
        }
    }

    MouseArea {
        id: btMouse; anchors.fill: parent; hoverEnabled: true
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bt"])
    }
}
