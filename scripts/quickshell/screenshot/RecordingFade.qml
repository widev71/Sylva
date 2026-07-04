import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    // Mode can be "in" (fade from black to transparent) or "out" (fade from transparent to black)
    property bool isFadeOut: Quickshell.env("FADE_MODE") === "out"

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay
                exclusionMode: ExclusionMode.Ignore
                
                Rectangle {
                anchors.fill: parent
                color: "black"
                
                // If FADE_MODE=out, start transparent, end black.
                // If FADE_MODE=in, start black, end transparent.
                opacity: isFadeOut ? 0.0 : 1.0
                
                Behavior on opacity { 
                    NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } 
                }
                
                Component.onCompleted: {
                    // Trigger the animation on next event loop tick
                    Qt.callLater(() => {
                        opacity = isFadeOut ? 1.0 : 0.0;
                    });
                }
            }
        }
    }
    }

    // Auto-close after the animation finishes
    Timer {
        interval: 700
        running: true
        onTriggered: Qt.quit()
    }
}
