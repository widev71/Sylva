import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../"

PanelWindow {
    id: countdownWindow
    color: "transparent"

    WlrLayershell.namespace: "qs-countdown"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    focusable: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MatugenColors { id: theme }

    property string countdownValue: ""
    property bool isActive: countdownValue !== ""

    // Poll for countdown changes
    Process {
        command: ["bash", "-c", "while inotifywait -qq -e modify /tmp/qs_countdown_val 2>/dev/null; do cat /tmp/qs_countdown_val; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                countdownWindow.countdownValue = txt;
                if (txt !== "") {
                    anim.restart();
                }
            }
        }
    }

    // Fallback poll
    Process {
        command: ["bash", "-c", "while true; do cat /tmp/qs_countdown_val 2>/dev/null; sleep 0.1; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== countdownWindow.countdownValue) {
                    countdownWindow.countdownValue = txt;
                    if (txt !== "") {
                        anim.restart();
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent

        // Dim background
        Rectangle {
            anchors.fill: parent
            color: theme.base
            opacity: countdownWindow.isActive ? 0.6 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        }

        // Countdown Text
        Text {
            id: countdownText
            anchors.centerIn: parent
            text: countdownWindow.countdownValue
            color: theme.text
            font.pixelSize: 300
            font.weight: Font.Bold
            font.family: "Inter"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            
            opacity: countdownWindow.isActive ? 1.0 : 0.0
            scale: 0.5

            SequentialAnimation {
                id: anim
                running: false
                ParallelAnimation {
                    NumberAnimation { target: countdownText; property: "scale"; from: 0.5; to: 1.2; duration: 600; easing.type: Easing.OutElastic; easing.overshoot: 1.5 }
                    NumberAnimation { target: countdownText; property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
                }
                NumberAnimation { target: countdownText; property: "opacity"; from: 1.0; to: 0.0; duration: 400; easing.type: Easing.InQuad }
            }
        }
    }
}
