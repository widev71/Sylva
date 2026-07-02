import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

Item {
    id: root

    required property real sc
    required property var d
    
    // Music properties
    required property string musicTitle
    required property string musicArtist
    required property string musicArtPath
    required property bool musicPlaying
    required property bool musicActive
    required property real musicProgress
    required property string musicPositionStr
    required property string musicLengthStr
    
    signal playPauseClicked()
    signal nextClicked()
    signal prevClicked()
    signal seekRequested(real percent)

    // Auth properties moved to Lock.qml

    // System info
    required property string batPct
    required property string batStatus

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item { Layout.fillHeight: true } // Top spacer pushes content to middle

        // ---------------- MEDIA SECTION ----------------
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 360 * root.sc
            spacing: 24 * root.sc

            // Album Art
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: parent.width
                radius: 18 * root.sc
                color: root.d.cPanel
                border.color: root.d.cPanelBorder
                border.width: 2 * root.sc
                clip: true

                Image {
                    id: albumArt
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: root.musicArtPath !== "" ? root.musicArtPath : ""
                    visible: root.musicArtPath !== ""
                    asynchronous: true
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: maskRect
                    }
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 18 * root.sc
                    color: "black"
                    visible: false
                    layer.enabled: true
                }
                
                // Border Overlay to ensure image doesn't cover the border
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.d.cPanelBorder
                    border.width: 2 * root.sc
                    radius: 18 * root.sc
                }
                
                // Fallback icon if no art
                Text {
                    anchors.centerIn: parent
                    text: "󰝚"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 64 * root.sc
                    color: root.d.cTextDim
                    visible: root.musicArtPath === ""
                }
            }

            // Track Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * root.sc
                Text {
                    text: root.musicActive ? root.musicTitle : "No Media Playing"
                    color: root.d.cText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 18 * root.sc
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.musicActive ? root.musicArtist : "Unknown Artist"
                    color: root.d.cTextDim
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14 * root.sc
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Progress Bar (Interactive)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8 * root.sc
                spacing: 4 * root.sc

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16 * root.sc

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4 * root.sc
                        color: root.d.cTextFaint
                        radius: 2 * root.sc
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * Math.max(0, Math.min(1, root.musicProgress))
                        height: 4 * root.sc
                        color: root.d.cLime
                        radius: 2 * root.sc
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, (parent.width * root.musicProgress) - (width / 2)))
                        width: 12 * root.sc
                        height: 12 * root.sc
                        radius: 6 * root.sc
                        color: root.d.cLime
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                let pct = Math.max(0, Math.min(1, mouse.x / width));
                                root.musicProgress = pct;
                            }
                        }
                        onReleased: function(mouse) {
                            let pct = Math.max(0, Math.min(1, mouse.x / width));
                            root.seekRequested(pct);
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.musicPositionStr
                        color: root.d.cTextDim
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12 * root.sc
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.musicLengthStr
                        color: root.d.cTextDim
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12 * root.sc
                    }
                }
            }

            // Playback Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4 * root.sc

                Item { Layout.fillWidth: true }
                
                // Prev
                MouseArea {
                    Layout.preferredWidth: 48 * root.sc
                    Layout.preferredHeight: 48 * root.sc
                    onClicked: root.prevClicked()
                    Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: 24 * root.sc; color: parent.pressed ? root.d.cText : root.d.cTextDim }
                }

                // Play/Pause
                MouseArea {
                    Layout.preferredWidth: 64 * root.sc
                    Layout.preferredHeight: 64 * root.sc
                    onClicked: root.playPauseClicked()
                    Text {
                        anchors.centerIn: parent
                        text: root.musicPlaying ? "󰏤" : "󰐊"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 42 * root.sc
                        color: parent.pressed ? root.d.cText : root.d.cLime
                        scale: parent.pressed ? 0.8 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    }
                }

                // Next
                MouseArea {
                    Layout.preferredWidth: 48 * root.sc
                    Layout.preferredHeight: 48 * root.sc
                    onClicked: root.nextClicked()
                    Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: 24 * root.sc; color: parent.pressed ? root.d.cText : root.d.cTextDim }
                }

                Item { Layout.fillWidth: true }
            }
        }

        Item { Layout.fillHeight: true } // Bottom spacer

        // Bottom row removed and moved to Lock.qml
    }
}
