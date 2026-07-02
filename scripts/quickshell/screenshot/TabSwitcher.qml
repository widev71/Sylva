import QtQuick
import QtQuick.Layouts

// Screenshot / Video mode morphing pill switcher
Item {
    id: root
    width: 110; height: 36

    required property bool isVideoMode
    required property var theme

    signal setScreenshot
    signal setVideo

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: theme.surface0

        // Morphing active highlight
        Rectangle {
            id: activeHighlight
            y: 2; height: parent.height - 4; radius: 16
            color: theme.mauve; z: 0

            property bool curVideoMode: root.isVideoMode
            onCurVideoModeChanged: {
                if (curVideoMode) { rightAnim.duration = 200; leftAnim.duration = 350; }
                else              { leftAnim.duration  = 200; rightAnim.duration = 350; }
            }

            property real targetLeft:  curVideoMode ? (parent.width / 2) : 2
            property real targetRight: targetLeft + (parent.width / 2) - 2
            property real actualLeft:  targetLeft
            property real actualRight: targetRight

            Behavior on actualLeft  { NumberAnimation { id: leftAnim;  duration: 250; easing.type: Easing.OutExpo } }
            Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }

            x: actualLeft
            width: actualRight - actualLeft
        }

        // Tab icons
        Row {
            anchors.fill: parent; z: 1

            Item {
                width: parent.width / 2; height: parent.height
                Text {
                    anchors.centerIn: parent
                    font.family: "Iosevka Nerd Font"
                    text: "󰄄"
                    color: !root.isVideoMode ? theme.crust : theme.text
                    font.pixelSize: 16
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setScreenshot() }
            }
            Item {
                width: parent.width / 2; height: parent.height
                Text {
                    anchors.centerIn: parent
                    font.family: "Iosevka Nerd Font"
                    text: "󰕧"
                    color: root.isVideoMode ? theme.crust : theme.text
                    font.pixelSize: 16
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setVideo() }
            }
        }
    }
}
