import QtQuick
import Quickshell

// Edge trigger hot zones: thin 1px mouse areas on left, right, bottom screen edges.
// Fires showSidebar / showPeek on the parent floatingWidget.
Item {
    id: root
    anchors.fill: parent

    required property var fw   // reference to the PanelWindow (floatingWidget)
    required property var peekShowTimer
    required property var peekHideTimer

    // ── Left edge ─────────────────────────────────────────────────────
    MouseArea {
        id: leftEdge
        x: 0; y: 0; width: 1; height: fw.height
        hoverEnabled: true
        onEntered: {
            peekHideTimer.stop();
            if (fw.isSidebarVisible || fw.pendingMode === "sidebar")
                fw.showSidebar("left", mouseY + y);
            else if (fw.isPeekVisible)
                fw.showPeek("left", mouseY + y);
            else {
                peekShowTimer.pendingShowEdge = "left";
                peekShowTimer.pendingShowPos  = mouseY + y;
                peekShowTimer.restart();
            }
        }
        onPositionChanged: mouse => {
            if (fw.isSidebarVisible || fw.pendingMode === "sidebar")
                fw.showSidebar("left", mouse.y + y);
            else if (fw.isPeekVisible)
                fw.showPeek("left", mouse.y + y);
            else
                peekShowTimer.pendingShowPos = mouse.y + y;
        }
        onExited: { peekShowTimer.stop(); peekHideTimer.restart(); }
    }

    // ── Right edge ────────────────────────────────────────────────────
    MouseArea {
        id: rightEdge
        x: fw.width - 1; y: 0; width: 1; height: fw.height
        hoverEnabled: true
        onEntered: {
            peekHideTimer.stop();
            if (fw.isSidebarVisible || fw.pendingMode === "sidebar")
                fw.showSidebar("right", mouseY + y);
            else if (fw.isPeekVisible)
                fw.showPeek("right", mouseY + y);
            else {
                peekShowTimer.pendingShowEdge = "right";
                peekShowTimer.pendingShowPos  = mouseY + y;
                peekShowTimer.restart();
            }
        }
        onPositionChanged: mouse => {
            if (fw.isSidebarVisible || fw.pendingMode === "sidebar")
                fw.showSidebar("right", mouse.y + y);
            else if (fw.isPeekVisible)
                fw.showPeek("right", mouse.y + y);
            else
                peekShowTimer.pendingShowPos = mouse.y + y;
        }
        onExited: { peekShowTimer.stop(); peekHideTimer.restart(); }
    }

    // ── Bottom edge ───────────────────────────────────────────────────
    MouseArea {
        id: bottomEdge
        x: 0; y: fw.height - 1; width: fw.width; height: 1
        hoverEnabled: true
        onEntered: {
            peekHideTimer.stop();
            if (fw.isSidebarVisible || fw.pendingMode === "sidebar")
                fw.showSidebar("bottom", mouseX + x);
            else if (fw.isPeekVisible)
                fw.showPeek("bottom", mouseX + x);
            else {
                peekShowTimer.pendingShowEdge = "bottom";
                peekShowTimer.pendingShowPos  = mouseX + x;
                peekShowTimer.restart();
            }
        }
        onPositionChanged: mouse => {
            if (fw.isSidebarVisible || fw.pendingMode === "sidebar")
                fw.showSidebar("bottom", mouse.x + x);
            else if (fw.isPeekVisible)
                fw.showPeek("bottom", mouse.x + x);
            else
                peekShowTimer.pendingShowPos = mouse.x + x;
        }
        onExited: { peekShowTimer.stop(); peekHideTimer.restart(); }
    }
}
