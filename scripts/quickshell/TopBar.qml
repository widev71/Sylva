import QtQuick.Effects
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "./topbar/logic"
import "./topbar/components"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: barWindow

            // ── IPC ───────────────────────────────────────────────────────
            IpcHandler {
                target: "topbar"
                function forceReload() { Quickshell.reload(true) }
                function queueReload() {
                    if (!barWindow.isSettingsOpen) Quickshell.reload(true);
                    else barWindow.pendingReload = true;
                }
                function toggleUpdate() { barWindow.forceUpdateShow = !barWindow.forceUpdateShow }
            }

            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }

            // ── Scaling ───────────────────────────────────────────────────
            Caching  { id: paths }
            Scaler   { id: scaler; currentWidth: barWindow.width }
            MatugenColors { id: mocha }

            property real baseScale: scaler.baseScale
            function s(val) { return scaler.s(val) }
            property int barHeight: s(48)

            height: barHeight
            margins { top: s(8); bottom: 0; left: s(4); right: s(4) }
            exclusiveZone: barHeight
            color: "transparent"

            // ── Reload state ──────────────────────────────────────────────
            property bool pendingReload: false

            onIsSettingsOpenChanged: {
                if (!isSettingsOpen && pendingReload) {
                    pendingReload = false;
                    Quickshell.reload(true);
                }
            }

            // ── Startup readiness ─────────────────────────────────────────
            property bool isStartupReady:          false
            property bool startupCascadeFinished:  false
            property bool fastPollerLoaded:        false
            property bool isDataReady:             fastPollerLoaded

            Timer { interval: 10;   running: true; onTriggered: barWindow.isStartupReady = true }
            Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
            Timer { interval: 600;  running: true; onTriggered: barWindow.isDataReady = true }

            // ── Widget / panel state ───────────────────────────────────────
            property string activeWidget: ""
            property bool isSettingsOpen: activeWidget === "settings"
            property real settingsSlideProgress: isSettingsOpen ? 1.0 : 0.0
            Behavior on settingsSlideProgress {
                enabled: barWindow.startupCascadeFinished
                NumberAnimation { duration: 600; easing.type: Easing.OutExpo }
            }

            // ── Update badge ───────────────────────────────────────────────
            property bool forceUpdateShow: false
            property bool isUpdateVisible: updateWatcher.updateAvailable || forceUpdateShow

            // ── Derived state helpers ──────────────────────────────────────
            property bool isMediaActive:  musicLogic.isMediaActive
            property bool isWifiOn:       netWatcher.wifiStatus.toLowerCase() === "enabled"
                                       || netWatcher.wifiStatus.toLowerCase() === "on"
            property bool isBtOn:         netWatcher.btStatus.toLowerCase() === "enabled"
                                       || netWatcher.btStatus.toLowerCase() === "on"
            property bool showEthernet:   netWatcher.ethStatus === "Connected"
                                       || (chassisDetect.isDesktop && !isWifiOn)
            property bool isSoundActive:  !audioWatcher.isMuted
                                       && parseInt(audioWatcher.volPercent) > 0
            property int  batCap:         parseInt(audioWatcher.batPercent) || 0
            property bool isCharging:     audioWatcher.batStatus === "Charging"
                                       || audioWatcher.batStatus === "Full"
            property color batDynamicColor: {
                if (isCharging)    return mocha.green;
                if (batCap <= 20)  return mocha.red;
                return mocha.text;
            }

            // ══════════════════════════════════════════════════════════════
            // LOGIC LAYER
            // ══════════════════════════════════════════════════════════════

            WidgetWatcher {
                id: widgetWatcherL
                paths: paths
                activeWidget: barWindow.activeWidget
                onWidgetChanged: function(w) { barWindow.activeWidget = w }
            }

            RecordingWatcher {
                id: recWatcherL
                paths: paths
            }

            UpdateWatcher {
                id: updateWatcher
                paths: paths
            }

            SettingsWatcher {
                id: settingsWatcher
                onWorkspaceCountChanged: function() { wsLogic.workspaceCount = settingsWatcher.workspaceCount }
            }

            ChassisDetector { id: chassisDetect }

            WorkspaceLogic {
                id: wsLogic
                paths: paths
                workspaceCount: settingsWatcher.workspaceCount
            }

            MusicLogic {
                id: musicLogic
                paths: paths
            }

            AudioWatcher {
                id: audioWatcher
                onFastPollerLoaded: barWindow.fastPollerLoaded = true
            }

            NetworkWatcher { id: netWatcher }

            WeatherClock {
                id: weatherClock
                startupReady: barWindow.isStartupReady
            }

            // ══════════════════════════════════════════════════════════════
            // UI LAYER
            // ══════════════════════════════════════════════════════════════

            Item {
                anchors.fill: parent

                // ── Left Panel ────────────────────────────────────────────
                LeftPanel {
                    id: leftContent
                    y: (parent.height - barHeight) / 2
                    mocha: mocha
                    s: barWindow.s
                    showHelpIcon:  settingsWatcher.showHelpIcon
                    isUpdateVisible: barWindow.isUpdateVisible
                    isSettingsOpen:  barWindow.isSettingsOpen
                    startupReady:    barWindow.isStartupReady
                }

                // ── Workspaces ────────────────────────────────────────────
                WorkspaceBar {
                    id: workspacesBox
                    y: (parent.height - barHeight) / 2
                    mocha: mocha
                    s: barWindow.s
                    workspacesModel:       wsLogic.model
                    startupCascadeFinished: barWindow.startupCascadeFinished

                    property real defaultX: leftContent.x + leftContent.width + s(4)
                    property real settingsX: mediaBox.settingsX - width - (width > 0 ? s(4) : 0)
                    x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress
                }

                // ── Media Box ─────────────────────────────────────────────
                MediaBox {
                    id: mediaBox
                    y: (parent.height - barHeight) / 2
                    mocha: mocha
                    s: barWindow.s
                    musicData:    musicLogic.musicData
                    displayTitle: musicLogic.displayTitle
                    displayTime:  musicLogic.displayTime
                    displayArtUrl: musicLogic.displayArtUrl
                    isMediaActive: musicLogic.isMediaActive
                    onRefreshMusic: musicLogic.refresh()

                    property real defaultX: workspacesBox.defaultX + workspacesBox.width
                                          + (workspacesBox.width > 0 ? s(4) : 0)
                    property real settingsX: centerClock.settingsX - width - (width > 0 ? s(4) : 0)
                    x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress
                }

                // ── Center Clock ──────────────────────────────────────────
                CenterClock {
                    id: centerClock
                    y: (parent.height - barHeight) / 2
                    mocha: mocha
                    s: barWindow.s
                    timeStr:     weatherClock.timeStr
                    dateStr:     weatherClock.dateStr
                    weatherIcon: weatherClock.weatherIcon
                    weatherTemp: weatherClock.weatherTemp
                    weatherHex:  weatherClock.weatherHex
                    startupReady: barWindow.isStartupReady

                    property real pureCenter: (parent.width - width) / 2
                    property real minX: mediaBox.defaultX + mediaBox.width
                                      + (mediaBox.width > 0 ? s(4) : 0)
                    property real settingsX: parent.width - rightRow.width - width - s(4)
                    property real defaultX: Math.max(minX, pureCenter)
                    x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress
                }

                // ── Right Row ─────────────────────────────────────────────
                Row {
                    id: rightRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: s(4)

                    property bool showLayout: false
                    opacity: showLayout ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    transform: Translate {
                        x: rightRow.showLayout ? 0 : s(30)
                        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                    }
                    Timer {
                        running: barWindow.isStartupReady && barWindow.isDataReady
                        interval: 250
                        onTriggered: rightRow.showLayout = true
                    }

                    // System tray
                    SystemTrayBox {
                        mocha: mocha
                        s: barWindow.s
                        barWindow: barWindow
                        startupCascadeFinished: barWindow.startupCascadeFinished
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Sys info panel
                    Rectangle {
                        height: barHeight
                        radius: s(14)
                        border.color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.5)
                        border.width: 1
                        color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.40)
                        anchors.verticalCenter: parent.verticalCenter

                        width: sysRow.implicitWidth + s(20)

                        Row {
                            id: sysRow
                            anchors.centerIn: parent
                            spacing: s(8)

                            KbPill {
                                mocha: mocha; s: barWindow.s
                                kbLayout: audioWatcher.kbLayout
                                showLayout: rightRow.showLayout
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TodoNotifRow {
                                mocha: mocha; s: barWindow.s
                                showLayout: rightRow.showLayout
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Control Center Toggle
                            Item {
                                width: s(28)
                                height: s(28)
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: rightRow.showLayout ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: s(8)
                                    color: ccMouseArea.containsMouse ? Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.5) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒓"
                                        font.pixelSize: s(16)
                                        color: mocha.text
                                    }
                                    
                                    MouseArea {
                                        id: ccMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle controlcenter"]);
                                        }
                                    }
                                }
                            }

                            WifiPill {
                                mocha: mocha; s: barWindow.s
                                wifiStatus:   netWatcher.wifiStatus
                                wifiIcon:     netWatcher.wifiIcon
                                wifiSsid:     netWatcher.wifiSsid
                                ethStatus:    netWatcher.ethStatus
                                showEthernet: barWindow.showEthernet
                                isWifiOn:     barWindow.isWifiOn
                                showLayout:   rightRow.showLayout
                                initDelay:    50
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            BtPill {
                                mocha: mocha; s: barWindow.s
                                btIcon:    netWatcher.btIcon
                                btDevice:  netWatcher.btDevice
                                isBtOn:    barWindow.isBtOn
                                isDesktop: chassisDetect.isDesktop
                                showLayout: rightRow.showLayout
                                initDelay:  100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            VolumePill {
                                mocha: mocha; s: barWindow.s
                                volIcon:     audioWatcher.volIcon
                                volPercent:  audioWatcher.volPercent
                                isSoundActive: barWindow.isSoundActive
                                showLayout:  rightRow.showLayout
                                initDelay:   150
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            BatteryPill {
                                mocha: mocha; s: barWindow.s
                                batIcon:         audioWatcher.batIcon
                                batPercent:      audioWatcher.batPercent
                                isDesktop:       chassisDetect.isDesktop
                                batDynamicColor: barWindow.batDynamicColor
                                showLayout:      rightRow.showLayout
                                initDelay:       200
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // ── Recording Button ──────────────────────────────────────
                RecordingButton {
                    id: recButton
                    y: (parent.height - barHeight) / 2
                    mocha: mocha
                    s: barWindow.s
                    isRecording: recWatcherL.isRecording
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
