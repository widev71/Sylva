import QtQuick
import QtQuick.Effects
import Quickshell

// Media player box: album art, title, time, and playback controls
Rectangle {
    id: root

    required property var mocha
    required property var musicData
    required property string displayTitle
    required property string displayTime
    required property string displayArtUrl
    required property bool isMediaActive
    required property var s

    // Called by control buttons to trigger a music refresh after playerctl commands
    signal refreshMusic

    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.40)
    radius: s(14)
    border.width: 1
    border.color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.5)
    height: s(48)
    clip: true

    width: isMediaActive ? innerRow.implicitWidth + s(24) : 0
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    visible: width > 0 || opacity > 0
    opacity: isMediaActive ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true; shadowColor: mocha.mauve
        shadowBlur: 1.0; shadowHorizontalOffset: 0; shadowVerticalOffset: 0
    }

    Item {
        id: mediaContainer
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: s(12)
        height: parent.height
        width: innerRow.implicitWidth

        opacity: isMediaActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        transform: Translate {
            x: isMediaActive ? 0 : s(-20)
            Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
        }

        Row {
            id: innerRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: s(16)

            // Album art + title/time info
            MouseArea {
                id: mediaInfoMouse
                width: infoRow.width; height: innerRow.height
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"])

                Row {
                    id: infoRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: s(10)
                    scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                    // Album art thumbnail
                    Rectangle {
                        width: s(32); height: s(32); radius: s(8); color: mocha.surface1
                        border.width: root.musicData.status === "Playing" ? 1 : 0
                        border.color: mocha.mauve
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: root.displayArtUrl || ""
                            fillMode: Image.PreserveAspectCrop
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.2)
                        }
                    }

                    // Title and position
                    Column {
                        spacing: -2
                        anchors.verticalCenter: parent.verticalCenter
                        width: s(180)
                        Text {
                            text: root.displayTitle
                            font.family: "JetBrains Mono"; font.weight: Font.Black
                            font.pixelSize: s(13); color: mocha.text
                            width: parent.width; elide: Text.ElideRight
                        }
                        Text {
                            text: root.displayTime
                            font.family: "JetBrains Mono"; font.weight: Font.Black
                            font.pixelSize: s(10); color: mocha.subtext0
                            width: parent.width; elide: Text.ElideRight
                        }
                    }
                }
            }

            // Playback controls
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: s(8)

                // Previous
                Item {
                    width: s(24); height: s(24); anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent; text: "󰒮"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: s(26)
                        color: prevMouse.containsMouse ? mocha.text : mocha.overlay2
                        scale: prevMouse.containsMouse ? 1.1 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    }
                    MouseArea {
                        id: prevMouse; hoverEnabled: true; anchors.fill: parent
                        onClicked: { Quickshell.execDetached(["playerctl", "previous"]); root.refreshMusic() }
                    }
                }

                // Play/Pause
                Item {
                    width: s(28); height: s(28); anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: root.musicData.status === "Playing" ? "󰏤" : "󰐊"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: s(30)
                        color: playMouse.containsMouse ? mocha.green : mocha.text
                        scale: playMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    }
                    MouseArea {
                        id: playMouse; hoverEnabled: true; anchors.fill: parent
                        onClicked: { Quickshell.execDetached(["playerctl", "play-pause"]); root.refreshMusic() }
                    }
                }

                // Next
                Item {
                    width: s(24); height: s(24); anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent; text: "󰒭"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: s(26)
                        color: nextMouse.containsMouse ? mocha.text : mocha.overlay2
                        scale: nextMouse.containsMouse ? 1.1 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    }
                    MouseArea {
                        id: nextMouse; hoverEnabled: true; anchors.fill: parent
                        onClicked: { Quickshell.execDetached(["playerctl", "next"]); root.refreshMusic() }
                    }
                }
            }
        }
    }
}
