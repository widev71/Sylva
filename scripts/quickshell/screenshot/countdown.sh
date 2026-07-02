#!/usr/bin/env bash
# Standalone countdown window launcher for screen recording
# Called by screenshot.sh before starting the recorder
# Runs quickshell with a temporary countdown-only config

cat > /tmp/qs_countdown_shell.qml << 'EOF'
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            property var modelData
            screen: modelData
            color: "transparent"
            WlrLayershell.namespace: "qs-countdown"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            anchors { top: true; bottom: true; left: true; right: true }

            property string countdownValue: "3"
            property int step: 3

            Timer {
                id: ticker
                interval: 1000
                repeat: true
                running: true
                onTriggered: {
                    win.step -= 1;
                    if (win.step <= 0) {
                        ticker.stop();
                        Qt.quit();
                    } else {
                        win.countdownValue = win.step.toString();
                        bubbleAnim.restart();
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#99000000"
                opacity: 1.0
            }

            Text {
                id: countdownText
                anchors.centerIn: parent
                text: win.countdownValue
                color: "white"
                font.pixelSize: 300
                font.weight: Font.Bold
                font.family: "JetBrains Mono"

                SequentialAnimation {
                    id: bubbleAnim
                    running: false
                    ParallelAnimation {
                        NumberAnimation { target: countdownText; property: "scale"; from: 0.5; to: 1.2; duration: 600; easing.type: Easing.OutElastic; easing.overshoot: 1.5 }
                        NumberAnimation { target: countdownText; property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
                    }
                    NumberAnimation { target: countdownText; property: "opacity"; from: 1.0; to: 0.0; duration: 400; easing.type: Easing.InQuad }
                }

                Component.onCompleted: { scale = 0.5; bubbleAnim.restart(); }
            }
        }
    }
}
EOF

quickshell -p /tmp/qs_countdown_shell.qml
