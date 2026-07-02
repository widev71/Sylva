import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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

                // ── Dashboard colors (Matugen palette) ────────────────────────────
                readonly property color cLime:       root.mauve
                readonly property color cLimeDim:    root.blue
                readonly property color cCyan:       root.sapphire
                readonly property color cAmber:      root.peach
                readonly property color cText:       root.text
                readonly property color cTextDim:    root.subtext0
                readonly property color cTextFaint:  root.overlay0
                readonly property color cPanel:      Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.55)
                readonly property color cPanelBorder: Qt.rgba(root.surface2.r, root.surface2.g, root.surface2.b, 0.50)
                readonly property color cHairline:   Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.50)

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

                // ── Album Art Full-screen Blur ────────────────────────────────
                Image {
                    id: blurBg
                    anchors.fill: parent
                    source: data.musicArtPath !== "" ? data.musicArtPath : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                    opacity: (data.musicActive && source !== "") ? 0.7 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 80 * screenRoot.sc
                        blur: 1.0
                        colorizationColor: root.crust
                        colorization: 0.4 // Darken it slightly to keep text readable
                    }
                }

                // ── Click handler ─────────────────────────────────────────────
                MouseArea {
                    anchors.fill: parent; enabled: !screenRoot.isPlayingIntro
                    onClicked: {
                        if (screenRoot.powerMenuOpen) { screenRoot.powerMenuOpen = false; return; }
                        mainPasswordField.forceActiveFocus();
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
                            SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0.25; duration: 1000 } NumberAnimation { to: 1.0; duration: 1000 } }
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

                    // 2-column absolute layout
                    Item {
                        anchors.fill: parent
                        anchors.topMargin: 120 * screenRoot.sc; anchors.bottomMargin: 80 * screenRoot.sc; anchors.leftMargin: 80 * screenRoot.sc; anchors.rightMargin: 80 * screenRoot.sc

                        LockLeftColumn {
                            id: leftColumn
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.35

                            sc: screenRoot.sc; d: d
                            musicTitle:   data.musicTitle; musicArtist: data.musicArtist; musicArtPath: data.musicArtPath
                            musicActive:  data.musicActive; musicPlaying: data.musicPlaying
                            musicProgress: data.musicProgress; musicPositionStr: data.musicPositionStr; musicLengthStr: data.musicLengthStr
                            onPlayPauseClicked: data.playPause()
                            onSeekRequested: function(percent) { data.seekMusic(percent); }
                            onNextClicked:      data.next()
                            onPrevClicked:      data.prev()

                            batPct:         data.batPct
                            batStatus:      data.batStatus
                        }

                        LockRightColumn {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.50 // Widened to give lyrics more space to the left

                            sc: screenRoot.sc; d: d
                            weatherIcon: data.weatherIcon; weatherDesc: data.weatherDesc; weatherTemp: data.weatherTemp
                            lyricsList: data.lyricsList
                            currentLyricIndex: data.currentLyricIndex
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
                    onOpenChanged: function(open) { screenRoot.powerMenuOpen = open; if (!open) mainPasswordField.forceActiveFocus(); }
                    onDoReboot:    reloadProcess.running   = true
                    onDoSuspend:   suspendProcess.running  = true
                    onDoPoweroff:  poweroffProcess.running = true
                }
                
                // ── Login Form (Moved from Left Column) ───────────────────────
                Rectangle {
                    id: loginPill
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 92 * screenRoot.sc // 28 (margin) + 48 (btn) + 16 (spacing)
                    anchors.bottomMargin: 32 * screenRoot.sc // Align visually with the button
                    width: 220 * screenRoot.sc
                    height: 38 * screenRoot.sc
                    radius: 19 * screenRoot.sc
                    color: Qt.rgba(0, 0, 0, 0.4)
                    opacity: screenRoot.introState
                    
                    TextInput {
                        id: mainPasswordField
                        anchors.fill: parent
                        anchors.leftMargin: 20 * screenRoot.sc
                        anchors.rightMargin: 20 * screenRoot.sc
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: lockUI.authenticating ? d.cPanel : d.cText
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 14 * screenRoot.sc
                        focus: true
                        enabled: !lockUI.authenticating
                        
                        onAccepted: {
                            if (text !== "") {
                                if (pam.responseRequired && !lockUI.authenticating) {
                                    lockUI.authenticating = true; lockUI.statusText = "Authenticating...";
                                    lockUI.failed = false; pam.respond(text);
                                }
                                text = ""; // clear after submit
                            }
                        }
                    }
                    
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20 * screenRoot.sc
                        anchors.verticalCenter: parent.verticalCenter
                        text: lockUI.authenticating ? "Verifying..." : (lockUI.failed ? "Access Denied" : "password")
                        color: lockUI.authenticating ? d.cPanel : (lockUI.failed ? d.red : d.cText)
                        font.pixelSize: 14 * screenRoot.sc
                        visible: mainPasswordField.text.length === 0
                    }
                }
                
                // ── Status Icons (Moved from Left Column) ──────────────────────
                RowLayout {
                    anchors.right: loginPill.left
                    anchors.rightMargin: 24 * screenRoot.sc
                    anchors.verticalCenter: loginPill.verticalCenter
                    spacing: 16 * screenRoot.sc
                    opacity: screenRoot.introState

                    // Wifi
                    Text { text: "󰖩"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: d.cText }
                    // Notification
                    Text { text: "󰂚"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: d.cText }
                    // Battery
                    RowLayout {
                        spacing: 6 * screenRoot.sc
                        Text { text: data.batStatus === "Charging" ? "󰂄" : "󰁹" ; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: d.cText }
                        Text {
                            text: data.batPct + "%"
                            color: d.cText
                            font.family: "SF Pro Display"
                            font.pixelSize: 12 * screenRoot.sc
                            opacity: 0.8
                        }
                    }
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
                        mainPasswordField.text = "";
                        mainPasswordField.forceActiveFocus();
                    }
                }
            }
        }
    }
}
