import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../"
import "github" as Github
import "./lock"

ShellRoot {
    id: root

    Caching { id: paths }

    // ── Theme ─────────────────────────────────────────────────────────
    MatugenColors { id: _theme }
    readonly property color base:     _theme.base
    readonly property color crust:    _theme.crust
    readonly property color mantle:   _theme.mantle
    readonly property color text:     _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay2: _theme.overlay2
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color mauve:    _theme.mauve
    readonly property color red:      _theme.red
    readonly property color peach:    _theme.peach
    readonly property color blue:     _theme.blue
    readonly property color green:    _theme.green
    readonly property color teal:     _theme.teal
    readonly property color pink:     _theme.pink
    readonly property color yellow:   _theme.yellow
    readonly property color sapphire: _theme.sapphire

    // ── Session config ────────────────────────────────────────────────
    QtObject {
        id: lockSettings
        property bool hidePassword: false
        property int  revealDuration: 300
    }

    // ── Shared lock state (all monitors) ──────────────────────────────
    QtObject {
        id: lockUI
        property bool   failed:        false
        property bool   authenticating: false
        property string statusText:    "Locked"
        property bool   unlocking:     false
    }

    // ── PAM authentication ────────────────────────────────────────────
    Timer {
        id: pamActionTimer; interval: 50
        onTriggered: pam.start()
    }

    PamContext {
        id: pam
        Component.onCompleted: pamActionTimer.start()
        onCompleted: function(result) {
            lockUI.authenticating = false;
            if (result === PamResult.Success) {
                lockUI.unlocking = true;
                unlockQuitTimer.start();
            } else {
                lockUI.failed = true;
                lockUI.statusText = "Access Denied";
                pamActionTimer.start();
            }
        }
    }

    Timer {
        id: unlockQuitTimer; interval: 350
        onTriggered: { rootLock.locked = false; Qt.quit(); }
    }

    // ── Session processes ─────────────────────────────────────────────
    Process { id: suspendProcess;  command: ["systemctl", "suspend"] }
    Process { id: poweroffProcess; command: ["systemctl", "poweroff"] }
    Process { id: reloadProcess;   command: ["systemctl", "reboot"] }

    // ── Lock surface ──────────────────────────────────────────────────
    WlSessionLock {
        id: rootLock
        locked: true

        WlSessionLockSurface {
            id: surface

            Item {
                id: screenRoot
                anchors.fill: parent

                Scaler { id: scaler; currentWidth: screenRoot.width > 0 ? screenRoot.width : Screen.width }
                readonly property real sc: scaler.baseScale

                // Password shapes array
                readonly property var pwShapes: ["◆","▲","★","✦","◉","◈","⬡","✧","◇","▷","⬟","△","⬣","✱"]

                // UI state
                property real introState:    0.0
                property bool powerMenuOpen: false
                property bool isPlayingIntro: true

                // Unlock shrink + fade
                Behavior on scale   { enabled: lockUI.unlocking; NumberAnimation { duration: 300; easing.type: Easing.InBack } }
                Behavior on opacity { enabled: lockUI.unlocking; NumberAnimation { duration: 300; easing.type: Easing.InCubic } }
                scale:   lockUI.unlocking ? 0.8 : 1.0
                opacity: lockUI.unlocking ? 0.0 : 1.0

                Component.onCompleted: introAnimation.start()

                // Orbit angle for background orbs
                property real globalOrbitAngle: 0
                NumberAnimation on globalOrbitAngle {
                    from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
                }

                // ── Dashboard colors (HUD palette) ────────────────────────────
                readonly property color cLime:       "#b4ff39"
                readonly property color cLimeDim:    "#7fb32a"
                readonly property color cCyan:       "#5ecfc9"
                readonly property color cAmber:      "#f2b056"
                readonly property color cText:       "#e8eae4"
                readonly property color cTextDim:    "#8b948a"
                readonly property color cTextFaint:  "#5a635a"
                readonly property color cPanel:      Qt.rgba(14/255,  20/255,  15/255,  0.55)
                readonly property color cPanelBorder: Qt.rgba(180/255, 255/255, 57/255,  0.14)
                readonly property color cHairline:   Qt.rgba(232/255, 234/255, 229/255, 0.08)

                // Convenience object forwarded to sub-components
                QtObject {
                    id: d
                    readonly property color cLime:        screenRoot.cLime
                    readonly property color cLimeDim:     screenRoot.cLimeDim
                    readonly property color cCyan:        screenRoot.cCyan
                    readonly property color cAmber:       screenRoot.cAmber
                    readonly property color cText:        screenRoot.cText
                    readonly property color cTextDim:     screenRoot.cTextDim
                    readonly property color cTextFaint:   screenRoot.cTextFaint
                    readonly property color cPanel:       screenRoot.cPanel
                    readonly property color cPanelBorder: screenRoot.cPanelBorder
                    readonly property color cHairline:    screenRoot.cHairline
                }

                // ── Data pollers ──────────────────────────────────────────────
                LockDataPollers {
                    id: data; paths: paths
                }

                // ── Background ────────────────────────────────────────────────
                LockBackground {
                    anchors.fill: parent
                    baseColor:         root.base
                    mauveColor:        root.mauve
                    blueColor:         root.blue
                    wallpaperPath:     "file://" + paths.getCacheDir("wallpaper_picker") + "/current_wallpaper.png"
                    sc:                screenRoot.sc
                    globalOrbitAngle:  screenRoot.globalOrbitAngle
                }

                // ── Click handler ─────────────────────────────────────────────
                MouseArea {
                    anchors.fill: parent; enabled: !screenRoot.isPlayingIntro
                    onClicked: {
                        if (screenRoot.powerMenuOpen) { screenRoot.powerMenuOpen = false; return; }
                        centerPanel.inputField.forceActiveFocus();
                    }
                }

                // ── HUD dashboard ─────────────────────────────────────────────
                Item {
                    anchors.fill: parent
                    opacity:   screenRoot.introState
                    transform: Translate { y: (20 * screenRoot.sc) * (1.0 - screenRoot.introState) }

                    // HUD frame brackets (decorative)
                    Item {
                        anchors.fill: parent; anchors.margins: 28 * screenRoot.sc

                        component Bracket: Rectangle {
                            property string type: "tl"
                            width: 34 * screenRoot.sc; height: 34 * screenRoot.sc
                            color: "transparent"; border.color: screenRoot.cLime; opacity: 0.55
                            Rectangle { width: parent.width; height: 2 * screenRoot.sc; color: screenRoot.cLime; anchors.top: (type === "tl" || type === "tr") ? parent.top : undefined; anchors.bottom: (type === "bl" || type === "br") ? parent.bottom : undefined }
                            Rectangle { width: 2 * screenRoot.sc; height: parent.height; color: screenRoot.cLime; anchors.left: (type === "tl" || type === "bl") ? parent.left : undefined; anchors.right: (type === "tr" || type === "br") ? parent.right : undefined }
                        }
                    }

                    // Header: LOCKED indicator
                    Row {
                        anchors.top: parent.top; anchors.left: parent.left
                        anchors.topMargin: 38 * screenRoot.sc; anchors.leftMargin: 52 * screenRoot.sc
                        spacing: 8 * screenRoot.sc
                        Rectangle {
                            width: 6 * screenRoot.sc; height: 6 * screenRoot.sc; radius: 3 * screenRoot.sc; color: screenRoot.cLime
                            SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0.25; duration: 1000 }; NumberAnimation { to: 1.0; duration: 1000 } }
                        }
                        Text { text: "LOCKED"; font.family: "SF Pro Display"; font.pixelSize: 11 * screenRoot.sc; font.letterSpacing: 2; color: screenRoot.cLime; opacity: 0.8 }
                    }

                    // Header: system tag
                    Text {
                        anchors.top: parent.top; anchors.right: parent.right
                        anchors.topMargin: 38 * screenRoot.sc; anchors.rightMargin: 52 * screenRoot.sc
                        text: "ARCH_LINUX   HYPRLAND"; font.family: "SF Pro Display"; font.pixelSize: 11 * screenRoot.sc; font.letterSpacing: 1; color: screenRoot.cTextDim
                    }

                    // Footer
                    Text {
                        anchors.bottom: parent.bottom; anchors.left: parent.left
                        anchors.bottomMargin: 38 * screenRoot.sc; anchors.leftMargin: 52 * screenRoot.sc
                        text: "UPTIME " + data.uptimeStr.toUpperCase() + " · LAYOUT " + data.kbLayout.toUpperCase() + " · ZSH 5.9.1"
                        font.family: "SF Pro Display"; font.pixelSize: 10 * screenRoot.sc; font.letterSpacing: 1.5; color: screenRoot.cTextFaint
                    }

                    // 3-column grid
                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 80 * screenRoot.sc; anchors.rightMargin: 80 * screenRoot.sc

                        LockLeftPanel {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            sc: screenRoot.sc; d: d
                            currentUser:  data.currentUser
                            musicTitle:   data.musicTitle; musicArtist: data.musicArtist
                            musicActive:  data.musicActive; musicPlaying: data.musicPlaying
                            onPlayPauseClicked: data.playPause()
                            onNextClicked:      data.next()
                            onPrevClicked:      data.prev()
                        }

                        LockCenterPanel {
                            id: centerPanel
                            anchors.centerIn: parent
                            sc: screenRoot.sc; d: d
                            currentUser:   data.currentUser
                            faceIconPath:  data.faceIconPath
                            isPlayingIntro: screenRoot.isPlayingIntro
                            locked:         screenRoot.powerMenuOpen
                            authenticating: lockUI.authenticating
                            failed:         lockUI.failed
                            pwShapes:       screenRoot.pwShapes
                            weatherIcon: data.weatherIcon; weatherDesc: data.weatherDesc; weatherTemp: data.weatherTemp
                            onAuthRequested: function(password) {
                                if (pam.responseRequired && !lockUI.authenticating) {
                                    lockUI.authenticating = true; lockUI.statusText = "Authenticating...";
                                    lockUI.failed = false; pam.respond(password);
                                }
                            }
                            onFailCleared: lockUI.failed = false
                            onDoSuspend:   suspendProcess.running = true
                            onDoReboot:    reloadProcess.running  = true
                            onDoPoweroff:  poweroffProcess.running = true
                        }

                        LockRightPanel {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            sc: screenRoot.sc; d: d
                            cpuPct: data.cpuPct; ramPct: data.ramPct; diskPct: data.diskPct; tempVal: data.tempVal
                        }
                    }
                }

                // ── Power menu ────────────────────────────────────────────────
                LockPowerMenu {
                    anchors.fill: parent
                    sc:             screenRoot.sc
                    theme:          _theme
                    isPlayingIntro: screenRoot.isPlayingIntro
                    powerMenuOpen:  screenRoot.powerMenuOpen
                    introState:     screenRoot.introState
                    onOpenChanged: function(open) { screenRoot.powerMenuOpen = open; if (!open) centerPanel.inputField.forceActiveFocus(); }
                    onDoReboot:    reloadProcess.running   = true
                    onDoSuspend:   suspendProcess.running  = true
                    onDoPoweroff:  poweroffProcess.running = true
                }

                // ── Intro animation ───────────────────────────────────────────
                LockIntroAnimation {
                    id: introAnimation
                    anchors.fill: parent
                    sc:    screenRoot.sc
                    theme: _theme
                    onFinished: {
                        screenRoot.isPlayingIntro = false;
                        screenRoot.introState = 1.0;
                        centerPanel.inputField.text = "";
                        centerPanel.inputField.forceActiveFocus();
                    }
                }
            }
        }
    }
}
