import QtQuick
import QtQuick.Layouts
import Quickshell

// Center clock/date + weather widget — clicks open calendar popup
Rectangle {
    id: root

    required property var mocha
    required property string timeStr
    required property string dateStr
    required property string weatherIcon
    required property string weatherTemp
    required property string weatherHex
    required property bool startupReady
    required property var s

    property bool isHovered: centerMouse.containsMouse

    color: isHovered
        ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6)
        : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.40)
    radius: s(14)
    border.width: 1
    border.color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, isHovered ? 0.8 : 0.5)
    height: s(48)
    width: centerRow.implicitWidth + s(36)
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on color { ColorAnimation { duration: 250 } }

    scale: isHovered ? 1.03 : 1.0
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

    // Slide-down entry
    property bool _showLayout: false
    opacity: _showLayout ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    transform: Translate {
        y: root._showLayout ? 0 : s(-30)
        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    }
    Timer { running: root.startupReady; interval: 150; onTriggered: root._showLayout = true }

    MouseArea {
        id: centerMouse; anchors.fill: parent; hoverEnabled: true
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])
    }

    RowLayout {
        id: centerRow
        anchors.centerIn: parent
        spacing: s(20)

        // Date and time
        ColumnLayout {
            spacing: -2
            Text {
                text: root.dateStr
                Layout.alignment: Qt.AlignHCenter
                font.family: "JetBrains Mono"; font.pixelSize: s(11); font.weight: Font.Bold
                color: mocha.subtext0
            }
            Text {
                text: root.timeStr
                Layout.alignment: Qt.AlignHCenter
                font.family: "JetBrains Mono"; font.pixelSize: s(16); font.weight: Font.Black
                color: mocha.blue
            }
        }

        // Divider
        Rectangle {
            width: 1; height: s(24)
            color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.2)
        }

        // Weather
        RowLayout {
            spacing: s(8)
            Text {
                text: root.weatherIcon
                font.family: "Iosevka Nerd Font"; font.pixelSize: s(18)
                color: root.weatherHex
            }
            Text {
                text: root.weatherTemp
                font.family: "JetBrains Mono"; font.pixelSize: s(14); font.weight: Font.Bold
                color: mocha.text
            }
        }
    }
}
