import QtQuick
import QtQuick.Layouts

// Left HUD panel: OS/user telemetry + now-playing music with controls
Rectangle {
    id: root

    required property real sc
    required property var  d         // dashboardItem colors object
    required property string currentUser
    required property string musicTitle
    required property string musicArtist
    required property bool   musicActive
    required property bool   musicPlaying

    signal playPauseClicked
    signal nextClicked
    signal prevClicked

    color:  d.cPanel
    border.color: d.cPanelBorder
    border.width: 1
    radius: 4 * sc
    width:  280 * sc
    height: colContent.implicitHeight + (36 * sc)

    ColumnLayout {
        id: colContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 18 * sc
        spacing: 0

        // Header
        Text {
            text: "SYSTEM // TELEMETRY"
            font.family: "SF Pro Display"; font.pixelSize: 10 * sc
            font.weight: Font.DemiBold; font.letterSpacing: 2.5
            color: d.cLimeDim
            Layout.bottomMargin: 12 * sc
        }

        // Telemetry rows
        component TelemetryRow: RowLayout {
            property string key: ""
            property string val: ""
            property bool isAccent: false
            Layout.fillWidth: true
            Layout.topMargin: 6 * sc; Layout.bottomMargin: 6 * sc
            Text { text: parent.key; font.family: "SF Pro Display"; font.pixelSize: 11 * sc; color: d.cTextDim; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text { text: parent.val; font.family: "SF Pro Display"; font.pixelSize: 13 * sc; font.weight: Font.DemiBold; color: parent.isAccent ? d.cLime : d.cText }
        }

        TelemetryRow { key: "OS";        val: "Arch Linux" }
        TelemetryRow { key: "WM";        val: "Hyprland";         isAccent: true }
        TelemetryRow { key: "USER";      val: root.currentUser }
        TelemetryRow { key: "CPU MODEL"; val: "i3-1005G1" }

        // Divider
        Rectangle { Layout.fillWidth: true; height: 1; color: d.cHairline; Layout.topMargin: 14 * sc; Layout.bottomMargin: 14 * sc }

        // Now Playing header
        RowLayout {
            spacing: 8 * sc; Layout.bottomMargin: 8 * sc
            Text { text: "♪"; font.family: "SF Pro Display"; font.pixelSize: 10 * sc; color: d.cCyan }
            Text { text: "NOW PLAYING"; font.family: "SF Pro Display"; font.pixelSize: 10 * sc; font.letterSpacing: 2; color: d.cCyan }
        }

        // Track info
        Text {
            text: root.musicTitle !== "" ? root.musicTitle : "No Media"
            font.family: "SF Pro Display"; font.pixelSize: 12 * sc; font.weight: Font.DemiBold; color: d.cText
            elide: Text.ElideRight; Layout.fillWidth: true
        }
        Text {
            text: root.musicArtist !== "" ? root.musicArtist : "Unknown Artist"
            font.family: "SF Pro Display"; font.pixelSize: 11 * sc; color: d.cTextDim
            Layout.bottomMargin: 10 * sc
            elide: Text.ElideRight; Layout.fillWidth: true
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true; height: 2 * sc; radius: 2 * sc; color: d.cHairline
            clip: true; Layout.bottomMargin: 8 * sc
            Rectangle { width: parent.width * (root.musicActive ? 0.38 : 0); height: parent.height; color: d.cCyan }
        }

        // Controls
        RowLayout {
            spacing: 14 * sc
            component CtrlBtn: Text {
                property bool isMain: false
                font.family: "Iosevka Nerd Font"
                font.pixelSize: isMain ? 15 * sc : 13 * sc
                color: isMain ? d.cText : d.cTextDim
                signal clicked()
                MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
            }
            CtrlBtn { text: "󰒮"; onClicked: root.prevClicked() }
            CtrlBtn { text: root.musicPlaying ? "󰏤" : "󰐊"; isMain: true; onClicked: root.playPauseClicked() }
            CtrlBtn { text: "󰒭"; onClicked: root.nextClicked() }
        }
    }
}
