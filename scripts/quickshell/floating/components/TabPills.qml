import QtQuick
import Quickshell

// Sidebar tab pills with morphing active highlight and drag-to-evaluate gestures
Item {
    id: root

    required property var fw
    required property var mocha
    required property var mainHitArea
    required property var s

    anchors.fill: parent
    anchors.margins: s(8)

    // Sliding active highlight
    Rectangle {
        id: activeHighlight
        x: 0; width: parent.width; z: 0
        radius: s(7)
        color: mocha.mauve

        property int prevIdx: 0
        property int curIdx: fw.activeIndex

        onCurIdxChanged: {
            if (curIdx > prevIdx) { bottomAnim.duration = 200; topAnim.duration = 350; }
            else if (curIdx < prevIdx) { topAnim.duration = 200; bottomAnim.duration = 350; }
            prevIdx = curIdx;
        }

        property real targetTop:    fw.barOffsetY + fw.getTargetY(curIdx, curIdx)
        property real targetBottom: targetTop + fw.h_ac
        property real actualTop:    targetTop
        property real actualBottom: targetBottom

        Behavior on actualTop    { NumberAnimation { id: topAnim;    duration: 250; easing.type: Easing.OutExpo } }
        Behavior on actualBottom { NumberAnimation { id: bottomAnim; duration: 250; easing.type: Easing.OutExpo } }

        y:      actualTop
        height: actualBottom - actualTop
    }

    // Tab pills
    Repeater {
        model: fw.tabCount
        delegate: Rectangle {
            id: barPill
            property bool isActive:  fw.activeIndex === index
            property bool isHovered: barMouse.containsMouse
            property bool isPressed: barMouse.pressed

            x: 0; width: parent.width; z: 1
            radius: s(7)

            y: fw.barOffsetY + fw.getTargetY(index, fw.activeIndex)
            Behavior on y { enabled: !fw.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

            height: isActive ? fw.h_ac : fw.h_in
            Behavior on height { enabled: !fw.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

            color: isActive
                ? "transparent"
                : (isPressed
                    ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)
                    : (isHovered
                        ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.25)
                        : Qt.rgba(mocha.text.r,  mocha.text.g,  mocha.text.b,  0.15)))
            Behavior on color { ColorAnimation { duration: 250 } }

            scale: isActive ? 1.0 : (isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            MouseArea {
                id: barMouse
                anchors.fill: parent; hoverEnabled: true
                property real startGlobalX: 0; property real startGlobalY: 0
                property bool isDragging: false

                onEntered: { fw.hoveredBars++; hideTimer.stop(); }
                onExited:  { fw.hoveredBars = Math.max(0, fw.hoveredBars - 1); fw.kickTimer(); }

                onPressed: mouse => {
                    let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
                    startGlobalX = gp.x; startGlobalY = gp.y; isDragging = false;
                }
                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
                    if (Math.abs(gp.x - startGlobalX) > 5 || Math.abs(gp.y - startGlobalY) > 5) isDragging = true;
                    fw.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
                }
                onClicked: {
                    if (!isDragging) {
                        if (!barPill.isActive) fw.activeIndex = index;
                        else fw.isExpanded = !fw.isExpanded;
                    }
                }
            }
        }
    }
}
