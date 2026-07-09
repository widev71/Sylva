import QtQuick
import QtQuick.Effects
import "./"

Item {
    id: root
    anchors.fill: parent

    property string userName: "Witya"
    property var backgroundSource: null

    signal finished()

    function getGreeting() {
        var hour = new Date().getHours()
        if (hour < 12) return "Good Morning, " + userName + "!"
        else if (hour < 18) return "Good Afternoon, " + userName + "!"
        else return "Good Evening, " + userName + "!"
    }

    property color crustColor: "black"
    property color textColor: "white"

    property int letterCount: textRepeater.count
    property int letterPopDuration: 500
    property int letterHoldDuration: 1500
    property int letterFadeOutDuration: 400
    property int lastLetterDelay: 300 + (letterCount * 30)
    property int totalDuration: lastLetterDelay + letterPopDuration + letterHoldDuration + letterFadeOutDuration

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Qt.alpha(crustColor, 0.55)
        opacity: 0

        MultiEffect {
            anchors.fill: parent
            source: root.backgroundSource
            visible: root.backgroundSource !== null
            blurEnabled: true
            blur: 0.6
            blurMax: 48
            saturation: -0.1
        }

        Repeater {
            model: 5
            delegate: Text {
                text: "✿"
                color: Qt.alpha(textColor, 0.25)
                font.pixelSize: 22 + (index * 6)
                x: parent.width * (0.15 + index * 0.18)
                y: parent.height * 0.5 + (index % 2 === 0 ? -140 : 130)
                opacity: 0
                rotation: index * 25

                NumberAnimation on opacity {
                    to: 1.0
                    duration: 900
                    running: bgRect.opacity > 0.5
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 0
            layer.enabled: true

            Repeater {
                id: textRepeater
                model: root.getGreeting().split("")

                delegate: Text {
                    id: letterText
                    text: modelData
                    color: textColor
                    font.family: "Inter"
                    font.pixelSize: Math.round(48 * (root.width / 1920))
                    font.bold: true

                    opacity: 0
                    transform: Translate { y: 30; id: letterTranslate }

                    SequentialAnimation {
                        running: true

                        PauseAnimation { duration: 300 + (index * 30) }

                        ParallelAnimation {
                            NumberAnimation { target: letterText; property: "opacity"; to: 1.0; duration: root.letterPopDuration; easing.type: Easing.OutBack }
                            NumberAnimation { target: letterTranslate; property: "y"; to: 0; duration: root.letterPopDuration; easing.type: Easing.OutBack }
                        }

                        PauseAnimation { duration: root.letterHoldDuration }

                        ParallelAnimation {
                            NumberAnimation { target: letterText; property: "opacity"; to: 0; duration: root.letterFadeOutDuration; easing.type: Easing.InCubic }
                            NumberAnimation { target: letterTranslate; property: "y"; to: -20; duration: root.letterFadeOutDuration; easing.type: Easing.InCubic }
                        }
                    }
                }
            }
        }

        SequentialAnimation {
            running: true

            NumberAnimation { target: bgRect; property: "opacity"; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
            PauseAnimation { duration: root.totalDuration - 300 - 600 }
            NumberAnimation { target: bgRect; property: "opacity"; to: 0; duration: 600; easing.type: Easing.InCubic }

            ScriptAction { script: root.finished() }
        }
    }
}