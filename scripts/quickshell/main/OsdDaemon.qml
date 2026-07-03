import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../"

PanelWindow {
    id: osdWindow

    property real uiScale: 1.0

    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors {
        bottom: true
    }
    
    // Width and height of the window surface
    width: 300 * uiScale
    height: 120 * uiScale
    margins.bottom: 60 * uiScale

    property string osdType: "volume" // "volume" or "brightness"
    property int osdValue: 50
    property bool osdVisible: false

    function showOsd(type, value) {
        osdType = type;
        osdValue = value;
        osdVisible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: osdVisible = false
    }

    MatugenColors { id: _theme }

    Item {
        anchors.fill: parent

        Rectangle {
            id: osdPill
            width: 240 * uiScale
            height: 48 * uiScale
            anchors.centerIn: parent
            radius: height / 2

            // Glassmorphism background
            color: Qt.alpha(_theme.base, 0.75)
            border.color: osdType === "volume" ? _theme.blue : _theme.yellow
            border.width: 1

            // Intro/outro animation
            opacity: osdVisible ? 1.0 : 0.0
            scale: osdVisible ? 1.0 : 0.8
            transform: Translate { y: osdVisible ? 0 : 20 * uiScale }

            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on transform { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.4
                shadowBlur: 1.5
                shadowVerticalOffset: 4
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16 * uiScale
                spacing: 12 * uiScale

                // Icon
                Text {
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 18 * uiScale
                    color: _theme.text
                    text: {
                        if (osdType === "volume") {
                            if (osdValue === 0) return "󰝟";
                            if (osdValue < 33) return "󰕿";
                            if (osdValue < 66) return "󰖀";
                            return "󰕾";
                        } else {
                            if (osdValue < 33) return "󰃞";
                            if (osdValue < 66) return "󰃟";
                            return "󰃠";
                        }
                    }
                    Behavior on text { enabled: osdVisible; SequentialAnimation { PauseAnimation { duration: 100 } } } // Delay icon change slightly
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 6 * uiScale
                    radius: height / 2
                    color: Qt.alpha(_theme.surface2, 0.5)
                    clip: true

                    Rectangle {
                        height: parent.height
                        width: parent.width * (Math.max(0, Math.min(100, osdValue)) / 100)
                        radius: height / 2
                        color: osdType === "volume" ? _theme.blue : _theme.yellow

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                }

                // Percentage Text
                Text {
                    Layout.preferredWidth: 35 * uiScale // Fixed width to prevent jumping
                    horizontalAlignment: Text.AlignRight
                    font.family: "Inter"
                    font.weight: Font.Bold
                    font.pixelSize: 13 * uiScale
                    color: _theme.subtext0
                    text: Math.max(0, Math.min(100, osdValue)) + "%"
                }
            }
        }
    }
}
