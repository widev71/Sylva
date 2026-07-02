import QtQuick

// Intro animation: expanding rings + lock-orb icon swap, then reveals dashboard
Item {
    id: root
    anchors.fill: parent
    z: 999

    required property var theme
    required property real sc

    signal finished

    visible: screenRoot.isPlayingIntro || opacity > 0

    // ── Rings ─────────────────────────────────────────────────────────
    Rectangle {
        id: ring3; width: 360 * sc; height: width; radius: height / 2
        anchors.centerIn: parent; color: "transparent"
        border.color: theme.mauve; border.width: Math.max(1, 1 * sc)
        scale: 0.5; opacity: 0
    }
    Rectangle {
        id: ring2; width: 300 * sc; height: width; radius: height / 2
        anchors.centerIn: parent; color: "transparent"
        border.color: theme.teal; border.width: Math.max(1, 1 * sc)
        scale: 0.8; opacity: 0
    }
    Rectangle {
        id: ring1; width: 240 * sc; height: width; radius: height / 2
        anchors.centerIn: parent; color: "transparent"
        border.color: theme.text; border.width: Math.max(1, 2 * sc)
        scale: 0.8; opacity: 0
    }

    // ── Lock orb ──────────────────────────────────────────────────────
    Item {
        id: introLockOrb; width: 150 * sc; height: width
        anchors.centerIn: parent; scale: 0; opacity: 0

        Rectangle {
            anchors.fill: parent; radius: height / 2
            color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.9)
            border.color: theme.teal; border.width: Math.max(1, 2 * sc)
        }
        Text {
            id: introIconUnlocked; anchors.centerIn: parent
            text: "󰌿"; font.family: "Iosevka Nerd Font"
            font.pixelSize: 56 * sc; color: theme.text
            opacity: 1; scale: 1; transformOrigin: Item.Center
        }
        Text {
            id: introIconLocked; anchors.centerIn: parent
            text: "󰌾"; font.family: "Iosevka Nerd Font"
            font.pixelSize: 56 * sc; color: theme.text
            opacity: 0; scale: 1.6; transformOrigin: Item.Center
        }
    }

    // ── Sequence ──────────────────────────────────────────────────────
    SequentialAnimation {
        id: introSequence

        ParallelAnimation {
            NumberAnimation { target: introLockOrb; property: "scale";   from: 0;   to: 1.0; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: introLockOrb; property: "opacity"; from: 0;   to: 1.0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring1; property: "scale";   from: 0.8; to: 1.25; duration: 250; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring1; property: "opacity"; from: 0.6; to: 0;    duration: 250 }
            NumberAnimation { target: ring2; property: "scale";   from: 0.8; to: 1.4;  duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring2; property: "opacity"; from: 0.4; to: 0;    duration: 300 }
            NumberAnimation { target: ring3; property: "scale";   from: 0.5; to: 1.5;  duration: 350; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring3; property: "opacity"; from: 0.3; to: 0;    duration: 350 }

            SequentialAnimation {
                PauseAnimation { duration: 300 }
                ParallelAnimation {
                    NumberAnimation { target: introIconUnlocked; property: "scale";   from: 1.0; to: 0.5; duration: 100; easing.type: Easing.InCubic }
                    NumberAnimation { target: introIconUnlocked; property: "opacity"; from: 1.0; to: 0;   duration: 50  }
                    NumberAnimation { target: introIconLocked;   property: "scale";   from: 1.6; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                    NumberAnimation { target: introIconLocked;   property: "opacity"; from: 0;   to: 1.0; duration: 100 }
                }
            }
        }

        PauseAnimation { duration: 50 }

        ParallelAnimation {
            NumberAnimation { target: introLockOrb; property: "scale";   to: 1.8; duration: 100; easing.type: Easing.InCubic }
            NumberAnimation { target: root;         property: "opacity"; to: 0;   duration: 100 }
        }

        ScriptAction { script: root.finished() }
    }

    function start() { introSequence.start(); }
}
