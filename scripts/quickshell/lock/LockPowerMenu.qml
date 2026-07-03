import QtQuick
import QtQuick.Layouts

// Power button + slide-up power menu (reboot / suspend / power off)
Item {
    id: root
    anchors.fill: parent

    required property real sc
    required property var theme   // MatugenColors object (root theme)
    required property bool isPlayingIntro
    required property bool powerMenuOpen
    required property real introState

    signal openChanged(bool open)
    signal doReboot
    signal doSuspend
    signal doPoweroff

    // ── Power button ──────────────────────────────────────────────────
    Rectangle {
        id: powerBtn
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        anchors.margins: 28 * sc
        width: 48 * sc; height: width; radius: height / 2

        color: root.powerMenuOpen
            ? theme.surface2
            : (powerBtnMa.containsMouse
                ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)
                : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.45))
        border.color: root.powerMenuOpen ? theme.red : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.12)
        border.width: 1
        opacity: root.introState
        scale:   powerBtnMa.pressed ? 0.9 : (powerBtnMa.containsMouse ? 1.08 : 1.0)

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        Text {
            anchors.centerIn: parent; text: "󰐥"
            font.family: "Iosevka Nerd Font"; font.pixelSize: 20 * sc
            color: root.powerMenuOpen ? theme.red : (powerBtnMa.containsMouse ? theme.text : theme.subtext0)
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        MouseArea {
            id: powerBtnMa; anchors.fill: parent; hoverEnabled: true
            enabled: !root.isPlayingIntro
            onClicked: {
                let next = !root.powerMenuOpen;
                root.powerMenuOpen = next;
                root.openChanged(next);
            }
        }
    }

    // ── Power menu ─────────────────────────────────────────────────────
    Rectangle {
        id: powerMenu
        anchors.bottom: powerBtn.top
        anchors.right:  parent.right
        anchors.bottomMargin: 12 * sc
        anchors.rightMargin:  28 * sc
        width: 240 * sc
        height: root.powerMenuOpen ? (pmLayout.implicitHeight + 20 * sc) : 0
        radius: 16 * sc; clip: true
        opacity: root.powerMenuOpen ? 1 : 0
        color:  Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.95)
        border.color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.2)
        border.width: 1
        Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            id: pmLayout
            anchors.top: parent.top; anchors.topMargin: 10 * sc
            anchors.left: parent.left; anchors.right: parent.right
            spacing: 4 * sc

            Text {
                text: "SYSTEM"
                font.family: "Inter"; font.weight: Font.Black
                font.pixelSize: 11 * sc; font.letterSpacing: 1.5
                color: theme.mauve
                Layout.leftMargin: 16 * sc
                Layout.topMargin: 4 * sc; Layout.bottomMargin: 4 * sc
            }

            component PmItem: Rectangle {
                property string label: ""
                property string icon: ""
                property color  accent: theme.text
                signal clicked()
                Layout.fillWidth: true
                Layout.preferredHeight: 44 * sc
                Layout.leftMargin: 8 * sc; Layout.rightMargin: 8 * sc
                radius: 10 * sc
                color: pmItemMa.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.1) : "transparent"
                scale: pmItemMa.pressed ? 0.95 : (pmItemMa.containsMouse ? 1.02 : 1.0)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 14 * sc; anchors.rightMargin: 14 * sc; spacing: 0
                    Text { text: icon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16 * sc; color: pmItemMa.containsMouse ? accent : Qt.rgba(accent.r, accent.g, accent.b, 0.5); Behavior on color { ColorAnimation { duration: 150 } } }
                    Item { Layout.fillWidth: true }
                    Text { text: label; font.family: "Inter"; font.pixelSize: 14 * sc; font.weight: Font.Medium; color: pmItemMa.containsMouse ? accent : Qt.rgba(accent.r, accent.g, accent.b, 0.5); Behavior on color { ColorAnimation { duration: 150 } } }
                }
                MouseArea { id: pmItemMa; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
            }

            PmItem { label: "Reboot";   icon: "󰜉"; accent: theme.blue;  onClicked: { root.powerMenuOpen = false; root.doReboot()   } }
            PmItem { label: "Suspend";  icon: "󰒲"; accent: theme.mauve; onClicked: { root.powerMenuOpen = false; root.doSuspend()  } }
            PmItem { label: "Power Off"; icon: "󰐥"; accent: theme.red; Layout.bottomMargin: 8 * sc; onClicked: { root.powerMenuOpen = false; root.doPoweroff() } }
        }
    }
}
