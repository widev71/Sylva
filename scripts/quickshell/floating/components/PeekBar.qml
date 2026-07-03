import QtQuick
import Quickshell

// Peek bar: the drag handle that appears at screen edges before the sidebar opens.
// Dragging it inward opens the sidebar; dragging outward hides it.
Rectangle {
    id: root

    required property var fw            // floatingWidget PanelWindow
    required property var mocha
    required property var mainHitArea
    required property var peekHideTimer
    required property var leftEdgeMa    // for containsMouse checks in peekHideTimer
    required property var rightEdgeMa
    required property var bottomEdgeMa
    required property var s

    // Dimensions
    width:  fw.activeEdge === "bottom"
                ? Math.max(s(20), fw.baseSidebarH - s(20))
                : s(12)
    height: fw.activeEdge === "bottom"
                ? s(12)
                : Math.max(s(20), fw.baseSidebarH - s(20))
    radius: s(6)

    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 1.0)
    border.width: 0

    opacity: (fw.isPeekVisible && !fw.isSidebarVisible)
             ? (peekMouse.containsMouse || peekMouse.pressed ? 1.0 : 0.0) : 0.0
    scale: fw.isPeekVisible ? 1.0 : 0.6
    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

    // Visual drag feedback offset
    property real visualDragOffset: {
        if (!peekMouse.pressed) return 0;
        return Math.max(-s(15), Math.min(peekMouse.currentDragDelta, s(15)));
    }

    // X position
    x: {
        let offscreen = 0, visibleX = 0;
        if (fw.activeEdge === "left") {
            offscreen = -width - s(10);
            visibleX  = s(4);
            return (fw.isPeekVisible ? visibleX : offscreen) + visualDragOffset;
        }
        if (fw.activeEdge === "right") {
            offscreen = fw.width + s(10);
            visibleX  = fw.width - width - s(4);
            return (fw.isPeekVisible ? visibleX : offscreen) - visualDragOffset;
        }
        if (fw.activeEdge === "bottom") return fw.clampedCenterX - width / 2;
        return 0;
    }

    // Y position
    y: {
        if (fw.activeEdge === "bottom") {
            let offscreen = fw.height + s(10);
            let visibleY  = fw.height - height - s(4);
            return (fw.isPeekVisible ? visibleY : offscreen) - visualDragOffset;
        }
        if (fw.activeEdge === "left" || fw.activeEdge === "right")
            return fw.clampedCenterY - height / 2;
        return 0;
    }

    Behavior on x { enabled: !fw.disableAnim && !peekMouse.pressed; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on y { enabled: !fw.disableAnim && !peekMouse.pressed; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    // Grip indicator
    Rectangle {
        anchors.centerIn: parent
        width:  fw.activeEdge === "bottom" ? s(30) : s(4)
        height: fw.activeEdge === "bottom" ? s(4)  : s(30)
        radius: s(2)
        color: Qt.darker(mocha.mauve, 1.8)
    }

    MouseArea {
        id: peekMouse
        anchors.fill: parent
        anchors.margins: -s(15)
        hoverEnabled: true
        enabled: fw.isPeekVisible || pressed

        property real startGlobalX: 0
        property real startGlobalY: 0
        property real currentDragDelta: 0

        onEntered: { fw.isPeekVisible = true; peekHideTimer.stop(); }
        onExited:  { if (!pressed) peekHideTimer.restart(); }

        onPressed: function(mouse) {
            let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
            startGlobalX = gp.x;
            startGlobalY = gp.y;
            currentDragDelta = 0;
            fw.useGraceTimer = true;
        }

        onPositionChanged: function(mouse) {
            if (!pressed) return;
            let gp = mapToItem(root.mainHitArea, mouse.x, mouse.y);
            let delta = 0;
            if (fw.activeEdge === "left")   delta = gp.x - startGlobalX;
            else if (fw.activeEdge === "right")  delta = startGlobalX - gp.x;
            else if (fw.activeEdge === "bottom") delta = startGlobalY - gp.y;
            currentDragDelta = delta;

            if (delta > s(15) && !fw.isExpanded) {
                fw.showSidebar(fw.activeEdge, fw.currentPos);
                fw.isExpanded = true;
            } else if (delta < -s(10) && fw.isPeekVisible) {
                fw.isPeekVisible = false;
            }
        }

        onReleased: { currentDragDelta = 0; peekHideTimer.restart(); }
        onClicked:  fw.showSidebar(fw.activeEdge, fw.currentPos)
    }
}
