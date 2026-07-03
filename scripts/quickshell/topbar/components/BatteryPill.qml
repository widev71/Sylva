import QtQuick
import Quickshell

// Battery pill — dynamic color gradient (green/red/text), desktop shows power icon only
Rectangle {
    id: root

    required property var mocha
    required property string batIcon
    required property string batPercent
    required property bool isDesktop
    required property color batDynamicColor
    required property bool showLayout
    required property int  initDelay
    required property var s

    property bool isHovered: batMouse.containsMouse
    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

    color: isHovered
        ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6)
        : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
    radius: s(10); height: s(34); clip: true
    Behavior on color { ColorAnimation { duration: 200 } }

    // Dynamic gradient fill
    Rectangle {
        anchors.fill: parent; radius: s(10)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: root.isDesktop ? mocha.red : root.batDynamicColor
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            GradientStop {
                position: 1.0
                color: root.isDesktop ? Qt.lighter(mocha.red, 1.3) : Qt.lighter(root.batDynamicColor, 1.3)
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }

    property real targetWidth: root.isDesktop ? s(34) : (batRow.implicitWidth + s(24))
    width: targetWidth
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
        id: batRow
        anchors.centerIn: parent
        spacing: s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isDesktop ? "" : root.batIcon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: root.isDesktop ? s(18) : s(16)
            color: mocha.base
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.isDesktop
            text: root.batPercent
            font.family: "Inter"; font.pixelSize: s(13); font.weight: Font.Black
            color: mocha.base
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    MouseArea {
        id: batMouse; anchors.fill: parent; hoverEnabled: true
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"])
    }
}
