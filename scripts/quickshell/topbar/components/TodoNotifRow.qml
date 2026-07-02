import QtQuick
import Quickshell

// Todo and Notification icon pills (simple icon-only pills)
Row {
    id: root

    required property var mocha
    required property bool showLayout
    required property var s

    spacing: s(8)

    // Todo pill
    Rectangle {
        property bool isHovered: todoMouse.containsMouse
        color: isHovered
            ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6)
            : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
        radius: s(10); height: s(34); clip: true
        Behavior on color { ColorAnimation { duration: 200 } }

        width: todoRow.implicitWidth + s(24)
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

        scale: isHovered ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        property bool _init: false
        Timer { running: root.showLayout && !parent._init; interval: 25; onTriggered: parent._init = true }
        opacity: _init ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: parent._init ? 0 : s(15)
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
        }

        Row {
            id: todoRow
            anchors.centerIn: parent
            spacing: s(8)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                font.family: "Iosevka Nerd Font"; font.pixelSize: s(16)
                color: Qt.tint(mocha.green, Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4))
            }
        }
        MouseArea {
            id: todoMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle todo"])
        }
    }

    // Notification pill
    Rectangle {
        property bool isHovered: notifMouse.containsMouse
        color: isHovered
            ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6)
            : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
        radius: s(10); height: s(34); clip: true
        Behavior on color { ColorAnimation { duration: 200 } }

        width: notifRow.implicitWidth + s(24)
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

        scale: isHovered ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        property bool _init: false
        Timer { running: root.showLayout && !parent._init; interval: 25; onTriggered: parent._init = true }
        opacity: _init ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: parent._init ? 0 : s(15)
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
        }

        Row {
            id: notifRow
            anchors.centerIn: parent
            spacing: s(8)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                font.family: "Iosevka Nerd Font"; font.pixelSize: s(16)
                color: Qt.tint(mocha.yellow, Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4))
            }
        }
        MouseArea {
            id: notifMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle notifications"])
        }
    }
}
