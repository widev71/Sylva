import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Right HUD panel: CPU / RAM / Temp / Disk stat bars
Rectangle {
    id: root

    required property real sc
    required property var  d
    required property real cpuPct
    required property real ramPct
    required property real diskPct
    required property real tempVal

    color:  d.cPanel
    border.color: d.cPanelBorder
    border.width: 1
    radius: 4 * sc
    width:  220 * sc
    height: colContent.implicitHeight + (36 * sc)

    ColumnLayout {
        id: colContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 18 * sc
        spacing: 0

        Text {
            text: "STATS"
            font.family: "SF Pro Display"; font.pixelSize: 10 * sc
            font.weight: Font.DemiBold; font.letterSpacing: 2.5
            color: d.cLimeDim
            Layout.bottomMargin: 12 * sc
        }

        component StatRow: ColumnLayout {
            property string label: ""
            property real pctValue: 0
            property bool isWarn: false
            Layout.fillWidth: true
            Layout.topMargin: 8 * sc; Layout.bottomMargin: 8 * sc
            spacing: 6 * sc

            RowLayout {
                Layout.fillWidth: true
                Text { text: parent.parent.label; font.family: "SF Pro Display"; font.pixelSize: 10 * sc; font.letterSpacing: 2; color: d.cTextDim }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(parent.parent.pctValue) + (parent.parent.label === "TEMP" ? "°" : "%")
                    font.family: "SF Pro Display"; font.pixelSize: 16 * sc; font.weight: Font.Bold
                    color: parent.parent.isWarn ? d.cAmber : d.cText
                }
            }
            Rectangle {
                Layout.fillWidth: true; height: 3 * sc; radius: 2 * sc; color: d.cHairline; clip: true
                Rectangle {
                    width: parent.width * (parent.parent.parent.pctValue / 100)
                    height: parent.height
                    color: parent.parent.parent.isWarn ? d.cAmber : d.cLime
                }
            }
        }

        StatRow { label: "CPU";  pctValue: root.cpuPct }
        Rectangle { Layout.fillWidth: true; height: 1; color: d.cHairline }
        StatRow { label: "RAM";  pctValue: root.ramPct }
        Rectangle { Layout.fillWidth: true; height: 1; color: d.cHairline }
        StatRow { label: "TEMP"; pctValue: Math.min(root.tempVal, 100); isWarn: root.tempVal > 60 }
        Rectangle { Layout.fillWidth: true; height: 1; color: d.cHairline }
        StatRow { label: "DISK"; pctValue: root.diskPct }
    }
}
