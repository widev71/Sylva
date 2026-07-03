import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "./floating/components"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: floatingWidget
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "qs-floating-overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors { top: false; bottom: true; left: true; right: true }
            implicitHeight: floatingWidget.screen.height - 60

            focusable: isSidebarVisible && (!isPinned || mainHoverTracker.hovered)

            // ── Scaler + Theming ───────────────────────────────────────
            Scaler {
                id: scaler
                currentWidth:  floatingWidget.screen.width
                currentHeight: floatingWidget.screen.height
            }
            property real baseScale: scaler.baseScale
            function s(val) { let r = scaler.s(val); return isNaN(r) ? val : r; }

            MatugenColors { id: mocha }

            // ── IPC ────────────────────────────────────────────────────
            IpcHandler {
                target: "floating"
                function setIndex(idx: string) {
                    let newIdx = parseInt(idx);
                    if (!isNaN(newIdx) && newIdx >= 0 && newIdx < floatingWidget.tabCount)
                        floatingWidget.activeIndex = newIdx;
                }
                function forceReload() { Quickshell.reload(true) }
            }

            // ── Module config ──────────────────────────────────────────
            property var tabModules: [
                "quickactions/DrawAction.qml",
                "quickactions/SystemUsage.qml",
                "quickactions/Timer.qml",
                "quickactions/StickyNotes.qml",
                "quickactions/MiniCalculator.qml",
                "quickactions/MiniClipboard.qml",
                "quickactions/ColorPicker.qml"
            ]
            property int tabCount: Math.max(1, tabModules.length)

            // ── Core state ─────────────────────────────────────────────
            property int    activeIndex:    0
            property bool   isExpanded:     false
            property bool   isPinned:       false
            property bool   useGraceTimer:  false
            property bool   isSidebarVisible: false
            property bool   isPeekVisible:  false
            property bool   disableAnim:    false
            property string activeEdge:     "left"
            property real   currentPos:     0
            property int    hoveredBars:    0

            onIsPinnedChanged: { if (!isPinned) kickTimer(); }

            // ── Layout math ────────────────────────────────────────────
            property real h_in:   s(32)
            property real h_ac:   s(112)
            property real itemSpacing: s(10)
            property real buttonSize:  s(19)
            property real controlAreaHeight: buttonSize * 2 + s(14)
            property real barOffsetY: activeEdge === "left" ? (controlAreaHeight + itemSpacing) : 0

            function getTargetY(idx, activeIdx) {
                let y = 0;
                for (let i = 0; i < idx; i++)
                    y += (i === activeIdx ? h_ac : h_in) + itemSpacing;
                return y;
            }

            property real baseSidebarH: {
                let count = tabCount;
                let activeTabH    = count > 0 ? h_ac : 0;
                let inactiveTabsH = Math.max(0, count - 1) * h_in;
                let tabsSpacing   = Math.max(0, count - 1) * itemSpacing;
                let controlSpacing = count > 0 ? itemSpacing : 0;
                return controlAreaHeight + controlSpacing + activeTabH + inactiveTabsH + tabsSpacing + s(16);
            }

            property real sidebarW: s(35)

            // ── Expand/morph dimensions ────────────────────────────────
            property real baseExpandedWidth:       s(378)
            property real baseExpandedExtraLength: s(224)
            property real expandedPadding:         s(15)
            property real targetExpandedExtraLength: baseExpandedExtraLength
            property real expandedWidth:       baseExpandedWidth
            property real expandedExtraLength: baseExpandedExtraLength
            property var  currentLayoutTemplate: [{x:0, y:0, w:1, h:1}]

            Behavior on expandedWidth       { enabled: !disableAnim; NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
            Behavior on expandedExtraLength { enabled: !disableAnim; NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }

            property real expandProgress:  isExpanded      ? 1.0 : 0.0
            property real visibleProgress: isSidebarVisible ? 1.0 : 0.0
            Behavior on expandProgress  { enabled: !disableAnim; NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
            Behavior on visibleProgress { enabled: !disableAnim; NumberAnimation { duration: 300; easing.type: Easing.OutExpo  } }

            property real currentExtraWidth:  (expandedWidth + expandedPadding) * expandProgress
            property real currentExtraLength: expandedExtraLength * expandProgress
            property real totalSidebarWidth:  s(35) + currentExtraWidth

            // ── Target position helpers ────────────────────────────────
            property real targetRotation: {
                if (activeEdge === "left")   return 0;
                if (activeEdge === "right")  return 180;
                if (activeEdge === "bottom") return -90;
                return 0;
            }

            property real targetEdgeMargin: {
                let length = baseSidebarH + (isExpanded ? targetExpandedExtraLength : 0);
                return (length / 2) + s(5);
            }

            function safeClamp(pos, size, margin) {
                let minC = margin, maxC = size - margin;
                if (minC <= maxC) return Math.max(minC, Math.min(maxC, pos));
                let ratio = Math.max(0, Math.min(1, pos / size));
                return minC + ratio * (maxC - minC);
            }
            property real clampedCenterX: safeClamp(currentPos, floatingWidget.width,  targetEdgeMargin)
            property real clampedCenterY: safeClamp(currentPos, floatingWidget.height, targetEdgeMargin)

            property real sidebarTargetX: {
                if (activeEdge === "left")   return 0;
                if (activeEdge === "right")  return floatingWidget.width - sidebarW;
                if (activeEdge === "bottom") return clampedCenterX - sidebarW / 2;
                return 0;
            }
            property real sidebarTargetY: {
                if (activeEdge === "left" || activeEdge === "right") return clampedCenterY - baseSidebarH / 2;
                if (activeEdge === "bottom") return floatingWidget.height - sidebarW / 2 - baseSidebarH / 2;
                return 0;
            }

            // ── Input mask ─────────────────────────────────────────────
            property var activeMaskAABB: {
                if (!isSidebarVisible) return Qt.rect(0, 0, 0, 0);
                let cw = sidebarContainer.width, ch = sidebarContainer.height;
                let cx = sidebarContainer.x + cw / 2, cy = sidebarContainer.y + ch / 2;
                let innerW = sidebarW + currentExtraWidth;
                let innerH = baseSidebarH + currentExtraLength;
                let buf = s(15);
                let relMinX = -cw / 2 - buf, relMaxX = -cw / 2 + innerW + buf;
                let relMinY = -innerH / 2 - buf, relMaxY = innerH / 2 + buf;
                let rot = targetRotation;
                if (rot === 0)   return Qt.rect(cx + relMinX, cy + relMinY, relMaxX - relMinX, relMaxY - relMinY);
                if (rot === 180) return Qt.rect(cx - relMaxX, cy - relMaxY, relMaxX - relMinX, relMaxY - relMinY);
                if (rot === -90) return Qt.rect(cx + relMinY, cy - relMaxX, relMaxY - relMinY, relMaxX - relMinX);
                let w = innerW + buf * 2, h = innerH + buf * 2;
                return Qt.rect(cx - w / 2, cy - h / 2, w, h);
            }

            mask: Region {
                Region { x: 0; y: 0; width: 1; height: floatingWidget.height }
                Region { x: floatingWidget.width - 1; y: 0; width: 1; height: floatingWidget.height }
                Region { x: 0; y: floatingWidget.height - 1; width: floatingWidget.width; height: 1 }
                Region {
                    x: floatingWidget.isPeekVisible ? peekBar.x - s(15) : 0
                    y: floatingWidget.isPeekVisible ? peekBar.y - s(15) : 0
                    width:  floatingWidget.isPeekVisible ? peekBar.width  + s(30) : 0
                    height: floatingWidget.isPeekVisible ? peekBar.height + s(30) : 0
                }
                Region {
                    x:      floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.x : 0
                    y:      floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.y : 0
                    width:  floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.width  : 0
                    height: floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.height : 0
                }
            }

            // ── Edge transition timers ─────────────────────────────────
            property string pendingEdge: ""
            property real   pendingPos: 0
            property bool   pendingWasExpanded: false
            property string pendingMode: ""

            Timer {
                id: edgeTransitionTimer; interval: 350
                onTriggered: {
                    floatingWidget.disableAnim = true;
                    floatingWidget.activeEdge  = floatingWidget.pendingEdge;
                    floatingWidget.currentPos  = floatingWidget.pendingPos;
                    teleportTimer.restart();
                }
            }
            Timer {
                id: teleportTimer; interval: 32
                onTriggered: {
                    floatingWidget.disableAnim = false;
                    if (floatingWidget.pendingMode === "sidebar") {
                        floatingWidget.isSidebarVisible = true;
                        floatingWidget.isExpanded = floatingWidget.pendingWasExpanded;
                        floatingWidget.isPeekVisible = false;
                        hideTimer.restart();
                    } else if (floatingWidget.pendingMode === "peek") {
                        floatingWidget.isPeekVisible = true;
                        floatingWidget.isSidebarVisible = false;
                        floatingWidget.isExpanded = false;
                    }
                    floatingWidget.pendingMode = "";
                }
            }

            // ── Visibility timers ──────────────────────────────────────
            Timer {
                id: peekHideTimer; interval: 50
                onTriggered: {
                    if (peekMouse.pressed) { peekHideTimer.restart(); return; }
                    if (!peekMouse.containsMouse) floatingWidget.isPeekVisible = false;
                }
            }
            Timer {
                id: hideTimer
                interval: floatingWidget.useGraceTimer ? 3000 : 800
                onTriggered: {
                    if (floatingWidget.isPinned) return;
                    if (sidebarDragArea.pressed || peekMouse.pressed || gridMouseArea.pressed) {
                        hideTimer.restart(); return;
                    }
                    floatingWidget.isExpanded = false;
                    floatingWidget.isSidebarVisible = false;
                    floatingWidget.useGraceTimer = false;
                }
            }
            Timer {
                id: peekShowTimer; interval: 300
                property string pendingShowEdge: ""
                property real   pendingShowPos: 0
                onTriggered: {
                    if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar")
                        floatingWidget.showSidebar(pendingShowEdge, pendingShowPos);
                    else
                        floatingWidget.showPeek(pendingShowEdge, pendingShowPos);
                }
            }

            // ── Focus tracker ──────────────────────────────────────────
            Item {
                id: focusTracker; focus: true
                onActiveFocusChanged: {
                    if (!activeFocus && !floatingWidget.isPinned) {
                        floatingWidget.isExpanded = false;
                        hideTimer.restart();
                    }
                }
            }

            // ── showPeek / showSidebar helpers ─────────────────────────
            function showPeek(edge, pos) {
                if (isPinned || isSidebarVisible || pendingMode === "sidebar") return;
                if (activeEdge !== edge) {
                    if (isPeekVisible || edgeTransitionTimer.running) {
                        pendingEdge = edge; pendingPos = pos; pendingMode = "peek";
                        if (!edgeTransitionTimer.running) { isPeekVisible = false; edgeTransitionTimer.restart(); }
                    } else {
                        disableAnim = true; activeEdge = edge; currentPos = pos;
                        pendingMode = "peek"; teleportTimer.restart();
                    }
                    return;
                }
                if (edgeTransitionTimer.running) { edgeTransitionTimer.stop(); pendingMode = ""; }
                currentPos = pos; isPeekVisible = true; peekHideTimer.stop();
            }

            function showSidebar(edge, pos) {
                if (isPinned) return;
                if (activeEdge !== edge) {
                    if (isSidebarVisible || isExpanded || edgeTransitionTimer.running) {
                        pendingEdge = edge; pendingPos = pos; pendingMode = "sidebar";
                        if (!edgeTransitionTimer.running) {
                            pendingWasExpanded = isExpanded; isExpanded = false;
                            isSidebarVisible = false; isPeekVisible = false;
                            edgeTransitionTimer.restart();
                        }
                    } else {
                        disableAnim = true; activeEdge = edge; currentPos = pos;
                        pendingMode = "sidebar"; pendingWasExpanded = false; teleportTimer.restart();
                    }
                    return;
                }
                if (edgeTransitionTimer.running) {
                    edgeTransitionTimer.stop();
                    if (pendingMode === "sidebar") isExpanded = pendingWasExpanded;
                    pendingMode = "";
                }
                currentPos = pos; isSidebarVisible = true; isPeekVisible = false; hideTimer.restart();
            }

            function evaluateDrag(gpStartX, gpStartY, gpMouseX, gpMouseY) {
                let delta = 0;
                if (activeEdge === "left")   delta = gpMouseX - gpStartX;
                else if (activeEdge === "right")  delta = gpStartX - gpMouseX;
                else if (activeEdge === "bottom") delta = gpStartY - gpMouseY;
                if (delta > s(30) && !isExpanded)       isExpanded = true;
                else if (delta < -s(30) && (isExpanded || isSidebarVisible)) {
                    isExpanded = false;
                    if (!isPinned) { isSidebarVisible = false; isPeekVisible = true; peekHideTimer.restart(); }
                }
            }

            function kickTimer() {
                if (!isPinned) {
                    if (mainHoverTracker.hovered || sidebarDragArea.containsMouse || sidebarDragArea.pressed
                        || gridMouseArea.containsMouse || gridMouseArea.pressed
                        || peekMouse.containsMouse || peekMouse.pressed
                        || pinMouse.containsMouse || expandMouse.containsMouse
                        || floatingWidget.hoveredBars > 0) return;
                    hideTimer.restart();
                }
            }

            function childIntercepts(sequenceStr) {
                if (!isExpanded) return false;
                if (typeof moduleRepeater !== "undefined" && activeIndex >= 0 && activeIndex < moduleRepeater.count) {
                    let loader = moduleRepeater.itemAt(activeIndex);
                    if (loader && loader.status === Loader.Ready && loader.item
                        && loader.item.interceptedShortcuts !== undefined)
                        return loader.item.interceptedShortcuts.includes(sequenceStr);
                }
                return false;
            }

            // ── Keyboard shortcuts ─────────────────────────────────────
            Shortcut { enabled: isSidebarVisible && !childIntercepts("Tab"); sequence: "Tab"; onActivated: { activeIndex = (activeIndex + 1) % tabCount; kickTimer(); } }
            Shortcut { enabled: isSidebarVisible && !childIntercepts("Shift+Tab"); sequence: "Shift+Tab"; onActivated: { activeIndex = (activeIndex + (tabCount - 1)) % tabCount; kickTimer(); } }
            Shortcut { enabled: isSidebarVisible && !childIntercepts("Return"); sequence: "Return"; onActivated: { isExpanded = !isExpanded; kickTimer(); } }
            Shortcut { enabled: isSidebarVisible && !childIntercepts("Enter");  sequence: "Enter";  onActivated: { isExpanded = !isExpanded; kickTimer(); } }
            Shortcut { enabled: isSidebarVisible && activeEdge === "bottom" && !childIntercepts("Left");  sequence: "Left";  onActivated: { activeIndex = Math.max(0, activeIndex - 1); kickTimer(); } }
            Shortcut { enabled: isSidebarVisible && activeEdge === "bottom" && !childIntercepts("Right"); sequence: "Right"; onActivated: { activeIndex = Math.min(tabCount - 1, activeIndex + 1); kickTimer(); } }
            Shortcut {
                enabled: isSidebarVisible && (activeEdge === "left" || activeEdge === "right") && !childIntercepts("Up")
                sequence: "Up"
                onActivated: { let step = activeEdge === "right" ? 1 : -1; activeIndex = Math.max(0, Math.min(tabCount - 1, activeIndex + step)); kickTimer(); }
            }
            Shortcut {
                enabled: isSidebarVisible && (activeEdge === "left" || activeEdge === "right") && !childIntercepts("Down")
                sequence: "Down"
                onActivated: { let step = activeEdge === "right" ? -1 : 1; activeIndex = Math.max(0, Math.min(tabCount - 1, activeIndex + step)); kickTimer(); }
            }
            Shortcut {
                enabled: isSidebarVisible && !childIntercepts("Escape"); sequence: "Escape"
                onActivated: {
                    if (isExpanded) { isExpanded = false; kickTimer(); }
                    else if (!isPinned) { isSidebarVisible = false; isPeekVisible = true; peekHideTimer.restart(); }
                }
            }

            // ══════════════════════════════════════════════════════════
            // UI
            // ══════════════════════════════════════════════════════════

            // Edge hot zones
            Item {
                id: mainHitArea
                anchors.fill: parent
                EdgeTriggers {
                    fw: floatingWidget
                    peekShowTimer: peekShowTimer
                    peekHideTimer: peekHideTimer
                }
            }

            // Peek handle
            PeekBar {
                id: peekBar
                fw:            floatingWidget
                mocha:         mocha
                mainHitArea:   mainHitArea
                peekHideTimer: peekHideTimer
                leftEdgeMa:    null
                rightEdgeMa:   null
                bottomEdgeMa:  null
                s:             floatingWidget.s
            }

            // Sidebar container
            Item {
                id: sidebarContainer
                width:  floatingWidget.sidebarW
                height: floatingWidget.baseSidebarH

                transformOrigin: Item.Center
                rotation: floatingWidget.targetRotation
                Behavior on rotation { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                x: {
                    if (floatingWidget.isSidebarVisible) return floatingWidget.sidebarTargetX;
                    if (floatingWidget.activeEdge === "left")  return -width - s(20);
                    if (floatingWidget.activeEdge === "right") return floatingWidget.width + s(20);
                    return floatingWidget.sidebarTargetX;
                }
                y: {
                    if (floatingWidget.isSidebarVisible) return floatingWidget.sidebarTargetY;
                    if (floatingWidget.activeEdge === "bottom") return floatingWidget.height + s(10) - floatingWidget.baseSidebarH / 2 + floatingWidget.sidebarW / 2;
                    return floatingWidget.sidebarTargetY;
                }
                Behavior on x { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                Behavior on y { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                Item {
                    id: morphOrigin
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width:  floatingWidget.sidebarW + floatingWidget.currentExtraWidth
                    height: floatingWidget.baseSidebarH + floatingWidget.currentExtraLength

                    HoverHandler {
                        id: mainHoverTracker
                        onHoveredChanged: {
                            if (hovered) { floatingWidget.useGraceTimer = false; hideTimer.stop(); }
                            else floatingWidget.kickTimer();
                        }
                    }

                    // Morphing background card
                    Rectangle {
                        id: morphingBackground
                        x: -s(15); y: 0
                        width:  s(15) + parent.width
                        height: parent.height
                        radius: s(15)
                        color:  Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.95)
                        border.width: 1
                        border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)

                        MouseArea {
                            id: sidebarDragArea
                            anchors.fill: parent
                            anchors.margins: floatingWidget.isExpanded ? -s(60) : -s(15)
                            hoverEnabled: true
                            enabled: floatingWidget.isSidebarVisible
                            property real startGlobalX: 0; property real startGlobalY: 0

                            onEntered: hideTimer.stop()
                            onExited:  { if (!pressed && !gridMouseArea.containsMouse) floatingWidget.kickTimer(); }
                            onPressed: function(mouse) {
                                let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                startGlobalX = gp.x; startGlobalY = gp.y;
                                floatingWidget.useGraceTimer = true;
                            }
                            onPositionChanged: function(mouse) {
                                if (!pressed) return;
                                let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                floatingWidget.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
                            }
                            onReleased: { if (!containsMouse) floatingWidget.kickTimer(); }
                        }
                    }

                    // Expanded content area (grid + modules)
                    Item {
                        id: expandedContainer
                        x: floatingWidget.sidebarW; y: 0
                        height: parent.height
                        width:  floatingWidget.currentExtraWidth

                        ExpandedContent {
                            id: expandedContent
                            anchors.fill: parent
                            fw:    floatingWidget
                            mocha: mocha
                            s:     floatingWidget.s
                        }
                    }

                    // Static sidebar strip (controls + tab pills)
                    Item {
                        id: staticContentWrapper
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width:  floatingWidget.sidebarW
                        height: floatingWidget.baseSidebarH

                        Item {
                            anchors.fill: parent
                            anchors.margins: s(8)

                            SidebarControls {
                                id: controlArea
                                fw:          floatingWidget
                                mocha:       mocha
                                mainHitArea: mainHitArea
                                s:           floatingWidget.s
                                width:  parent.width
                                x: 0
                                y: floatingWidget.activeEdge === "left"
                                    ? 0
                                    : floatingWidget.getTargetY(floatingWidget.tabCount, floatingWidget.activeIndex)
                                Behavior on y {
                                    enabled: !floatingWidget.disableAnim
                                    NumberAnimation { duration: 350; easing.type: Easing.OutExpo }
                                }
                            }

                            TabPills {
                                anchors.fill: parent
                                fw:          floatingWidget
                                mocha:       mocha
                                mainHitArea: mainHitArea
                                s:           floatingWidget.s
                            }
                        }
                    }
                }
            }
        }
    }
}
