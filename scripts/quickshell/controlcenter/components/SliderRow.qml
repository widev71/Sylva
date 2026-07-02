import QtQuick
import Quickshell

Item {
    id: root
    
    property string icon: ""
    property string iconColor: "#cdd6f4"
    property real iconSize: 18
    
    property real value: 0      // 0 to 100
    property string trackColor: "rgba(255, 255, 255, 0.1)"
    property string fillColor: "#89b4fa"
    
    signal valueChangedUser(real newValue)
    
    Row {
        anchors.fill: parent
        spacing: 12
        
        Text { 
            text: root.icon
            color: root.iconColor
            font.pixelSize: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
            width: root.iconSize + 4
            horizontalAlignment: Text.AlignHCenter
        }
        
        Item {
            width: parent.width - root.iconSize - 16
            height: parent.height
            
            Rectangle {
                id: track
                width: parent.width
                height: 20
                radius: height/2
                color: root.trackColor
                anchors.verticalCenter: parent.verticalCenter
                
                Rectangle {
                    width: Math.max(height, parent.width * (root.value / 100))
                    height: parent.height
                    radius: height/2
                    color: root.fillColor
                    
                    Behavior on width {
                        enabled: !sliderMouse.drag.active
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }
                }
                
                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    
                    drag.target: Item {} // Dummy target to enable drag events easily
                    drag.axis: Drag.XAxis
                    
                    function updateValue(mouseX) {
                        let pct = Math.max(0, Math.min(100, (mouseX / track.width) * 100));
                        root.valueChangedUser(pct);
                    }
                    
                    onPressed: (mouse) => updateValue(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateValue(mouse.x);
                    }
                }
            }
        }
    }
}
