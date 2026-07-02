import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

Item {
    id: root

    required property real sc
    required property var d
    
    required property string weatherIcon
    required property string weatherDesc
    required property string weatherTemp
    required property var lyricsList
    required property int currentLyricIndex

    // Local state for the clock
    property string ampm: "AM"
    property string hoursStr: "10"
    property string minutesStr: "00"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let d = new Date();
            let hh = d.getHours();
            let mm = d.getMinutes();
            root.ampm = (hh >= 12) ? "PM" : "AM";
            
            // Format 12-hour clock
            hh = hh % 12;
            if (hh === 0) hh = 12;
            
            root.hoursStr = hh.toString();
            root.minutesStr = mm < 10 ? "0" + mm : mm;
        }
        triggeredOnStart: true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item { Layout.preferredHeight: 24 * root.sc } // Small top padding — clock at top

        // ---------------- CLOCK & WEATHER ----------------
        ColumnLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: 12 * root.sc

            // Clock Row
            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 16 * root.sc

                Text {
                    text: root.hoursStr + ":" + root.minutesStr
                    color: root.d.cText
                    font.pixelSize: 96 * root.sc
                    font.weight: Font.Light
                    font.family: "JetBrains Mono"
                }

                // Vertical Divider
                Rectangle {
                    Layout.preferredWidth: 2 * root.sc
                    Layout.preferredHeight: 80 * root.sc
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.3)
                    radius: 1 * root.sc
                }

                // AM / PM Stack
                ColumnLayout {
                    spacing: 4 * root.sc
                    Text {
                        text: "AM"
                        font.pixelSize: 32 * root.sc
                        font.weight: Font.Normal
                        font.family: "JetBrains Mono"
                        color: root.ampm === "AM" ? root.d.cText : "transparent"
                        style: root.ampm === "AM" ? Text.Normal : Text.Outline
                        styleColor: root.d.cText
                    }
                    Text {
                        text: "PM"
                        font.pixelSize: 32 * root.sc
                        font.weight: Font.Normal
                        font.family: "JetBrains Mono"
                        color: root.ampm === "PM" ? root.d.cText : "transparent"
                        style: root.ampm === "PM" ? Text.Normal : Text.Outline
                        styleColor: root.d.cText
                    }
                }
            }

            // Weather Row
            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 32 * root.sc
                
                // Weather Icon + Temp
                RowLayout {
                    spacing: 8 * root.sc
                    Text { text: root.weatherIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 22 * root.sc; color: root.d.cTextDim }
                    Text {
                        text: root.weatherTemp
                        color: root.d.cText
                        font.pixelSize: 20 * root.sc
                        font.family: "JetBrains Mono"
                    }
                }
                
                // Weather Details
                ColumnLayout {
                    spacing: 4 * root.sc
                    Text {
                        text: root.weatherDesc !== "" ? root.weatherDesc : "Weather unavailable"
                        color: root.d.cText
                        font.pixelSize: 14 * root.sc
                        font.family: "JetBrains Mono"
                    }
                    Text {
                        text: "H: 30° L:23°" // Static placeholder as per mockup
                        color: root.d.cText
                        font.pixelSize: 14 * root.sc
                        font.family: "JetBrains Mono"
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer — pushes lyrics to vertical center

        // ---------------- LYRICS ----------------
        ListView {
            id: lyricsView
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width * 0.95
            Layout.preferredHeight: 400 * root.sc
            
            model: root.lyricsList
            currentIndex: root.currentLyricIndex >= 0 ? root.currentLyricIndex : 0
            
            clip: true
            spacing: 16 * root.sc
            
            // Center the active lyric in the ListView
            preferredHighlightBegin: height / 2 - 80 * root.sc
            preferredHighlightEnd: height / 2 + 80 * root.sc
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 400

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0.0; duration: 400; easing.type: Easing.OutQuart }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0.0; duration: 400; easing.type: Easing.OutQuart }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: 400; easing.type: Easing.OutQuart }
            }
            
            delegate: Text {
                id: lyricText
                width: ListView.view.width
                text: modelData.text || "♪"
                color: root.d.cText
                font.pixelSize: (index === ListView.view.currentIndex) ? 48 * root.sc : 28 * root.sc
                font.weight: Font.Light
                font.family: "JetBrains Mono"
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                opacity: (index === ListView.view.currentIndex) ? 1.0 : 0.35

                // Cinematic Focus & Blur effect
                property real blurAmount: (index === ListView.view.currentIndex) ? 0.0 : 1.0
                layer.enabled: blurAmount > 0
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 10 * root.sc
                    blur: lyricText.blurAmount
                }
                
                // Spring/Bounce easing for font size, smooth fading for opacity and blur
                Behavior on font.pixelSize { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
                Behavior on blurAmount { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            }
            
            onCountChanged: {
                if (count > 0 && currentIndex >= 0) {
                    positionViewAtIndex(currentIndex, ListView.Center)
                }
            }
            onCurrentIndexChanged: {
                if (count > 0 && currentIndex >= 0) {
                    positionViewAtIndex(currentIndex, ListView.Center)
                }
            }
        }

        Item { Layout.fillHeight: true } // Bottom spacer — balances lyrics to center
    }
}
