import QtQuick

// Four corner resize handles (circles) for the selection box
Item {
    id: root
    anchors.fill: parent

    required property real selX
    required property real selY
    required property real selW
    required property real selH
    required property color handleColor
    required property color accentColor
    required property bool hasSelection
    required property bool isSelecting
    required property bool isScanningQr
    required property bool showQrPopup
    required property bool isVideoMode

    component Handle: Rectangle {
        width: 20; height: 20; radius: 10
        color: root.handleColor
        border.color: root.accentColor
        border.width: 4
        visible: (root.hasSelection || root.isSelecting)
            && !root.isScanningQr
            && !root.showQrPopup
            && !root.isVideoMode
        z: 10
    }

    Handle { x: root.selX - width / 2;              y: root.selY - height / 2 }
    Handle { x: root.selX + root.selW - width / 2;  y: root.selY - height / 2 }
    Handle { x: root.selX - width / 2;              y: root.selY + root.selH - height / 2 }
    Handle { x: root.selX + root.selW - width / 2;  y: root.selY + root.selH - height / 2 }
}
