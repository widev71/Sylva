import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
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

                // TITLE
                Text {
                    text: "Widget Manager"
                    font.pixelSize: s(24)
                    font.bold: true
                    color: window.text
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: s(10)
                    bottomPadding: s(10)
                }

                // WIDGET MANAGER GRID
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - s(10)
                    columns: 3
                    spacing: s(16)
                    
                                        // Top Bar: Settings
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopSettings
                        icon: ""
                        iconSize: s(24)
                        activeColor: window.mauve
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopSettings = !Config.showTopSettings;
                            Config.setSetting("showTopSettings", Config.showTopSettings);
                        }
                    }

                    // Top Bar: Search
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopSearch
                        icon: "󰍉"
                        iconSize: s(24)
                        activeColor: window.mauve
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopSearch = !Config.showTopSearch;
                            Config.setSetting("showTopSearch", Config.showTopSearch);
                        }
                    }

                    // Top Bar: Help
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopHelp
                        icon: "󰋗"
                        iconSize: s(24)
                        activeColor: window.mauve
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopHelp = !Config.showTopHelp;
                            Config.setSetting("showTopHelp", Config.showTopHelp);
                        }
                    }
                    
                    // Top Bar: Wi-Fi
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopWifi
                        icon: netWatcher.wifiIcon
                        iconSize: s(24)
                        activeColor: window.blue
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopWifi = !Config.showTopWifi;
                            Config.setSetting("showTopWifi", Config.showTopWifi);
                        }
                    }
                    
                    // Top Bar: Bluetooth
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopBt
                        icon: netWatcher.btIcon
                        iconSize: s(24)
                        activeColor: window.blue
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopBt = !Config.showTopBt;
                            Config.setSetting("showTopBt", Config.showTopBt);
                        }
                    }

                    // Top Bar: Volume
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopVolume
                        icon: "󰕾"
                        iconSize: s(24)
                        activeColor: window.green
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopVolume = !Config.showTopVolume;
                            Config.setSetting("showTopVolume", Config.showTopVolume);
                        }
                    }

                    // Top Bar: Battery
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopBattery
                        icon: "󰁹"
                        iconSize: s(24)
                        activeColor: window.green
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopBattery = !Config.showTopBattery;
                            Config.setSetting("showTopBattery", Config.showTopBattery);
                        }
                    }
                    
                    // Top Bar: Keyboard Layout
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopKb
                        icon: "󰌌"
                        iconSize: s(24)
                        activeColor: window.peach
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopKb = !Config.showTopKb;
                            Config.setSetting("showTopKb", Config.showTopKb);
                        }
                    }

                    // Top Bar: Todo
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopTodo
                        icon: "󰃶"
                        iconSize: s(24)
                        activeColor: window.peach
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopTodo = !Config.showTopTodo;
                            Config.setSetting("showTopTodo", Config.showTopTodo);
                        }
                    }

                    // Top Bar: Notifications
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: Config.showTopNotif
                        icon: "󰂚"
                        iconSize: s(24)
                        activeColor: window.yellow
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Config.showTopNotif = !Config.showTopNotif;
                            Config.setSetting("showTopNotif", Config.showTopNotif);
                        }
                    }

                    // Global: DND Mode
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        isActive: window.isDndOn
                        icon: window.isDndOn ? "󰂛" : "󰂚"
                        iconSize: s(24)
                        activeColor: window.mauve
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        onClicked: {
                            Quickshell.execDetached(["quickshell", "ipc", "call", "main", "toggleDnd"]);
                            window.isDndOn = !window.isDndOn;
                        }
                    }

                    // Global: Deep Focus Mode
                    CCComponents.ToggleBtn {
                        width: (parent.width - (s(16) * 2)) / 3
                        height: s(70)
                        property bool isFocusMode: false
                        isActive: isFocusMode
                        icon: isFocusMode ? "󰈈" : "󰈉" // Eye icon
                        iconSize: s(24)
                        activeColor: window.red
                        inactiveColor: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        activeIconColor: window.base
                        inactiveIconColor: window.text
                        
                        Component.onCompleted: {
                            Quickshell.exec(["bash", "-c", "test -f /tmp/hypr_focus_mode && echo 1 || echo 0"], function(result) {
                                isFocusMode = result.stdout.trim() === "1";
                            });
                        }
                        
                        onClicked: {
                            Quickshell.exec(["bash", "-c", "~/.config/hypr/scripts/focus_mode.sh"], function(result) {
                                isFocusMode = !isFocusMode;
                            });
                        }
                    }
                }
            }
        }
    }
}
