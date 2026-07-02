import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import "../"
import "../topbar/logic" as Logic
import "./components" as CCComponents

Item {
    id: window
    focus: true

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    // ── Logic ────────────────────────────────────────────────────────
    Logic.NetworkWatcher { id: netWatcher }
    Logic.AudioWatcher { id: audioWatcher }
    
    property bool isWifiOn: netWatcher.wifiStatus === "On"
    property bool isBtOn: netWatcher.btStatus === "On"
    property bool isDndOn: false // Requires pulling state from DND file (like in NotificationPopup)
    property bool isDarkMode: true // Not easily polled without a watcher, placeholder for now
    
    property real sysBrightness: 50
    Process {
        id: brightnessPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/get_brightness.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length > 5) {
                    window.sysBrightness = parseInt(lines[4]) || 50;
                }
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: brightnessPoller.running = true }

    // ANIMATIONS
    property real introMain: 0
    property real introContent: 0

    ParallelAnimation {
        running: true
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 600; easing.type: Easing.OutExpo }
        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation { target: window; property: "introContent"; from: 0; to: 1.0; duration: 600; easing.type: Easing.OutExpo }
        }
    }

    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introMain)
        opacity: introMain
        transform: Translate { y: s(20) * (1 - introMain) }

        Rectangle {
            anchors.fill: parent
            radius: s(24)
            color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.70)
            border.color: Qt.rgba(window.overlay0.r, window.overlay0.g, window.overlay0.b, 0.4)
            border.width: 1
            clip: true
            
            // Layout
            Column {
                anchors.fill: parent
                anchors.margins: s(16)
                spacing: s(16)
                opacity: introContent
                transform: Translate { y: s(10) * (1 - introContent) }

                // TOP ROW: Profile (Left) and Toggles (Right)
                Row {
                    width: parent.width
                    height: s(120)
                    spacing: s(16)

                    // Profile Section
                    Rectangle {
                        width: (parent.width - s(16)) / 2
                        height: parent.height
                        radius: s(20)
                        color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: s(8)
                            
                            Rectangle {
                                width: s(64); height: s(64)
                                radius: width / 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: window.surface1
                                Image {
                                    anchors.fill: parent
                                    source: "file://" + Quickshell.env("HOME") + "/.face.icon"
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                            Text {
                                text: Quickshell.env("USER")
                                font.pixelSize: s(16)
                                font.bold: true
                                color: window.text
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Toggles Section (2x2 Grid)
                    Grid {
                        width: (parent.width - s(16)) / 2
                        height: parent.height
                        columns: 2
                        rows: 2
                        spacing: s(10)
                        
                        // Wi-Fi
                        CCComponents.ToggleBtn {
                            width: (parent.width - s(10)) / 2
                            height: (parent.height - s(10)) / 2
                            isActive: window.isWifiOn
                            icon: netWatcher.wifiIcon
                            iconSize: s(20)
                            activeColor: window.blue
                            inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                            activeIconColor: window.base
                            inactiveIconColor: window.text
                            onClicked: { Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"]); }
                        }
                        
                        // Bluetooth
                        CCComponents.ToggleBtn {
                            width: (parent.width - s(10)) / 2
                            height: (parent.height - s(10)) / 2
                            isActive: window.isBtOn
                            icon: netWatcher.btIcon
                            iconSize: s(20)
                            activeColor: window.blue
                            inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                            activeIconColor: window.base
                            inactiveIconColor: window.text
                            onClicked: { Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bluetooth"]); }
                        }

                        // DND
                        CCComponents.ToggleBtn {
                            width: (parent.width - s(10)) / 2
                            height: (parent.height - s(10)) / 2
                            isActive: window.isDndOn
                            icon: window.isDndOn ? "󰂛" : "󰂚"
                            iconSize: s(20)
                            activeColor: window.mauve
                            inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                            activeIconColor: window.base
                            inactiveIconColor: window.text
                            onClicked: {
                                Quickshell.execDetached(["quickshell", "ipc", "call", "main", "toggleDnd"]);
                                window.isDndOn = !window.isDndOn;
                            }
                        }

                        // Dark Mode (placeholder)
                        CCComponents.ToggleBtn {
                            width: (parent.width - s(10)) / 2
                            height: (parent.height - s(10)) / 2
                            isActive: window.isDarkMode
                            icon: window.isDarkMode ? "󰖨" : "󰖎"
                            iconSize: s(20)
                            activeColor: window.yellow
                            inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                            activeIconColor: window.base
                            inactiveIconColor: window.text
                            onClicked: { window.isDarkMode = !window.isDarkMode; } // Just UI for now
                        }
                    }
                }

                // SLIDERS
                Rectangle {
                    width: parent.width
                    height: s(100)
                    radius: s(20)
                    color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                    
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - s(32)
                        spacing: s(16)
                        
                        // Brightness
                        CCComponents.SliderRow {
                            width: parent.width
                            height: s(20)
                            icon: window.sysBrightness > 66 ? "󰃠" : (window.sysBrightness > 33 ? "󰃟" : "󰃞")
                            iconSize: s(18)
                            iconColor: window.text
                            trackColor: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.8)
                            fillColor: window.yellow
                            value: window.sysBrightness
                            onValueChangedUser: (val) => {
                                window.sysBrightness = val;
                                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/set_brightness.sh " + Math.round(val)]);
                            }
                        }
                        
                        // Volume
                        CCComponents.SliderRow {
                            width: parent.width
                            height: s(20)
                            icon: audioWatcher.volIcon
                            iconSize: s(18)
                            iconColor: window.text
                            trackColor: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.8)
                            fillColor: window.mauve
                            value: parseInt(audioWatcher.volPercent) || 0
                            onValueChangedUser: (val) => {
                                Quickshell.execDetached(["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (val / 100).toFixed(2)]);
                            }
                        }
                    }
                }

                // MEDIA PLAYER
                Rectangle {
                    width: parent.width
                    height: s(120)
                    radius: s(20)
                    color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Media Player Placeholder"
                        color: window.subtext0
                    }
                }

                // POWER CONTROLS
                Row {
                    width: parent.width
                    height: s(60)
                    spacing: s(12)
                    
                    Repeater {
                        model: [
                            { icon: "󰌾", color: window.text, action: "hyprlock" },
                            { icon: "󰍃", color: window.peach, action: "hyprctl dispatch exit" },
                            { icon: "󰑐", color: window.green, action: "systemctl reboot" },
                            { icon: "󰐥", color: window.red, action: "systemctl poweroff" }
                        ]
                        
                        Rectangle {
                            width: (parent.width - (3 * s(12))) / 4
                            height: parent.height
                            radius: s(16)
                            color: powerMouse.containsMouse ? Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.8) : Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: modelData.color
                                font.pixelSize: s(22)
                            }
                            
                            MouseArea {
                                id: powerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c", modelData.action])
                            }
                        }
                    }
                }
            }
        }
    }
}
