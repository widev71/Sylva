import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

PanelWindow {
    id: osdWindow
    color: "transparent"

    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    focusable: false

    // ⚠️ KEY FIX: Remove from compositor entirely when not displaying
    visible: osdWindow.isActive

    anchors {
        bottom: true
    }
    
    margins.bottom: 40
    
    width: 250
    height: 60

    MatugenColors { id: theme }

    property real currentValue: 0.0
    property string currentIcon: "󰕾"
    property bool isMuted: false
    property bool isActive: false

    // Poll the osd trigger file
    Process {
        command: ["bash", "-c", "while inotifywait -qq -e modify /tmp/qs_osd_val 2>/dev/null; do cat /tmp/qs_osd_val; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("|");
                if (parts.length >= 2) {
                    let type = parts[0];
                    let val = parseFloat(parts[1]);
                    let muted = parts.length > 2 ? parts[2] === "1" : false;
                    
                    if (!isNaN(val)) {
                        osdWindow.currentValue = val;
                        osdWindow.isMuted = muted;
                        if (type === "volume") {
                            osdWindow.currentIcon = muted ? "󰖁" : (val > 0.6 ? "󰕾" : (val > 0.3 ? "󰖀" : "󰕿"));
                        } else if (type === "mic") {
                            osdWindow.currentIcon = muted ? "󰍭" : "󰍬";
                        } else if (type === "brightness") {
                            osdWindow.currentIcon = val > 0.6 ? "󰃠" : (val > 0.3 ? "󰃟" : "󰃞");
                        }
                        
                        osdWindow.isActive = true;
                        hideTimer.restart();
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: osdWindow.isActive = false
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.9)
        radius: 30
        
        opacity: osdWindow.isActive ? 1.0 : 0.0
        scale: osdWindow.isActive ? 1.0 : 0.8
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 10
            shadowColor: "#000000"
            shadowOpacity: 0.3
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            Text {
                text: osdWindow.currentIcon
                color: osdWindow.isMuted ? theme.red : theme.mauve
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 22
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 10
                radius: 5
                color: theme.surface2
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: parent.width * Math.min(osdWindow.currentValue, 1.0)
                    height: parent.height
                    radius: 5
                    color: osdWindow.isMuted ? theme.red : theme.mauve
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }
            }
        }
    }
}
