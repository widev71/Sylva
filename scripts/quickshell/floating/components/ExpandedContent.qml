import QtQuick
import Quickshell

// Expanded content area: background grid blocks + module Loaders
Item {
    id: root

    required property var fw
    required property var mocha
    required property var s

    anchors.fill: parent

    opacity: fw.expandProgress
    clip: true

    // ── Ghost grid blocks ─────────────────────────────────────────────
    component EmptyBlock: Rectangle {
        radius: s(12)
        color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
        border.width: 1
        border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
        clip: true
    }

    Item {
        anchors.fill: parent
        anchors.topMargin:    s(15)
        anchors.bottomMargin: s(15)
        anchors.leftMargin:   s(15)
        anchors.rightMargin:  s(15)
        visible: fw.expandProgress > 0.01

        Item {
            anchors.centerIn: parent
            width:    fw.activeEdge === "bottom" ? parent.height : parent.width
            height:   fw.activeEdge === "bottom" ? parent.width  : parent.height
            rotation: fw.activeEdge === "right"  ? 180 : (fw.activeEdge === "bottom" ? 90 : 0)

            property real sp: s(10)
            property real cw: Math.max(0, width)
            property real ch: Math.max(0, height)

            Repeater {
                model: fw.currentLayoutTemplate
                delegate: EmptyBlock {
                    x: (modelData.x * parent.cw) + (modelData.x > 0 ? parent.sp / 2 : 0)
                    y: (modelData.y * parent.ch) + (modelData.y > 0 ? parent.sp / 2 : 0)
                    width:  (modelData.w * parent.cw) - ((modelData.x > 0 ? parent.sp / 2 : 0) + ((modelData.x + modelData.w) < 0.99 ? parent.sp / 2 : 0))
                    height: (modelData.h * parent.ch) - ((modelData.y > 0 ? parent.sp / 2 : 0) + ((modelData.y + modelData.h) < 0.99 ? parent.sp / 2 : 0))
                }
            }
        }
    }

    // ── Module Loaders ────────────────────────────────────────────────
    Repeater {
        id: moduleRepeater
        model: fw.tabModules

        delegate: Loader {
            id: contentLoader
            z: 10
            anchors.fill: parent
            anchors.topMargin:    s(15)
            anchors.bottomMargin: s(15)
            anchors.leftMargin:   s(15)
            anchors.rightMargin:  s(15)

            visible: index === fw.activeIndex && fw.expandProgress > 0.01
            source: modelData
            asynchronous: false

            // Props forwarded to loaded modules
            property var    scaleFunc:  fw.s
            property var    mochaColors: mocha
            property string activeEdge: fw.activeEdge

            property bool isCurrentTarget: index === fw.activeIndex
            property real modWidth: (status === Loader.Ready && item && item.preferredWidth !== undefined)
                                        ? item.preferredWidth : fw.baseExpandedWidth
            property real modExt:   (status === Loader.Ready && item && item.preferredExtraLength !== undefined)
                                        ? item.preferredExtraLength : fw.baseExpandedExtraLength

            property var modLayout: {
                if (status === Loader.Ready && item && item.requestedLayoutTemplate !== undefined) {
                    let req = item.requestedLayoutTemplate;
                    if (typeof req === "number") {
                        if (req === 0) return [
                            {x:0,y:0,w:0.5,h:0.5},{x:0.5,y:0,w:0.5,h:0.5},
                            {x:0,y:0.5,w:0.5,h:0.5},{x:0.5,y:0.5,w:0.5,h:0.5}
                        ];
                        return [{x:0,y:0,w:1,h:1}];
                    }
                    return req;
                }
                return [{x:0,y:0,w:1,h:1}];
            }

            function updateSizes() {
                if (!isCurrentTarget) return;
                fw.targetExpandedExtraLength = modExt;
                fw.expandedWidth             = modWidth;
                fw.expandedExtraLength       = modExt;
                fw.currentLayoutTemplate     = modLayout;
            }

            onLoaded:              updateSizes()
            onIsCurrentTargetChanged: updateSizes()
            onModWidthChanged:     updateSizes()
            onModExtChanged:       updateSizes()
            onModLayoutChanged:    updateSizes()
            Component.onCompleted: updateSizes()
        }
    }

    // ── Hover + scroll tracker ────────────────────────────────────────
    MouseArea {
        id: gridMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: hideTimer.stop()
        onExited:  { if (!sidebarDragArea.containsMouse) fw.kickTimer(); }
        onWheel: wheel => {
            let step = 0;
            if (wheel.angleDelta.y > 0) step = fw.activeEdge === "right" ? 1 : -1;
            else if (wheel.angleDelta.y < 0) step = fw.activeEdge === "right" ? -1 : 1;
            if (step !== 0)
                fw.activeIndex = Math.max(0, Math.min(fw.tabCount - 1, fw.activeIndex + step));
        }
    }
}
