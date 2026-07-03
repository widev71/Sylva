import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

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

    width: isMediaActive ? contentContainer.width + s(24) : 0
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    visible: width > 0 || opacity > 0
    opacity: isMediaActive ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400 } }



    // --- Hover Detection ---
    HoverHandler {
        id: hoverHandler
    }
    property bool isHovered: hoverHandler.hovered

    // --- Lyrics Polling ---
    property var lyrics: []
    property int activeLyricIndex: -1
    property string currentLyricText: ""

    Process {
        id: indexPoller
        command: ["cat", "/tmp/current_lyric_index.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    let idx = parseInt(txt);
                    if (!isNaN(idx) && idx !== activeLyricIndex) activeLyricIndex = idx;
                }
            }
        }
    }
    Timer { interval: 350; running: root.isMediaActive; repeat: true; onTriggered: indexPoller.running = true }

    Process {
        id: lyricsPoller
        command: ["cat", "/tmp/lyrics_data.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && txt.length > 2) {
                    try {
                        let parsed = JSON.parse(txt);
                        if (Array.isArray(parsed)) root.lyrics = parsed;
                    } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 5000; running: root.isMediaActive; repeat: true; triggeredOnStart: true; onTriggered: lyricsPoller.running = true }

    onActiveLyricIndexChanged: {
        if (activeLyricIndex >= 0 && activeLyricIndex < lyrics.length) {
            currentLyricText = lyrics[activeLyricIndex].text || "♪";
        } else {
            currentLyricText = "";
        }
    }
    onLyricsChanged: {
        if (activeLyricIndex >= 0 && activeLyricIndex < lyrics.length) {
            currentLyricText = lyrics[activeLyricIndex].text || "♪";
        } else {
            currentLyricText = "";
        }
    }

    Item {
        id: contentContainer
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: s(12)
        height: parent.height
        width: contentRow.width

        opacity: isMediaActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        transform: Translate {
            x: isMediaActive ? 0 : s(-20)
            Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
        }

        Row {
            id: contentRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: s(10)

            // Album art thumbnail
            Rectangle {
                id: albumArt
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

            // The dynamic content area (Controls vs Lyrics)
            Item {
                id: dynamicArea
                height: parent.height
                
                property bool showLyrics: !root.isHovered && root.currentLyricText !== ""
                
                Text {
                    id: measureText
                    text: root.currentLyricText
                    font.family: "Inter"
                    font.pixelSize: s(13)
                    font.weight: Font.Bold
                    visible: false
                }
                
                width: showLyrics ? Math.min(measureText.implicitWidth, s(280)) : infoControlsRow.implicitWidth
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                // Lyrics mode
                Item {
                    anchors.fill: parent
                    opacity: dynamicArea.showLyrics ? 1.0 : 0.0
                    transform: Translate { y: dynamicArea.showLyrics ? 0 : s(15) }
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on transform { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    clip: true
                    
                    ListView {
                        id: lyricsList
                        anchors.fill: parent
                        model: root.lyrics
                        currentIndex: root.activeLyricIndex >= 0 ? root.activeLyricIndex : 0
                        
                        interactive: false // Disable manual scrolling
                        
                        preferredHighlightBegin: 0
                        preferredHighlightEnd: 0
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        highlightMoveDuration: 250
                        
                        delegate: Item {
                            width: ListView.view.width
                            height: ListView.view.height
                            
                            Text {
                                id: lyricsText
                                text: modelData.text || "♪"
                                color: mocha.text
                                font.family: "Inter"
                                font.pixelSize: s(13)
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                                
                                opacity: index === ListView.view.currentIndex ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                
                                // Marquee scrolling if text is too long (only for active item)
                                x: (index === ListView.view.currentIndex && implicitWidth > lyricsList.width) ? -(implicitWidth - lyricsList.width) : 0
                                Behavior on x { 
                                    NumberAnimation { 
                                        duration: lyricsText.implicitWidth > lyricsList.width ? 3000 : 0
                                        easing.type: Easing.InOutSine 
                                    } 
                                }
                            }
                        }
                    }
                }

                // Controls mode
                Row {
                    id: infoControlsRow
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: !dynamicArea.showLyrics ? 1.0 : 0.0
                    transform: Translate { y: !dynamicArea.showLyrics ? 0 : s(-15) }
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on transform { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    spacing: s(16)

                    // Title and position
                    Column {
                        id: infoCol
                        spacing: -2
                        anchors.verticalCenter: parent.verticalCenter
                        width: s(180)
                        Text {
                            text: root.displayTitle
                            font.family: "Inter"; font.weight: Font.Black
                            font.pixelSize: s(13); color: mocha.text
                            width: parent.width; elide: Text.ElideRight
                        }
                        Text {
                            text: root.displayTime
                            font.family: "Inter"; font.weight: Font.Black
                            font.pixelSize: s(10); color: mocha.subtext0
                            width: parent.width; elide: Text.ElideRight
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
                                onClicked: { Quickshell.execDetached(["playerctl", "previous"]); root.refreshMusic(); mouse.accepted = true; }
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
                                onClicked: { Quickshell.execDetached(["playerctl", "play-pause"]); root.refreshMusic(); mouse.accepted = true; }
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
                                onClicked: { Quickshell.execDetached(["playerctl", "next"]); root.refreshMusic(); mouse.accepted = true; }
                            }
                        }
                    }
                }
            }
        }
        
        // MouseArea for opening music menu (only covers album art and text area, not controls)
        MouseArea {
            width: albumArt.width + s(10) + (dynamicArea.showLyrics ? dynamicArea.width : infoCol.width)
            height: parent.height
            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"])
        }
    }
}
