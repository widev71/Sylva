import QtQuick
import Quickshell
import "../../"

// Left panel: Help, Search, Settings, and Update notification buttons
Rectangle {
    id: root

    required property var mocha
    required property bool showHelpIcon
    required property bool isUpdateVisible
    required property bool isSettingsOpen
    required property bool startupReady
    required property var s   // scale function

    property int pillHeight: s(34)

    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.40)
    radius: s(14)
    border.width: width > 0 ? 1 : 0
    border.color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.5)
    clip: true

    height: s(48)
    width: innerRow.width > 0 ? innerRow.width + s(16) : 0

    property bool _showLayout: false
    property real targetX: (_showLayout && !isSettingsOpen) ? 0 : s(-200)

    x: targetX
    Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }

    opacity: (_showLayout && !isSettingsOpen && width > 0) ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    enabled: !isSettingsOpen

    Timer {
        running: root.startupReady
        interval: 10
        onTriggered: root._showLayout = true
    }

    Row {
        id: innerRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: s(8)
        spacing: s(4)

        // Help button
        Rectangle {
            property bool isHovered: helpMouse.containsMouse
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
            radius: s(10)
            property real targetWidth: (root.showHelpIcon && Config.showTopHelp) ? s(34) : 0
            width: targetWidth
            height: pillHeight
            visible: targetWidth > 0 || opacity > 0
            opacity: (root.showHelpIcon && Config.showTopHelp) ? 1.0 : 0.0
            clip: true
            Behavior on width   { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on color   { ColorAnimation  { duration: 200 } }
            Text {
                anchors.centerIn: parent; text: "󰋗"
                font.family: "Iosevka Nerd Font"; font.pixelSize: s(22)
                color: parent.isHovered ? mocha.teal : mocha.text
                scale: parent.isHovered ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }
            MouseArea {
                id: helpMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
            }
        }

                // Search / App launcher button
        Rectangle {
            property bool isHovered: searchMouse.containsMouse
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
            radius: s(10); height: pillHeight;
            
            property real targetWidth: Config.showTopSearch ? s(34) : 0
            width: targetWidth
            visible: targetWidth > 0 || opacity > 0
            opacity: Config.showTopSearch ? 1.0 : 0.0
            clip: true
            
            Behavior on width   { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent; text: "󰍉"
                font.family: "Iosevka Nerd Font"; font.pixelSize: s(22)
                color: parent.isHovered ? mocha.blue : mocha.text
                scale: parent.isHovered ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }
            MouseArea {
                id: searchMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle applauncher"])
            }
        }

                // Settings button
        Rectangle {
            property bool isHovered: settingsMouse.containsMouse
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
            radius: s(10); height: pillHeight;
            
            property real targetWidth: Config.showTopSettings ? s(34) : 0
            width: targetWidth
            visible: targetWidth > 0 || opacity > 0
            opacity: Config.showTopSettings ? 1.0 : 0.0
            clip: true
            
            Behavior on width   { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent; text: ""
                font.family: "Iosevka Nerd Font"; font.pixelSize: s(22)
                color: parent.isHovered ? mocha.blue : mocha.text
                scale: parent.isHovered ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }
            MouseArea {
                id: settingsMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle settings"])
            }
        }

        // Update available badge
        Rectangle {
            id: updateButton
            property bool isHovered: updateMouse.containsMouse
            color: isHovered ? Qt.rgba(mocha.green.r, mocha.green.g, mocha.green.b, 0.15) : "transparent"
            radius: s(10)
            width: root.isUpdateVisible ? s(34) : 0
            height: pillHeight
            visible: width > 0 || opacity > 0
            opacity: root.isUpdateVisible ? 1.0 : 0.0
            clip: false
            Behavior on width   { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on color   { ColorAnimation  { duration: 200 } }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width; height: parent.height; radius: parent.radius
                color: mocha.green; z: -1
                SequentialAnimation on scale {
                    running: root.isUpdateVisible && !updateButton.isHovered; loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.3; duration: 2000; easing.type: Easing.OutCubic }
                }
                SequentialAnimation on opacity {
                    running: root.isUpdateVisible && !updateButton.isHovered; loops: Animation.Infinite
                    NumberAnimation { from: 0.15; to: 0.0; duration: 2000; easing.type: Easing.OutCubic }
                }
            }
            Text {
                anchors.centerIn: parent; text: "󰚰"
                font.family: "Iosevka Nerd Font"; font.pixelSize: s(22)
                color: parent.isHovered ? mocha.text : mocha.green
                rotation: parent.isHovered ? 360 : 0
                scale: parent.isHovered ? 1.15 : 1.0
                Behavior on color    { ColorAnimation  { duration: 200 } }
                Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                Behavior on scale    { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }
            MouseArea {
                id: updateMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle updater"])
                }
            }
        }
    }
}
