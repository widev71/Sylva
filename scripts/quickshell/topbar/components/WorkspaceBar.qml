import QtQuick
import QtQuick.Effects
import Quickshell

// Workspace pills with sliding active highlight and cascade entry animation
Rectangle {
    id: root

    required property var mocha
    required property var workspacesModel
    required property bool startupCascadeFinished
    required property var s

    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.40)
    radius: s(14)
    border.width: 1
    border.color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.5)
    height: s(48)
    clip: true

    width: workspacesModel.count > 0 ? wsRow.implicitWidth + s(20) : 0

    visible: width > 0 || opacity > 0
    opacity: workspacesModel.count > 0 ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true; shadowColor: mocha.mauve
        shadowBlur: 1.0; shadowHorizontalOffset: 0; shadowVerticalOffset: 0
    }

    // Sliding active workspace highlight
    Rectangle {
        id: activeHighlight
        y: (root.height - s(32)) / 2
        height: s(32)
        radius: s(10)
        color: mocha.mauve
        z: 0

        property int prevIdx: 0
        property int curIdx: workspacesModel.activeIndex

        onCurIdxChanged: {
            if (curIdx > prevIdx) {
                rightAnim.duration = 200; leftAnim.duration = 350;
            } else if (curIdx < prevIdx) {
                leftAnim.duration = 200; rightAnim.duration = 350;
            }
            prevIdx = curIdx;
        }

        property real stepSize:   s(32) + s(6)
        property real targetLeft: wsRow.x + (curIdx * stepSize)
        property real targetRight: targetLeft + s(32)

        property real actualLeft:  targetLeft
        property real actualRight: targetRight

        Behavior on actualLeft  { NumberAnimation { id: leftAnim;  duration: 250; easing.type: Easing.OutExpo } }
        Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }

        x: actualLeft
        width: actualRight - actualLeft
        opacity: workspacesModel.count > 0 ? 1 : 0
    }

    // Workspace pills
    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: s(6)

        Repeater {
            model: root.workspacesModel
            delegate: Rectangle {
                id: wsPill
                property bool isHovered: wsPillMouse.containsMouse
                property string stateLabel: model.wsState
                property string wsName:     model.wsId

                width: s(32); height: s(32); radius: s(10)
                color: isHovered
                    ? Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)
                    : (stateLabel === "occupied"
                        ? Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)
                        : "transparent")

                scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                Behavior on color { ColorAnimation { duration: 250 } }

                // Cascade entry animation
                property bool initAnimTrigger: false
                opacity: initAnimTrigger ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: wsPill.initAnimTrigger ? 0 : s(15)
                    Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                }
                Component.onCompleted: {
                    if (!root.startupCascadeFinished) {
                        animTimer.interval = index * 60;
                        animTimer.start();
                    } else {
                        initAnimTrigger = true;
                    }
                }
                Timer { id: animTimer; running: false; repeat: false; onTriggered: wsPill.initAnimTrigger = true }

                Text {
                    anchors.centerIn: parent
                    text: wsName
                    font.family: "JetBrains Mono"; font.pixelSize: s(14)
                    font.weight: stateLabel === "active" ? Font.Black
                               : (stateLabel === "occupied" ? Font.Bold : Font.Medium)
                    color: index === workspacesModel.activeIndex
                        ? mocha.crust
                        : (isHovered ? mocha.text
                            : (stateLabel === "occupied" ? mocha.text : mocha.overlay0))
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                MouseArea {
                    id: wsPillMouse; hoverEnabled: true; anchors.fill: parent
                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsName])
                }
            }
        }
    }
}
