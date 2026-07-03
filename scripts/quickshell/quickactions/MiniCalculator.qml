//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    // =========================================================
    // --- MODULE CAPABILITIES EXPORT
    // =========================================================
    property int requestedLayoutTemplate: 1
    property bool isActiveTab: typeof isCurrentTarget !== "undefined" ? isCurrentTarget : true
    property string iconFont: "Font Awesome 6 Free Solid" 
    property string safeActiveEdge: typeof activeEdge !== "undefined" ? activeEdge : "left"

    function s(val) { return typeof scaleFunc === "function" ? scaleFunc(val) : val; }

    property real baseW: s(400) 
    property real baseL: s(420)

    property real preferredWidth: safeActiveEdge === "bottom" ? baseL + 50 : baseW
    property real preferredExtraLength: safeActiveEdge === "bottom" ? baseW : baseL

    property real counterRotation: {
        if (safeActiveEdge === "right") return 180;
        if (safeActiveEdge === "bottom") return 90;
        return 0; 
    }

    property color cBase: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.base : "#1e1e2e"
    property color cMantle: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mantle : "#181825"
    property color cSurface0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface0 : "#313244"
    property color cSurface1: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface1 : "#45475a"
    property color cText: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.text : "#cdd6f4"
    property color cSubtext0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.subtext0 : "#a6adc8"
    property color cGreen: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.green : "#a6e3a1"
    property color cMauve: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mauve : "#cba6f7"
    property color cRed: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.red : "#f38ba8"

    property string expression: ""
    property string resultStr: "0"
    
    // Intercept keyboard shortcuts
    property var interceptedShortcuts: {
        let keys = ["Return", "Enter", "Left", "Right", "Up", "Down"];
        for(let i=0; i<=9; i++) keys.push(i.toString());
        keys.push("+", "-", "*", "/", ".", "Backspace", "Escape", "=");
        return keys;
    }

    Item {
        id: orientedRoot
        anchors.centerIn: parent
        width: (root.counterRotation % 180 !== 0) ? parent.height : parent.width
        height: (root.counterRotation % 180 !== 0) ? parent.width : parent.height
        rotation: root.counterRotation
        clip: true
        
        // Grab key events unconditionally if we are active
        focus: root.isActiveTab
        
        Keys.onPressed: function(event) {
            let k = event.text;
            if (k >= "0" && k <= "9") append(k);
            else if (k === "+" || k === "-" || k === "*" || k === "/") append(" " + k + " ");
            else if (k === ".") append(".");
            else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || k === "=") calculate();
            else if (event.key === Qt.Key_Backspace) backspace();
            else if (event.key === Qt.Key_Escape) root.expression = "";
        }

        Rectangle { anchors.fill: parent; color: root.cMantle; radius: root.s(10); z: -1 }

        // Header
        Rectangle {
            id: header
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: root.s(45)
            color: root.cSurface0
            radius: root.s(10)
            
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: root.s(10); color: root.cSurface0 }
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.cSurface1 }

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.s(10)
                anchors.leftMargin: root.s(15)
                anchors.rightMargin: root.s(15)
                spacing: root.s(10)

                Text { text: "\uF1EC"; font.family: root.iconFont; font.pixelSize: root.s(16); color: root.cGreen }
                Text { text: "Calculator"; font.family: "Inter"; font.bold: true; font.pixelSize: root.s(14); color: root.cText; Layout.fillWidth: true }
            }
        }

        // Display
        Rectangle {
            id: displayRect
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.s(15)
            height: root.s(80)
            color: root.cBase
            radius: root.s(10)
            border.width: 1
            border.color: root.cSurface1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.s(10)
                spacing: 0
                
                Text {
                    Layout.fillWidth: true
                    text: root.expression === "" ? " " : root.expression
                    font.family: "Inter"
                    font.pixelSize: root.s(14)
                    color: root.cSubtext0
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
                
                Text {
                    Layout.fillWidth: true
                    text: root.resultStr
                    font.family: "Inter"
                    font.weight: Font.Bold
                    font.pixelSize: root.s(32)
                    color: root.cText
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }

        // Keypad Grid
        GridLayout {
            anchors.top: displayRect.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.s(15)
            columns: 4
            rowSpacing: root.s(8)
            columnSpacing: root.s(8)
            
            Repeater {
                model: [
                    { t: "C", c: root.cRed, a: () => { root.expression = ""; root.resultStr = "0"; } },
                    { t: "()", c: root.cSurface1, a: () => { handleParens(); } },
                    { t: "%", c: root.cSurface1, a: () => { append(" % "); } },
                    { t: "÷", c: root.cMauve, a: () => { append(" / "); } },
                    
                    { t: "7", c: root.cSurface0, a: () => { append("7"); } },
                    { t: "8", c: root.cSurface0, a: () => { append("8"); } },
                    { t: "9", c: root.cSurface0, a: () => { append("9"); } },
                    { t: "×", c: root.cMauve, a: () => { append(" * "); } },
                    
                    { t: "4", c: root.cSurface0, a: () => { append("4"); } },
                    { t: "5", c: root.cSurface0, a: () => { append("5"); } },
                    { t: "6", c: root.cSurface0, a: () => { append("6"); } },
                    { t: "−", c: root.cMauve, a: () => { append(" - "); } },
                    
                    { t: "1", c: root.cSurface0, a: () => { append("1"); } },
                    { t: "2", c: root.cSurface0, a: () => { append("2"); } },
                    { t: "3", c: root.cSurface0, a: () => { append("3"); } },
                    { t: "+", c: root.cMauve, a: () => { append(" + "); } },
                    
                    { t: "0", c: root.cSurface0, a: () => { append("0"); }, w: 2 },
                    { t: ".", c: root.cSurface0, a: () => { append("."); } },
                    { t: "=", c: root.cMauve, a: () => { calculate(); } }
                ]
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.columnSpan: modelData.w ? modelData.w : 1
                    radius: root.s(8)
                    color: ma.pressed ? root.alpha(modelData.c, 0.7) : (ma.containsMouse ? root.alpha(modelData.c, 0.9) : modelData.c)
                    border.width: 1
                    border.color: modelData.c === root.cSurface0 ? root.cSurface1 : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData.t
                        font.family: "Inter"
                        font.weight: modelData.c === root.cSurface0 ? Font.Medium : Font.Bold
                        font.pixelSize: root.s(20)
                        color: modelData.c === root.cSurface0 ? root.cText : (modelData.c === root.cSurface1 ? root.cText : root.cBase)
                    }
                    
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { orientedRoot.forceActiveFocus(); modelData.a(); }
                    }
                }
            }
        }
    }

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function append(str) {
        if (root.resultStr !== "0" && root.expression === "") {
            if ([" + ", " - ", " * ", " / ", " % "].includes(str)) {
                root.expression = root.resultStr;
            } else {
                root.resultStr = "0";
            }
        }
        root.expression += str;
    }
    
    function backspace() {
        if (root.expression.endsWith(" ")) {
            root.expression = root.expression.substring(0, root.expression.length - 3);
        } else {
            root.expression = root.expression.substring(0, root.expression.length - 1);
        }
    }
    
    function handleParens() {
        let open = (root.expression.match(/\(/g) || []).length;
        let close = (root.expression.match(/\)/g) || []).length;
        if (open > close) append(")"); else append("(");
    }
    
    function calculate() {
        if (root.expression.trim() === "") return;
        try {
            let safeExpr = root.expression.replace(/[^0-9\+\-\*\/\%\(\)\.]/g, '');
            let res = Function('"use strict";return (' + safeExpr + ')')();
            if (isNaN(res) || !isFinite(res)) throw "Error";
            
            res = Math.round(res * 100000000) / 100000000;
            root.resultStr = res.toString();
            root.expression = ""; 
        } catch (e) {
            root.resultStr = "Error";
        }
    }
}
