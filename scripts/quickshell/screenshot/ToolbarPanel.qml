import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Bottom toolbar: tab switcher + audio controls + action buttons + capture circle
Item {
    id: root
    z: 30

    required property var   theme
    required property bool  isVideoMode
    required property bool  hasSelection
    required property bool  isSelecting
    required property bool  isScanningQr
    required property bool  showQrPopup
    required property bool  isMaximized
    required property real  accentColor
    required property var   micModel
    required property real  deskVol
    required property bool  deskMute
    required property real  micVol
    required property bool  micMute
    required property string micDevice
    required property var   s

    signal captureClicked(bool openEditor, bool isRecord)
    signal toggleMaximizeClicked
    signal qrScanClicked
    signal editCaptureClicked
    signal requestDeskVolChange(real v)
    signal requestDeskMuteChange(bool m)
    signal requestMicVolChange(real v)
    signal requestMicMuteChange(bool m)
    signal requestMicDeviceChange(string dev)

    property real totalHeight: s(120)
    property bool fitsOutsideBottom: false  // set by parent based on selY + selH

    visible: root.hasSelection && !root.isSelecting && !root.isScanningQr && !root.showQrPopup

    width:  Math.max(toolbarRow.width + s(64), s(340))
    height: totalHeight

    // Background card
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.85)
        border.color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.08)
        border.width: s(1)
        radius: s(24)
    }

    // ── Shared inline components ──────────────────────────────────────

    component AnimWrap: Item {
        property bool isShown: false
        property real contentWidth: 0
        property real rightPadding: s(3)
        property real targetWidth: contentWidth + rightPadding
        width: isShown ? targetWidth : 0
        height: parent.height
        opacity: isShown ? 1.0 : 0.0
        clip: true
        Behavior on width   { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
        default property alias content: internalWrapper.children
        Item { id: internalWrapper; width: parent.contentWidth; height: parent.height }
    }

    component ToolbarBtn: Rectangle {
        id: tBtn
        property string iconTxt: ""
        property string label: ""
        property bool isDanger: false
        signal clicked()
        height: s(36)
        width: label !== "" ? (txt.implicitWidth + s(36)) : s(36)
        radius: s(18)
        color: tBtn.isDanger ? theme.red : (maBtn.containsMouse ? theme.surface1 : theme.surface0)
        Behavior on color { ColorAnimation { duration: 150 } }
        RowLayout {
            anchors.centerIn: parent; spacing: s(6)
            Text { font.family: "Iosevka Nerd Font"; text: tBtn.iconTxt; color: tBtn.isDanger ? theme.crust : theme.text; font.pixelSize: s(18) }
            Text { id: txt; visible: tBtn.label !== ""; font.family: "JetBrains Mono"; font.weight: Font.DemiBold; text: tBtn.label; color: tBtn.isDanger ? theme.crust : theme.text; font.pixelSize: s(13) }
        }
        MouseArea { id: maBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tBtn.clicked() }
    }

    component AudioControl: RowLayout {
        property string iconOn: ""
        property string iconOff: ""
        property real   volumeValue: 1.0
        property bool   mutedValue: false
        property bool   hasDropdown: false
        signal volumeUpdate(real newVol)
        signal muteUpdate(bool newMute)
        signal dropdownClicked()
        spacing: s(4)

        Rectangle {
            width: s(30); height: s(30); radius: s(15)
            color: maIcon.containsMouse ? theme.surface2 : theme.surface0
            Behavior on color { ColorAnimation { duration: 150 } }
            Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: parent.parent.mutedValue ? parent.parent.iconOff : parent.parent.iconOn; color: parent.parent.mutedValue ? theme.red : theme.text; font.pixelSize: s(16) }
            MouseArea { id: maIcon; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.muteUpdate(!parent.parent.mutedValue) }
        }
        Slider {
            Layout.preferredWidth: s(60)
            from: 0.0; to: 1.0; value: parent.volumeValue
            onValueChanged: parent.volumeUpdate(value)
            background: Rectangle {
                x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                implicitWidth: s(60); implicitHeight: s(4); width: parent.availableWidth; height: implicitHeight; radius: s(2); color: theme.surface2
                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; color: parent.parent.parent.mutedValue ? theme.subtext0 : theme.mauve; radius: s(2) }
            }
            handle: Rectangle {
                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                implicitWidth: s(12); implicitHeight: s(12); radius: s(6)
                color: parent.parent.parent.mutedValue ? theme.subtext0 : theme.mauve
            }
        }
        Rectangle {
            visible: parent.hasDropdown; width: s(20); height: s(30); color: "transparent"
            Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: root.fitsOutsideBottom ? "󰅃" : "󰅀"; color: theme.text; font.pixelSize: s(16) }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.dropdownClicked() }
        }
    }

    // ── Mic dropdown ──────────────────────────────────────────────────
    Rectangle {
        id: micDropdown
        visible: false
        width: s(280)
        height: root.micModel.count === 0 ? s(40) : Math.min(s(180), root.micModel.count * s(36))
        x: -s(140)
        y: root.fitsOutsideBottom ? (root.height + s(8)) : (-height - s(8))
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.95)
        border.color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.08)
        border.width: s(1); radius: s(12); z: 50

        Text { visible: root.micModel.count === 0; anchors.centerIn: parent; text: "No Microphones (Install pulseaudio)"; color: theme.subtext0; font.pixelSize: s(12) }
        ListView {
            visible: root.micModel.count > 0; anchors.fill: parent; anchors.margins: s(4)
            model: root.micModel; clip: true
            delegate: Rectangle {
                width: ListView.view.width; height: s(32); radius: s(6)
                color: maList.containsMouse ? theme.surface0 : "transparent"
                RowLayout { anchors.fill: parent; anchors.margins: s(6); Text { text: model.devDesc; color: root.micDevice === model.devName ? theme.mauve : theme.text; font.pixelSize: s(12); elide: Text.ElideRight; Layout.fillWidth: true } }
                MouseArea { id: maList; anchors.fill: parent; hoverEnabled: true; onClicked: { root.requestMicDeviceChange(model.devName); micDropdown.visible = false } }
            }
        }
    }

    // ── Top row: buttons ──────────────────────────────────────────────
    Row {
        id: toolbarRow
        anchors.top: parent.top; anchors.topMargin: s(12)
        anchors.horizontalCenter: parent.horizontalCenter
        height: s(36); spacing: 0

        // Screenshot/Video tab switcher
        Item {
            width: s(110) + s(3); height: parent.height
            TabSwitcher {
                width: s(110); height: s(36)
                isVideoMode: root.isVideoMode
                theme: root.theme
                onSetScreenshot: root.isVideoMode = false
                onSetVideo: root.isVideoMode = true
            }
        }

        // Video-only audio controls
        AnimWrap { isShown: root.isVideoMode; contentWidth: s(2); Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: theme.surface0; radius: s(1) } }
        AnimWrap {
            isShown: root.isVideoMode; contentWidth: s(94)
            AudioControl {
                width: parent.width; height: parent.height
                iconOn: "󰓃"; iconOff: "󰓄"
                volumeValue: root.deskVol; mutedValue: root.deskMute
                onVolumeUpdate: function(v) { root.requestDeskVolChange(v) }
                onMuteUpdate:   function(m) { root.requestDeskMuteChange(m) }
            }
        }
        AnimWrap {
            isShown: root.isVideoMode; contentWidth: s(118)
            AudioControl {
                id: micAudioCtrl
                width: parent.width; height: parent.height
                iconOn: "󰍬"; iconOff: "󰍭"; hasDropdown: true
                volumeValue: root.micVol; mutedValue: root.micMute
                onVolumeUpdate: function(v) { root.requestMicVolChange(v) }
                onMuteUpdate:   function(m) { root.requestMicMuteChange(m) }
                onDropdownClicked: {
                    micDropdown.visible = !micDropdown.visible
                    micDropdown.x = mapToItem(root, 0, 0).x - s(120)
                }
            }
        }

        // Screenshot-only action buttons
        AnimWrap { isShown: !root.isVideoMode; contentWidth: s(2); Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: theme.surface0; radius: s(1) } }
        AnimWrap { isShown: !root.isVideoMode; contentWidth: s(36); ToolbarBtn { iconTxt: "󰏫"; onClicked: root.editCaptureClicked() } }
        AnimWrap { isShown: !root.isVideoMode; contentWidth: s(36); ToolbarBtn { iconTxt: "⿻"; onClicked: root.qrScanClicked() } }
        AnimWrap { isShown: !root.isVideoMode; contentWidth: s(2); Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: theme.surface0; radius: s(1) } }
        AnimWrap { isShown: !root.isVideoMode; contentWidth: s(36); ToolbarBtn { iconTxt: root.isMaximized ? "󰍉" : "󰊓"; onClicked: root.toggleMaximizeClicked() } }

        // Close
        Item {
            width: s(2) + s(3) + s(36); height: parent.height
            Row {
                anchors.verticalCenter: parent.verticalCenter; height: parent.height; spacing: s(3)
                Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: theme.surface0; radius: s(1) }
                ToolbarBtn { anchors.verticalCenter: parent.verticalCenter; iconTxt: "󰅖"; isDanger: true; onClicked: Qt.quit() }
            }
        }
    }

    // ── Bottom: capture circle + gradient lines ────────────────────────
    Item {
        anchors.bottom: parent.bottom; anchors.bottomMargin: s(12)
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width; height: s(56); z: 10

        // Left gradient wave
        Rectangle {
            height: s(4); radius: s(2)
            color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.1)
            anchors.left: parent.left; anchors.leftMargin: s(24)
            anchors.right: actionBtnContainer.left; anchors.rightMargin: s(16)
            anchors.verticalCenter: parent.verticalCenter; clip: true
            Rectangle {
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: actionArea.containsMouse ? parent.width : 0; radius: s(2)
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutExpo } }
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: root.isVideoMode ? theme.red : theme.mauve } GradientStop { position: 1.0; color: "transparent" } }
            }
        }

        // Capture circle
        Item {
            id: actionBtnContainer; width: s(56); height: width; anchors.centerIn: parent; z: 20
            Rectangle { anchors.fill: parent; radius: width/2; color: "transparent"; border.color: root.isVideoMode ? Qt.alpha(theme.red, 0.4) : Qt.alpha(theme.surface1, 0.8); border.width: s(2); Behavior on border.color { ColorAnimation { duration: 250 } } }
            Rectangle { width: actionArea.pressed ? s(32) : (actionArea.containsMouse ? s(40) : s(36)); height: width; radius: width/2; anchors.centerIn: parent; color: root.isVideoMode ? theme.red : theme.mauve; Behavior on color { ColorAnimation { duration: 250 } } Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutBack } } }
            MouseArea { id: actionArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.captureClicked(false, root.isVideoMode) }
        }

        // Right gradient wave
        Rectangle {
            height: s(4); radius: s(2)
            color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.1)
            anchors.right: parent.right; anchors.rightMargin: s(24)
            anchors.left: actionBtnContainer.right; anchors.leftMargin: s(16)
            anchors.verticalCenter: parent.verticalCenter; clip: true
            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: actionArea.containsMouse ? parent.width : 0; radius: s(2)
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutExpo } }
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: root.isVideoMode ? theme.red : theme.mauve } }
            }
        }
    }
}
