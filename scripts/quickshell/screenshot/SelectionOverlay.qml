import QtQuick

// Four dim rectangles masking outside the selection + a tinted selection rect
Item {
    id: root
    anchors.fill: parent
    z: 1

    required property real selX
    required property real selY
    required property real selW
    required property real selH
    required property color dimColor
    required property color selectionTint
    required property color accentColor
    required property color greenColor
    required property color redColor
    required property bool isSelecting
    required property bool hasSelection
    required property bool isVideoMode
    required property bool showQrPopup
    required property bool isQrSuccess

    // ── Full dim when nothing selected ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.dimColor
        opacity: (!root.isSelecting && !root.hasSelection) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.isVideoMode
                ? "Click Record (Portal handles area selection)"
                : "Select region to capture"
            font.family: "JetBrains Mono"
            font.weight: Font.DemiBold
            font.pixelSize: 24
            color: "white"
        }
    }

    // ── Surround dim (4 rects) ────────────────────────────────────────
    Item {
        anchors.fill: parent
        opacity: (root.isSelecting || root.hasSelection) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle { x: 0;              y: 0;              width: parent.width;                              height: root.selY;                             color: root.dimColor }
        Rectangle { x: 0;              y: root.selY + root.selH; width: parent.width;               height: parent.height - (root.selY + root.selH); color: root.dimColor }
        Rectangle { x: 0;              y: root.selY;      width: root.selX;                               height: root.selH;                             color: root.dimColor }
        Rectangle { x: root.selX + root.selW; y: root.selY; width: parent.width - (root.selX + root.selW); height: root.selH;                           color: root.dimColor }
    }

    // ── Selection tint rectangle ──────────────────────────────────────
    Rectangle {
        visible: root.isSelecting || root.hasSelection
        x: root.selX; y: root.selY
        width: root.selW; height: root.selH
        color: (root.showQrPopup && root.isQrSuccess)
            ? Qt.alpha(root.greenColor, 0.15)
            : (root.isVideoMode ? Qt.alpha(root.redColor, 0.05) : root.selectionTint)
        border.color: (root.showQrPopup && root.isQrSuccess)
            ? root.greenColor
            : (root.isVideoMode ? root.redColor : root.accentColor)
        border.width: 4
        z: 5
    }
}
