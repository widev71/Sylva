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
    property string weatherHigh: "--°C"
    property string weatherLow: "--°C"
    property color weatherHex: "#cdd6f4"
    required property var lyricsList
    required property int currentLyricIndex
    property real musicProgress: 0.0

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
                    id: clockText
                    text: root.hoursStr + ":" + root.minutesStr
                    color: root.d.cText
                    font.pixelSize: 96 * root.sc
                    font.weight: Font.Light
                    font.family: "Inter"
                    // For smooth number transition, we can animate opacity.
                    SequentialAnimation on opacity {
                        id: clockAnim
                        running: false
                        NumberAnimation { to: 0.5; duration: 150 }
                        NumberAnimation { to: 1.0; duration: 150 }
                    }
                    onTextChanged: clockAnim.restart()
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
                        font.family: "Inter"
                        color: root.ampm === "AM" ? root.d.cText : "transparent"
                        style: root.ampm === "AM" ? Text.Normal : Text.Outline
                        styleColor: root.d.cText
                    }
                    Text {
                        text: "PM"
                        font.pixelSize: 32 * root.sc
                        font.weight: Font.Normal
                        font.family: "Inter"
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
                    Text { text: root.weatherIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 22 * root.sc; color: root.weatherHex }
                    Text {
                        text: root.weatherTemp
                        color: root.d.cText
                        font.pixelSize: 20 * root.sc
                        font.family: "Inter"
                    }
                }
                
                // Weather Details
                ColumnLayout {
                    spacing: 4 * root.sc
                    Text {
                        text: root.weatherDesc !== "" ? root.weatherDesc : "Weather unavailable"
                        color: root.d.cText
                        font.pixelSize: 14 * root.sc
                        font.family: "Inter"
                    }
                    Text {
                        text: "H: " + root.weatherHigh + " L: " + root.weatherLow
                        color: root.d.cText
                        font.pixelSize: 14 * root.sc
                        font.family: "Inter"
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer — pushes lyrics to vertical center

        // ---------------- LYRICS ----------------
        Item {
            id: lyricsWrapper
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width * 0.95
            property real targetHeight: (root.lyricsList && root.lyricsList.length > 0) ? 400 * root.sc : 0
            Behavior on targetHeight { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            Layout.preferredHeight: targetHeight
            opacity: targetHeight > 0 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2 * root.sc
                color: root.d.cPanelBorder
                radius: 1 * root.sc
                
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    // Need to get musicProgress from parent or LockDataPollers. 
                    // LockRightColumn does not have musicProgress exposed yet. 
                    // I will expose it above. For now, height binds to root.musicProgress if we add it.
                    height: parent.height * (typeof root.musicProgress !== "undefined" ? root.musicProgress : 0)
                    color: root.d.cLime
                    radius: 1 * root.sc
                    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.Linear } }
                }
            }

            ListView {
                id: lyricsView
                anchors.fill: parent
                anchors.leftMargin: 16 * root.sc
                
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
                font.pixelSize: ListView.isCurrentItem ? 48 * root.sc : 28 * root.sc
                font.weight: Font.Light
                font.family: "Inter"
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                opacity: ListView.isCurrentItem ? 1.0 : 0.35

                Behavior on opacity {
                    NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
                }
                Behavior on font.pixelSize {
                    NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
                }

                property real blurAmount: ListView.isCurrentItem ? 0.0 : 1.0
                Behavior on blurAmount {
                    NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
                }

                layer.enabled: blurAmount > 0
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 10 * root.sc
                    blur: lyricText.blurAmount
                }

                transform: Translate {
                    y: ListView.isCurrentItem ? 0 : 4 * root.sc
                    Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                }
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
        } // end lyricsWrapper

        Item { Layout.fillHeight: true } // Bottom spacer — balances lyrics to center
    }
}
