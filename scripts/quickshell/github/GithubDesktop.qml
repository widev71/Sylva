import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: window
    width: 360
    height: 180
    
    // We will inherit colors from Lock.qml or define them here
    property color base: "#1e1e2e"
    property color text: "#cdd6f4"
    property color subtext0: "#a6adc8"
    property color surface0: "#313244"
    property color borderCol: Qt.rgba(166/255, 227/255, 161/255, 0.4)
    
    Rectangle {
        id: bg
        anchors.fill: parent
        color: Qt.rgba(30/255, 30/255, 46/255, 0.6)
        radius: 16
        border.color: window.borderCol
        border.width: 1
    }
    
    MultiEffect {
        source: bg
        anchors.fill: bg
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 32
        blur: 1.0
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "🐙 GitHub Activity"
                font.family: "Inter"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: window.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "@widev71"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: window.subtext0
            }
        }
        
        GridLayout {
            id: graphGrid
            Layout.alignment: Qt.AlignHCenter
            columns: 20
            rows: 7
            flow: GridLayout.TopToBottom
            columnSpacing: 4
            rowSpacing: 4
            
            Repeater {
                id: graphRepeater
                model: 140
                
                Rectangle {
                    width: 12
                    height: 12
                    radius: 3
                    
                    property int level: 0
                    
                    color: {
                        if (level === 0) return window.surface0;
                        if (level === 1) return "#0e4429";
                        if (level === 2) return "#006d32";
                        if (level === 3) return "#26a641";
                        return "#39d353";
                    }
                    
                    border.width: level > 0 ? 1 : 0
                    border.color: Qt.darker(color, 1.2)
                }
            }
        }
    }
    
    Process {
        id: fetchProc
        command: ["python3", "/home/witya/.config/hypr/scripts/quickshell/watchers/fetch_github.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    for (let i = 0; i < data.length && i < graphRepeater.count; i++) {
                        graphRepeater.itemAt(i).level = data[i].level;
                    }
                } catch(e) {}
            }
        }
    }
    
    Timer {
        interval: 3600000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            fetchProc.running = false;
            fetchProc.running = true;
        }
    }
}
