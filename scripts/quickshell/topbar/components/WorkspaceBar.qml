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

    // Removed sliding active highlight (replaced by Pacman)

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

                Image {
                    anchors.centerIn: parent
                    source: stateLabel === "active" 
                            ? "file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/assets/workspace/pacman.png"
                            : (stateLabel === "occupied" 
                                ? "file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/assets/workspace/ghost.png"
                                : "file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/assets/workspace/empty.png")
                    width: stateLabel === "active" ? s(22) : (stateLabel === "occupied" ? s(20) : s(12))
                    height: width
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    
                    // Simple rotation animation for pacman
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                }
                MouseArea {
                    id: wsPillMouse; hoverEnabled: true; anchors.fill: parent
                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsName])
                }
            }
        }
    }
}
