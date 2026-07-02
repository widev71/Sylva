import QtQuick
import Quickshell

// Expand and Pin control buttons at the top/bottom of the sidebar strip
Item {
    id: root

    required property var fw
    required property var mocha
    required property var mainHitArea
    required property var s

    width:  parent.width
    height: fw.controlAreaHeight

    // ── Expand button ─────────────────────────────────────────────────
    Item {
        id: expandButton
        width: fw.buttonSize; height: fw.buttonSize
        x: (parent.width - width) / 2
        y: fw.activeEdge === "left"
            ? s(6)
            : parent.height - height - s(6)

        rotation: fw.isExpanded ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        Item {
            anchors.fill: parent
            property color iconColor: fw.isExpanded ? mocha.mauve
                : (expandMouse.pressed  ? Qt.darker(mocha.mauve, 1.2)
                : (expandMouse.containsMouse ? mocha.mauve
                : Qt.tint(mocha.base, Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.3))))

            property real pivotX: parent.width / 2 - s(4)

            // Center dot
            Rectangle {
                width: s(5); height: s(5); radius: width / 2
                color: parent.iconColor
                anchors.verticalCenter: parent.verticalCenter
                x: parent.pivotX - width / 2
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            // Upper arm
            Rectangle {
                x: parent.pivotX
                anchors.verticalCenter: parent.verticalCenter
                width: s(13); height: s(4.5); radius: height / 2
                transformOrigin: Item.Left; rotation: 42
                color: parent.iconColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            // Lower arm
            Rectangle {
                x: parent.pivotX
                anchors.verticalCenter: parent.verticalCenter
                width: s(13); height: s(4.5); radius: height / 2
                transformOrigin: Item.Left; rotation: -42
                color: parent.iconColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            id: expandMouse
            anchors.fill: parent; hoverEnabled: true
            property real startGlobalX: 0; property real startGlobalY: 0
            property bool isDragging: false

            onEntered: hideTimer.stop()
            onExited:  fw.kickTimer()
            onPressed: function(mouse) {
                let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
                startGlobalX = gp.x; startGlobalY = gp.y; isDragging = false;
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return;
                let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
                if (Math.abs(gp.x - startGlobalX) > 5 || Math.abs(gp.y - startGlobalY) > 5) isDragging = true;
                fw.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
            }
            onClicked: { if (!isDragging) { fw.isExpanded = !fw.isExpanded; fw.kickTimer(); } }
        }
    }

    // ── Pin button ────────────────────────────────────────────────────
    Rectangle {
        id: pinButton
        width: fw.buttonSize; height: fw.buttonSize; radius: width / 2
        x: (parent.width - width) / 2
        y: fw.activeEdge === "left"
            ? expandButton.y + expandButton.height + s(8)
            : expandButton.y - height - s(8)

        color: fw.isPinned
            ? mocha.mauve
            : (pinMouse.pressed
                ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)
                : (pinMouse.containsMouse
                    ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.25)
                    : "transparent"))
        border.width: s(2)
        border.color: fw.isPinned
            ? mocha.mauve
            : Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.2)

        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        MouseArea {
            id: pinMouse
            anchors.fill: parent; hoverEnabled: true
            property real startGlobalX: 0; property real startGlobalY: 0
            property bool isDragging: false

            onEntered: hideTimer.stop()
            onExited:  fw.kickTimer()
            onPressed: function(mouse) {
                let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
                startGlobalX = gp.x; startGlobalY = gp.y; isDragging = false;
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return;
                let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
                if (Math.abs(gp.x - startGlobalX) > 5 || Math.abs(gp.y - startGlobalY) > 5) isDragging = true;
                fw.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
            }
            onClicked: { if (!isDragging) fw.isPinned = !fw.isPinned; }
        }
    }
}
