import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: window.s(145)
    height: window.s(145)

    // Properties to customize the orb
    property real animVal: 0
    property string valueText: Math.round(animVal) + "%"
    property string labelText: "DATA"
    property string iconText: ""
    
    // Colors
    property color colorMain: window.blue
    property color colorSecondary: window.sapphire

    Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
    onAnimValChanged: orbCanvas.requestPaint()

    scale: orbMa.containsMouse ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

    // Individual Aura - Fixed Overlap
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + (orbMa.containsMouse ? window.s(16) : window.s(4)) 
        height: width; radius: width / 2
        color: root.colorMain
        opacity: orbMa.containsMouse ? 0.25 : 0.08
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    Canvas {
        id: orbCanvas; anchors.fill: parent; rotation: 180
        Connections { target: window; function onBaseChanged() { orbCanvas.requestPaint() } }
        onPaint: {
            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
            var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
            var eA = (Math.min(100, Math.max(0, root.animVal)) / 100) * 2 * Math.PI;
            ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
            ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
            var grad = ctx.createLinearGradient(0, height, width, 0); 
            grad.addColorStop(0, root.colorMain.toString()); 
            grad.addColorStop(1, root.colorSecondary.toString());
            ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
        }
    }

    ColumnLayout {
        anchors.centerIn: parent; spacing: 0
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
            Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: root.colorMain; text: root.iconText }
            Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: root.valueText }
        }
        Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: root.labelText }
    }

    MouseArea { id: orbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
}
