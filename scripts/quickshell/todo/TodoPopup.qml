import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

Item {
    id: window

    property var layoutData: null
    property real uiScale: 1.0
    function s(val) { return Math.round(val * uiScale) }
    

    
    MatugenColors { id: theme }
    readonly property color base: theme.base
    readonly property color mantle: theme.mantle
    readonly property color crust: theme.crust
    readonly property color text: theme.text
    readonly property color subtext0: theme.subtext0
    readonly property color surface0: theme.surface0
    readonly property color surface1: theme.surface1
    readonly property color surface2: theme.surface2
    readonly property color green: theme.green
    readonly property color red: theme.red


    Item {
        anchors.fill: parent

        Rectangle {
            id: todoRect
            anchors.fill: parent
            radius: s(12)
            color: Qt.rgba(window.mantle.r, window.mantle.g, window.mantle.b, 0.95)
            border.color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.8)
            border.width: 1

            property var todos: []
            property string backendScript: "~/.config/hypr/scripts/quickshell/calendar/todo_backend.py"

            function loadTodos() {
                Quickshell.exec(["bash", "-c", "python3 " + backendScript + " get"], function(result) {
                    try {
                        todoRect.todos = JSON.parse(result.stdout);
                    } catch(e) {}
                });
            }
            
            function addTodo(txt) {
                Quickshell.exec(["bash", "-c", "python3 " + backendScript + " add '" + txt.replace(/'/g, "'\\''") + "'"], function(result) {
                    loadTodos();
                });
            }

            function toggleTodo(idx) {
                Quickshell.exec(["bash", "-c", "python3 " + backendScript + " toggle " + idx], function(result) {
                    loadTodos();
                });
            }

            function deleteTodo(idx) {
                Quickshell.exec(["bash", "-c", "python3 " + backendScript + " delete " + idx], function(result) {
                    loadTodos();
                });
            }

            Component.onCompleted: loadTodos()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: s(16)
                spacing: s(12)

                Text {
                    text: "To-Do List"
                    font.family: "Inter"
                    font.weight: Font.ExtraBold
                    font.pixelSize: s(16)
                    color: window.text
                }

                ListView {
                    id: todoList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: s(8)
                    model: todoRect.todos

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: s(36)
                        radius: s(8)
                        color: todoMa.containsMouse ? Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.8) : "transparent"
                        border.color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                        border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: s(8)
                            spacing: s(10)

                            Rectangle {
                                width: s(18)
                                height: s(18)
                                radius: s(4)
                                color: modelData.done ? window.green : "transparent"
                                border.color: modelData.done ? window.green : window.surface2
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: s(12)
                                    color: window.base
                                    visible: modelData.done
                                }
                            }

                            Text {
                                text: modelData.text
                                font.family: "Inter"
                                font.pixelSize: s(13)
                                color: modelData.done ? window.subtext0 : window.text
                                font.strikeout: modelData.done
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                text: ""
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: s(14)
                                color: delMa.containsMouse ? window.red : window.subtext0
                                visible: todoMa.containsMouse
                                
                                MouseArea {
                                    id: delMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: todoRect.deleteTodo(index)
                                }
                            }
                        }
                        
                        MouseArea {
                            id: todoMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: todoRect.toggleTodo(index)
                            z: -1
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: s(40)
                    radius: s(8)
                    color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.5)
                    border.color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.8)
                    border.width: 1
                    
                    TextInput {
                        id: todoInput
                        anchors.fill: parent
                        anchors.margins: s(10)
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "Inter"
                        font.pixelSize: s(14)
                        color: window.text
                        clip: true
                        selectByMouse: true
                        
                        Text {
                            text: "Add a new task..."
                            color: Qt.alpha(window.subtext0, 0.7)
                            font: parent.font
                            visible: !parent.text && !parent.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Keys.onReturnPressed: {
                            if (text.trim() !== "") {
                                todoRect.addTodo(text.trim());
                                text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
