import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland

// System tray icons with cascading entry animation and context menu support
Rectangle {
    id: root

    required property var mocha
    required property bool startupCascadeFinished
    required property var barWindow
    required property var s

    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.40)
    radius: s(14)
    border.width: 1
    border.color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.5)
    height: s(48)

    property real targetWidth: trayRepeater.count > 0 ? trayRow.width + s(24) : 0
    width: targetWidth
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

    visible: targetWidth > 0
    opacity: targetWidth > 0 ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } }



    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: s(10)

        Repeater {
            id: trayRepeater
            model: SystemTray.items
            delegate: Image {
                id: trayIcon
                source: modelData.icon || ""
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(s(18), s(18))
                width: s(18); height: s(18)
                anchors.verticalCenter: parent.verticalCenter

                property bool isHovered: trayMouse.containsMouse
                property bool initAnimTrigger: false

                opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
                scale:   initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                Component.onCompleted: {
                    if (!root.startupCascadeFinished) {
                        trayAnimTimer.interval = index * 50;
                        trayAnimTimer.start();
                    } else {
                        initAnimTrigger = true;
                    }
                }
                Timer { id: trayAnimTimer; running: false; repeat: false; onTriggered: trayIcon.initAnimTrigger = true }

                QsMenuAnchor {
                    id: menuAnchor
                    anchor.window: root.barWindow
                    anchor.item: trayIcon
                    menu: modelData.menu
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent; hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: function(mouse) {
                        let cx = mouse.x;
                        let cy = mouse.y;
                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.isMenuOnly || modelData.onlyMenu) {
                                menuAnchor.open();
                            } else if (typeof modelData.activate === "function") {
                                modelData.activate();
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            if (typeof modelData.secondaryActivate === "function")
                                modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.menu) menuAnchor.open();
                            else if (typeof modelData.contextMenu === "function")
                                modelData.contextMenu(cx, cy);
                            else modelData.activate();
                        }
                    }
                }
            }
        }
    }
}
