import QtQuick
import Quickshell

Item {
    id: root
    
    property bool isActive: false
    property string activeColor: "#89b4fa"
    property string inactiveColor: "rgba(255, 255, 255, 0.1)"
    property string activeIconColor: "#1e1e2e"
    property string inactiveIconColor: "#cdd6f4"
    
    property string icon: ""
    property real iconSize: 20
    
    signal clicked()
    
    Rectangle {
        anchors.fill: parent
        radius: width * 0.2
        color: root.isActive ? root.activeColor : root.inactiveColor
        Behavior on color { ColorAnimation { duration: 150 } }
        
        Text {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: root.iconSize
            color: root.isActive ? root.activeIconColor : root.inactiveIconColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
            
            // Hover effect overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "white"
                opacity: ma.pressed ? 0.2 : (ma.containsMouse ? 0.1 : 0)
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }
        }
    }
}
