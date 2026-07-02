import QtQuick
import QtQuick.Layouts

// QR highlight boxes (bounding box per QR code found in scan)
// and floating result popup cards (text + copy + open browser)
Item {
    id: root
    anchors.fill: parent

    required property var   qrModel
    required property var   theme
    required property bool  showQrPopup
    required property bool  isSelecting
    required property var   s

    signal copyText(string text)
    signal openUrl(string url)
    signal dismiss

    // ── QR highlight bounding boxes ───────────────────────────────────
    Repeater {
        model: root.qrModel
        delegate: Rectangle {
            visible: opacity > 0
            opacity: (root.showQrPopup && model.qSuccess && model.qW > 0) ? 1.0 : 0.0
            property real pad: (root.showQrPopup && model.qSuccess) ? s(5) : 0
            x: model.qW > 0 ? (model.qX - pad) : model.qX
            y: model.qH > 0 ? (model.qY - pad) : model.qY
            width:  model.qW > 0 ? (model.qW + pad * 2) : 0
            height: model.qH > 0 ? (model.qH + pad * 2) : 0
            color: Qt.alpha(theme.green, 0.25)
            border.color: theme.green; border.width: s(3); radius: s(8); z: 34
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
            Behavior on pad     { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        }
    }

    // ── QR result popup cards ─────────────────────────────────────────
    Repeater {
        model: root.qrModel
        delegate: Rectangle {
            id: qrPopupItem
            visible: opacity > 0
            opacity: (root.showQrPopup && !root.isSelecting) ? 1.0 : 0.0
            x: model.qTargetX
            y: model.qTargetY + (model.fitsTop ? (1.0 - opacity) * s(15) : -(1.0 - opacity) * s(15))
            width:  qrPopupLayout.implicitWidth + s(32)
            height: s(52); radius: s(26)
            color: theme.base
            border.color: model.qSuccess ? theme.green : theme.red; border.width: s(2)
            property bool isHovered: maHover.containsMouse
            scale: isHovered ? 1.0 : model.qBaseScale
            z: isHovered ? 100 : (40 - index)
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
            Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            MouseArea { id: maHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

            RowLayout {
                id: qrPopupLayout
                anchors.centerIn: parent; spacing: s(8)

                Text {
                    text: model.qText
                    color: model.qSuccess ? theme.text : theme.red
                    font.family: "JetBrains Mono"; font.pixelSize: s(13); font.weight: Font.DemiBold
                    Layout.maximumWidth: s(400); Layout.leftMargin: s(8)
                    elide: Text.ElideRight; wrapMode: Text.NoWrap
                }

                Rectangle { visible: model.qSuccess; width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: theme.surface0; radius: s(1) }

                // Copy button
                Rectangle {
                    visible: model.qSuccess
                    width: s(36); height: s(36); radius: s(18)
                    color: copyMa.containsMouse ? theme.surface1 : theme.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰆏"; color: theme.text; font.pixelSize: s(18) }
                    MouseArea { id: copyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.copyText(model.qText); root.dismiss() } }
                }

                // Open URL button
                Rectangle {
                    visible: model.qSuccess && (model.qText.startsWith("http://") || model.qText.startsWith("https://"))
                    width: s(36); height: s(36); radius: s(18)
                    color: openMa.containsMouse ? theme.surface1 : theme.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰌹"; color: theme.text; font.pixelSize: s(18) }
                    MouseArea { id: openMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.openUrl(model.qText); root.dismiss() } }
                }

                Rectangle { width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: theme.surface0; radius: s(1) }

                // Close button
                Rectangle {
                    width: s(36); height: s(36); radius: s(18)
                    color: closeMa.containsMouse ? theme.red : theme.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰅖"; color: closeMa.containsMouse ? theme.crust : theme.text; font.pixelSize: s(18) }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dismiss() }
                }
            }
        }
    }
}
