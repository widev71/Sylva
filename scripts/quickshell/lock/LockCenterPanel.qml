import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Center panel: clock, date, avatar, password input pill, and action buttons
ColumnLayout {
    id: root
    spacing: 0

    required property real sc
    required property var  d
    required property string currentUser
    required property string faceIconPath
    required property bool   isPlayingIntro
    required property bool   locked
    required property bool   authenticating
    required property bool   failed
    required property var    pwShapes

    // Suspend / reboot / poweroff signals (handled by parent)
    signal doSuspend
    signal doReboot
    signal doPoweroff

    // Password model shared with parent (TextInput must stay here for focus)
    property alias inputField: inputField
    property alias passModel:  passModel

    // ── Weather row ───────────────────────────────────────────────────
    required property string weatherIcon
    required property string weatherDesc
    required property string weatherTemp

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 18 * sc
        spacing: 8 * sc
        Text { text: weatherIcon + " " + weatherDesc.toUpperCase() + " · "; font.family: "SF Pro Display"; font.pixelSize: 11 * sc; font.letterSpacing: 2; color: d.cTextDim }
        Text { text: weatherTemp; font.family: "SF Pro Display"; font.pixelSize: 11 * sc; font.weight: Font.DemiBold; color: d.cAmber }
    }

    // ── Clock ─────────────────────────────────────────────────────────
    Text {
        id: clockText
        Layout.alignment: Qt.AlignHCenter
        font.family: "Space Grotesk, SF Pro Display, sans-serif"
        font.pixelSize: 120 * sc; font.weight: Font.Bold
        color: d.cText; font.letterSpacing: -2
    }
    Text {
        id: dateText
        Layout.alignment: Qt.AlignHCenter
        font.family: "SF Pro Display"; font.pixelSize: 12 * sc
        color: d.cTextDim; font.letterSpacing: 4
        Layout.topMargin: 10 * sc
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d2 = new Date();
            clockText.text = Qt.formatDateTime(d2, "hh:mm");
            dateText.text  = Qt.formatDateTime(d2, "dddd — dd MMM").toUpperCase();
        }
    }

    // ── Avatar ────────────────────────────────────────────────────────
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 34 * sc; Layout.bottomMargin: 10 * sc
        width: 160 * sc; height: 160 * sc; radius: 80 * sc
        color: "transparent"
        border.color: d.cLimeDim; border.width: 2 * sc

        Rectangle { id: maskItem; anchors.fill: parent; anchors.margins: 4 * sc; radius: height / 2; color: "black"; visible: false; layer.enabled: true }
        Image     { id: avatarImg; anchors.fill: maskItem; source: root.faceIconPath !== "" ? root.faceIconPath : ""; fillMode: Image.PreserveAspectCrop; visible: false }
        MultiEffect { source: avatarImg; anchors.fill: avatarImg; maskEnabled: true; maskSource: maskItem }
        Rectangle {
            anchors.fill: maskItem; radius: height / 2
            visible: avatarImg.status !== Image.Ready
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#d9a441" }
                GradientStop { position: 1.0; color: "#8a5a2b" }
            }
        }
    }

    // ── Username ──────────────────────────────────────────────────────
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.currentUser
        font.family: "SF Pro Display"; font.pixelSize: 13 * sc
        font.weight: Font.DemiBold; font.letterSpacing: 1
        color: d.cText
        Layout.bottomMargin: 22 * sc
    }

    // ── Password pill ─────────────────────────────────────────────────
    Rectangle {
        id: loginPill
        Layout.alignment: Qt.AlignHCenter
        width: 280 * sc; height: 44 * sc
        color: Qt.rgba(20/255, 26/255, 20/255, 0.6)
        border.color: d.cPanelBorder; border.width: 1; radius: 3 * sc

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16 * sc; anchors.rightMargin: 16 * sc
            spacing: 10 * sc

            Text { text: "󰌾"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13 * sc; color: d.cLimeDim }

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                // Dots for typed chars
                Row {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 4 * sc
                    Repeater {
                        model: passModel
                        delegate: Text { text: "•"; font.pixelSize: 16 * sc; color: d.cTextDim; verticalAlignment: Text.AlignVCenter }
                    }
                }
                // Placeholder + cursor
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: passModel.count === 0
                    Text {
                        text: root.failed ? "Access Denied" : (root.authenticating ? "Authenticating..." : "Enter your password")
                        font.family: "SF Pro Display"; font.pixelSize: 12 * sc; font.letterSpacing: 1
                        color: root.failed ? d.cAmber : d.cTextFaint
                    }
                    Rectangle {
                        width: 6 * sc; height: 12 * sc; color: d.cLime
                        anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 4 * sc
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.0; duration: 500 }
                            NumberAnimation { to: 0.0; duration: 10 }
                            PauseAnimation  { duration: 500 }
                            NumberAnimation { to: 1.0; duration: 10 }
                        }
                    }
                }
            }
            Text { text: "→"; font.family: "SF Pro Display"; font.pixelSize: 14 * sc; color: d.cTextDim }
        }

        // Invisible TextInput captures keystrokes
        TextInput {
            id: inputField
            anchors.fill: parent; opacity: 0
            echoMode: TextInput.Password
            enabled: !root.isPlayingIntro
            property string oldText: ""
            Component.onCompleted: forceActiveFocus()
            onActiveFocusChanged: {
                if (!activeFocus && !root.locked && !root.isPlayingIntro) forceActiveFocus();
            }
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) { text = ""; passModel.clear(); event.accepted = true; }
            }
            onAccepted: {
                if (text.length > 0 && !root.authenticating) {
                    root.authRequested(text);
                    text = ""; oldText = ""; passModel.clear();
                }
            }
            onTextChanged: {
                if (root.authenticating) return;
                if (text !== oldText) {
                    if (text.length > oldText.length) {
                        for (let i = oldText.length; i < text.length; i++)
                            passModel.append({ "charStr": text.charAt(i), "isDot": false, "shapeChar": root.pwShapes[Math.floor(Math.random() * root.pwShapes.length)] });
                    } else if (text.length < oldText.length) {
                        let diff = oldText.length - text.length;
                        for (let i = 0; i < diff; i++) passModel.remove(passModel.count - 1);
                    } else {
                        passModel.clear();
                        for (let i = 0; i < text.length; i++)
                            passModel.append({ "charStr": text.charAt(i), "isDot": false, "shapeChar": root.pwShapes[Math.floor(Math.random() * root.pwShapes.length)] });
                    }
                    oldText = text;
                }
                if (text.length > 0) root.failCleared();
            }
        }
        ListModel { id: passModel }
    }

    signal authRequested(string password)
    signal failCleared

    // ── Action buttons (suspend/reboot/poweroff) ──────────────────────
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 16 * sc
        spacing: 18 * sc

        component ActionBtn: Text {
            font.family: "Iosevka Nerd Font"; font.pixelSize: 14 * sc; color: d.cTextDim
            signal clicked()
            MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
        }
        ActionBtn { text: "󰒲"; onClicked: root.doSuspend() }
        ActionBtn { text: "󰍡"; onClicked: root.doReboot() }
        ActionBtn { text: "󰐥"; onClicked: root.doPoweroff() }
    }
}
