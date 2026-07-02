import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

    Item {
        id: keybindTabRoot

        function scrollToBottom() {
            keybindFlickable.contentY = Math.max(0, keybindsColLayout.implicitHeight - keybindFlickable.height + root.s(100));
        }
        function scrollTo(y) {
            let maxY = Math.max(0, keybindFlickable.contentHeight - keybindFlickable.height);
            keybindFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
        }
        function scrollToBox(approxItemY) {
            let viewH = keybindFlickable.height;
            let itemTop = approxItemY;
            let itemBottom = approxItemY + root.s(56);
            let curY = keybindFlickable.contentY;
            let maxY = Math.max(0, keybindFlickable.contentHeight - viewH);
            if (itemTop < curY + root.s(10)) {
                keybindFlickable.contentY = Math.max(0, itemTop - root.s(20));
            } else if (itemBottom > curY + viewH - root.s(10)) {
                keybindFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
            }
        }

        Flickable {
            id: keybindFlickable
            anchors.fill: parent
            contentWidth: width
            contentHeight: keybindsColLayout.implicitHeight + root.s(100)
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

            ColumnLayout {
                id: keybindsColLayout
                width: parent.width
                spacing: root.s(8)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: wsCol.implicitHeight + root.s(32)
                    radius: root.s(12)
                    color: root.surface0
                    border.color: root.surface1; border.width: 1
                    ColumnLayout {
                        id: wsCol
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        spacing: root.s(10)
                        Text { text: "Workspaces (SUPER + 1-9)"; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(12); color: root.text; Layout.alignment: Qt.AlignVCenter }
                        Flow {
                            Layout.fillWidth: true; spacing: root.s(7)
                            Repeater {
                                model: 9
                                Rectangle {
                                    property int wsNum: index + 1
                                    width: root.s(30); height: root.s(30); radius: root.s(6)
                                    color: wsMa.containsMouse ? root.peach : root.surface1
                                    border.color: wsMa.containsMouse ? root.peach : "transparent"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Text {
                                        anchors.centerIn: parent; text: parent.wsNum
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11)
                                        color: wsMa.containsMouse ? root.base : root.peach
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    MouseArea { id: wsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", wsNum.toString()]) }
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: kbListView
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    implicitHeight: dynamicKeybindsModel.count * root.s(56) + root.s(20)
                    model: dynamicKeybindsModel
                    interactive: false
                    cacheBuffer: root.s(2000)
                    displayMarginBeginning: root.s(100)
                    displayMarginEnd: root.s(100)
                    spacing: root.s(8)

                    delegate: Rectangle {
                        id: kbRowRect
                        property int outerIndex: index 
                        property bool isJumpHighlighted: root.highlightedBox === outerIndex
                        
                        property bool layoutReady: false
                        Component.onCompleted: Qt.callLater(() => layoutReady = true)

                        width: kbListView.width
                        height: root.s(44) + (model.isEditing ? editPanel.implicitHeight + root.s(12) : 0)
                        radius: root.s(8)

                        HoverHandler { id: rowHover }
                        property bool isHovered: rowHover.hovered || model.isEditing || isJumpHighlighted
                        property bool isTypeOpen: false
                        property bool isDispOpen: false

                        color: isJumpHighlighted ? root.surface1 : (isHovered ? root.surface1 : root.surface0)
                        border.color: isJumpHighlighted ? root.peach : (isHovered ? Qt.alpha(root.peach, 0.5) : root.surface1)
                        border.width: isJumpHighlighted ? 2 : 1

                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        MouseArea { anchors.fill: parent; z: -2; onClicked: root.highlightedBox = outerIndex; }

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(10)

                            Item {
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(24); clip: true

                                Row {
                                    id: modKeyContainer
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: root.s(5)
                                    Rectangle {
                                        width: k1Text.implicitWidth + root.s(10); height: root.s(24); radius: root.s(4)
                                        color: root.surface1
                                        border.color: root.surface2; border.width: 1
                                        visible: model.mods !== ""
                                        Text {
                                            id: k1Text; anchors.centerIn: parent; text: model.mods
                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(9)
                                            color: root.peach
                                        }
                                    }
                                    Text {
                                        text: "+"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10)
                                        color: root.overlay0
                                        visible: model.mods !== "" && model.key !== ""; anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: k2Text.implicitWidth + root.s(10); height: root.s(24); radius: root.s(4)
                                        color: root.surface1
                                        border.color: root.surface2; border.width: 1
                                        visible: model.key !== ""
                                        Text {
                                            id: k2Text; anchors.centerIn: parent; text: model.key
                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(9)
                                            color: root.peach
                                        }
                                    }
                                }

                                // Edit button
                                Rectangle {
                                    id: editButtonSlide
                                    width: root.s(26); height: root.s(26); radius: root.s(6)
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: kbRowRect.isHovered ? parent.width - width : parent.width
                                    color: model.isEditing
                                        ? root.peach
                                        : (editMa.containsMouse ? root.peach : root.surface2)
                                        
                                    Behavior on x { 
                                        enabled: kbRowRect.layoutReady
                                        NumberAnimation { duration: 250; easing.type: Easing.OutQuart } 
                                    }
                                    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.isEditing ? "▴" : "󰏫"
                                        font.family: model.isEditing ? "Inter" : "Iosevka Nerd Font"
                                        font.pixelSize: root.s(13)
                                        color: model.isEditing
                                            ? root.base
                                            : (editMa.containsMouse ? root.base : root.subtext0)
                                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                                    }
                                    MouseArea { 
                                        id: editMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                        onClicked: { 
                                            dynamicKeybindsModel.setProperty(outerIndex, "isEditing", !model.isEditing); 
                                            kbRowRect.isTypeOpen = false; 
                                            kbRowRect.isDispOpen = false; 
                                            if (!model.isEditing) {
                                                root.forceActiveFocus();
                                            }
                                        } 
                                    }
                                }
                                Item {
                                    id: cmdClipRect
                                    anchors.left: modKeyContainer.right; anchors.leftMargin: root.s(8)
                                    anchors.right: editButtonSlide.left; anchors.rightMargin: root.s(6)
                                    anchors.verticalCenter: parent.verticalCenter; height: parent.height; clip: true

                                    property int marqueeSpacing: root.s(60)
                                    property bool shouldMarquee: kbRowRect.isHovered && cmdTextMain.implicitWidth > width

                                    Item {
                                        id: marqueeContainer
                                        height: parent.height
                                        width: cmdClipRect.shouldMarquee ? cmdTextMain.implicitWidth * 2 + cmdClipRect.marqueeSpacing : parent.width
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: cmdClipRect.shouldMarquee ? undefined : parent.right
                                        anchors.left: cmdClipRect.shouldMarquee ? parent.left : undefined

                                        Row {
                                            spacing: cmdClipRect.marqueeSpacing; anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: cmdClipRect.shouldMarquee ? undefined : parent.right
                                            Text {
                                                id: cmdTextMain; text: (model.dispatcher + " " + model.command).trim()
                                                font.family: "JetBrains Mono"; font.pixelSize: root.s(10)
                                                color: root.subtext0
                                            }
                                            Text {
                                                id: cmdTextClone; text: cmdTextMain.text; font: cmdTextMain.font; color: cmdTextMain.color
                                                visible: cmdClipRect.shouldMarquee
                                            }
                                        }

                                        SequentialAnimation on x {
                                            id: cmdAnim; loops: Animation.Infinite
                                            running: cmdClipRect.shouldMarquee && kbRowRect.layoutReady
                                            PauseAnimation { duration: 1500 }
                                            NumberAnimation { from: 0; to: -(cmdTextMain.implicitWidth + cmdClipRect.marqueeSpacing); duration: (cmdTextMain.implicitWidth + cmdClipRect.marqueeSpacing) * 25 }
                                            PropertyAction { target: marqueeContainer; property: "x"; value: 0 }
                                        }
                                        onXChanged: { if (!cmdClipRect.shouldMarquee && x !== 0) x = 0; }
                                    }

                                    onShouldMarqueeChanged: {
                                        if (shouldMarquee) { marqueeContainer.anchors.right = undefined; marqueeContainer.anchors.left = parent.left; marqueeContainer.x = 0; cmdAnim.restart(); }
                                        else { cmdAnim.stop(); marqueeContainer.x = 0; marqueeContainer.anchors.left = undefined; marqueeContainer.anchors.right = parent.right; }
                                    }
                                }

                                MouseArea {
                                    id: bindMa
                                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: editButtonSlide.left
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton; enabled: !model.isEditing
                                    onClicked: {
                                        if (model.dispatcher.startsWith("exec")) { Quickshell.execDetached(["bash", "-c", model.command]); }
                                        else { Quickshell.execDetached(["hyprctl", "dispatch", model.dispatcher, model.command]); }
                                    }
                                }
                            }

                            // ── Edit panel ───────────────────────────────
                            ColumnLayout {
                                id: editPanel
                                Layout.fillWidth: true; visible: model.isEditing; spacing: root.s(8); clip: true

                                // Record shortcut
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(34)
                                    radius: root.s(6)
                                    color: recordMa.pressed || captureTrap.activeFocus
                                        ? Qt.alpha(root.red, 0.12)
                                        : root.surface0
                                    border.color: recordMa.pressed || captureTrap.activeFocus
                                        ? root.red
                                        : root.surface2
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Text {
                                        anchors.centerIn: parent; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11)
                                        color: captureTrap.activeFocus ? root.red : root.text
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        text: captureTrap.activeFocus ? "Press Keys (Esc to confirm)..." : (model.mods ? model.mods + " + " : "") + (model.key || "[Click to Record Shortcut]")
                                    }
                                    MouseArea {
                                        id: recordMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { captureTrap.accumulatedMods = []; captureTrap.accumulatedKey = ""; captureTrap.forceActiveFocus(); }
                                    }
                                    Item {
                                        id: captureTrap
                                        focus: false
                                        property var accumulatedMods: []
                                        property string accumulatedKey: ""
                                        Keys.onTabPressed: (event) => { event.accepted = true; processKey(event); }
                                        Keys.onBacktabPressed: (event) => { event.accepted = true; processKey(event); }
                                        Keys.onReturnPressed: (event) => { event.accepted = true; processKey(event); }
                                        Keys.onEnterPressed: (event) => { event.accepted = true; processKey(event); }
                                        Keys.onEscapePressed: (event) => { captureTrap.focus = false; event.accepted = true; }
                                        Keys.onShortcutOverride: (event) => { event.accepted = true; }
                                        Keys.onReleased: (event) => { event.accepted = true; }
                                        Keys.onPressed: (event) => { event.accepted = true; processKey(event); }
                                        function processKey(event) {
                                            if (event.key === Qt.Key_Escape) return;
                                            let newMods = [];
                                            if (event.modifiers & Qt.MetaModifier) newMods.push("$mainMod");
                                            if (event.modifiers & Qt.ControlModifier) newMods.push("CTRL");
                                            if (event.modifiers & Qt.AltModifier) newMods.push("ALT");
                                            if (event.modifiers & Qt.ShiftModifier) newMods.push("SHIFT_L");
                                            let isModifierOnly = (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R ||
                                                                  event.key === Qt.Key_Meta || event.key === Qt.Key_Control ||
                                                                  event.key === Qt.Key_Alt || event.key === Qt.Key_Shift ||
                                                                  event.key === Qt.Key_CapsLock);
                                            if (isModifierOnly) {
                                                let mergedMods = [...captureTrap.accumulatedMods];
                                                for (let m of newMods) { if (!mergedMods.includes(m)) mergedMods.push(m); }
                                                dynamicKeybindsModel.setProperty(outerIndex, "mods", mergedMods.join(" "));
                                                captureTrap.accumulatedMods = mergedMods;
                                                return;
                                            }
                                            let k = "";
                                            if (event.key === Qt.Key_Space) k = "SPACE";
                                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) k = "RETURN";
                                            else if (event.key === Qt.Key_Tab) k = "TAB";
                                            else if (event.key === Qt.Key_Print) k = "Print";
                                            else if (event.key === Qt.Key_Left) k = "left";
                                            else if (event.key === Qt.Key_Right) k = "right";
                                            else if (event.key === Qt.Key_Up) k = "up";
                                            else if (event.key === Qt.Key_Down) k = "down";
                                            else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) { k = "F" + (event.key - Qt.Key_F1 + 1); }
                                            else if (event.text && event.text.length > 0) k = event.text.toUpperCase();
                                            else k = event.key.toString();
                                            if (captureTrap.accumulatedKey !== "") {
                                                let prevMods = model.mods ? model.mods.split(" ").filter(x => x !== "") : [];
                                                if (!prevMods.includes(captureTrap.accumulatedKey)) prevMods.push(captureTrap.accumulatedKey);
                                                for (let m of newMods) { if (!prevMods.includes(m)) prevMods.push(m); }
                                                dynamicKeybindsModel.setProperty(outerIndex, "mods", prevMods.join(" "));
                                                captureTrap.accumulatedMods = prevMods;
                                            } else {
                                                let allMods = [...captureTrap.accumulatedMods];
                                                for (let m of newMods) { if (!allMods.includes(m)) allMods.push(m); }
                                                captureTrap.accumulatedMods = allMods;
                                                dynamicKeybindsModel.setProperty(outerIndex, "mods", allMods.join(" "));
                                            }
                                            captureTrap.accumulatedKey = k;
                                            dynamicKeybindsModel.setProperty(outerIndex, "key", k);
                                        }
                                        onActiveFocusChanged: {
                                            if (!activeFocus) { accumulatedMods = []; accumulatedKey = ""; Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"]); }
                                            else { Quickshell.execDetached(["hyprctl", "dispatch", "submap", "passthru"]); }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: root.s(8); Layout.alignment: Qt.AlignTop; z: 2
                                    ColumnLayout {
                                        Layout.preferredWidth: (parent.width - root.s(8)) * 0.4; Layout.alignment: Qt.AlignTop; spacing: root.s(4)
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
                                            radius: root.s(6)
                                            scale: kbRowRect.isTypeOpen ? 1.02 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                            color: kbRowRect.isTypeOpen
                                                ? Qt.alpha(root.peach, 0.12)
                                                : root.surface0
                                            border.color: kbRowRect.isTypeOpen ? root.peach : root.surface2
                                            border.width: kbRowRect.isTypeOpen ? 2 : 1
                                            Behavior on border.color { ColorAnimation { duration: 200 } }
                                            Behavior on border.width { NumberAnimation { duration: 150 } }
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: root.s(7)
                                                Text {
                                                    text: model.type; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                                    color: kbRowRect.isTypeOpen ? root.peach : root.text; Layout.fillWidth: true
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }
                                                Text {
                                                    text: kbRowRect.isTypeOpen ? "▴" : "▾"; font.pixelSize: root.s(10)
                                                    color: kbRowRect.isTypeOpen ? root.peach : root.subtext0
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }
                                            }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { kbRowRect.isTypeOpen = !kbRowRect.isTypeOpen; kbRowRect.isDispOpen = false; } }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: kbRowRect.isTypeOpen ? root.bindTypes.length * root.s(26) : 0
                                            radius: root.s(6); color: root.surface0; clip: true
                                            border.color: root.surface1; border.width: kbRowRect.isTypeOpen ? 1 : 0
                                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                            ListView {
                                                anchors.fill: parent; model: root.bindTypes; interactive: false
                                                opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                                                delegate: Rectangle {
                                                    width: parent.width; height: root.s(26)
                                                    color: typeItemMa.containsMouse ? Qt.alpha(root.peach, 0.12) : "transparent"
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter; x: root.s(8); text: modelData
                                                        font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                                        color: model.type === modelData ? root.peach : root.text
                                                    }
                                                    MouseArea { id: typeItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dynamicKeybindsModel.setProperty(outerIndex, "type", modelData); kbRowRect.isTypeOpen = false; } }
                                                }
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.preferredWidth: (parent.width - root.s(8)) * 0.6; Layout.alignment: Qt.AlignTop; spacing: root.s(4)
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
                                            radius: root.s(6)
                                            scale: kbRowRect.isDispOpen ? 1.02 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                            color: kbRowRect.isDispOpen
                                                ? Qt.alpha(root.peach, 0.12)
                                                : root.surface0
                                            border.color: kbRowRect.isDispOpen ? root.peach : root.surface2
                                            border.width: kbRowRect.isDispOpen ? 2 : 1
                                            Behavior on border.color { ColorAnimation { duration: 200 } }
                                            Behavior on border.width { NumberAnimation { duration: 150 } }
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: root.s(7)
                                                Text {
                                                    text: model.dispatcher; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                                    color: kbRowRect.isDispOpen ? root.peach : root.text; Layout.fillWidth: true
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }
                                                Text {
                                                    text: kbRowRect.isDispOpen ? "▴" : "▾"; font.pixelSize: root.s(10)
                                                    color: kbRowRect.isDispOpen ? root.peach : root.subtext0
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }
                                            }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { kbRowRect.isDispOpen = !kbRowRect.isDispOpen; kbRowRect.isTypeOpen = false; } }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: kbRowRect.isDispOpen ? Math.min(root.s(140), root.dispatchers.length * root.s(26)) : 0
                                            radius: root.s(6); color: root.surface0; clip: true
                                            border.color: root.surface1; border.width: kbRowRect.isDispOpen ? 1 : 0
                                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                            ListView {
                                                anchors.fill: parent; model: root.dispatchers; interactive: true
                                                opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                                                ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
                                                delegate: Rectangle {
                                                    width: parent.width; height: root.s(26)
                                                    color: dispItemMa.containsMouse ? Qt.alpha(root.peach, 0.12) : "transparent"
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter; x: root.s(8); text: modelData
                                                        font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                                        color: model.dispatcher === modelData ? root.peach : root.text
                                                    }
                                                    MouseArea { id: dispItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dynamicKeybindsModel.setProperty(outerIndex, "dispatcher", modelData); kbRowRect.isDispOpen = false; } }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Command input
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(34)
                                    radius: root.s(6)
                                    color: cmdInput.activeFocus ? Qt.alpha(root.peach, 0.08) : root.surface0
                                    border.color: cmdInput.activeFocus ? root.peach : root.surface2
                                    border.width: 1; z: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    TextInput {
                                        id: cmdInput
                                        anchors.fill: parent; anchors.margins: root.s(9)
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: model.command
                                        font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                        color: root.text; clip: true; selectByMouse: true
                                        onTextChanged: dynamicKeybindsModel.setProperty(outerIndex, "command", text)
                                        Text {
                                            text: "Command arguments..."
                                            color: root.subtext0
                                            visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignRight; spacing: root.s(8); z: 0
                                    // Delete button
                                    Rectangle {
                                        Layout.preferredWidth: root.s(80); Layout.preferredHeight: root.s(30); radius: root.s(7)
                                        color: delMa.containsMouse ? root.red : root.surface1
                                        border.color: delMa.containsMouse ? root.red : Qt.alpha(root.red, 0.4)
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                                        Behavior on border.color { ColorAnimation { duration: 180 } }
                                        RowLayout {
                                            anchors.centerIn: parent; spacing: root.s(6)
                                            Text {
                                                text: "󰆴"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14)
                                                color: delMa.containsMouse ? root.base : root.red
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                            }
                                            Text {
                                                text: "Delete"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.weight: Font.Medium
                                                color: delMa.containsMouse ? root.base : root.red
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                            }
                                        }
                                        MouseArea { 
                                            id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                            onClicked: { 
                                                root.forceActiveFocus();
                                                dynamicKeybindsModel.remove(outerIndex); 
                                                root.saveAllKeybinds(); 
                                            } 
                                        }
                                    }
                                    // Save button
                                    Rectangle {
                                        Layout.preferredWidth: root.s(80); Layout.preferredHeight: root.s(30); radius: root.s(7)
                                        color: rowSaveMa.containsMouse ? root.green : root.surface1
                                        border.color: rowSaveMa.containsMouse ? root.green : Qt.alpha(root.green, 0.4)
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                                        Behavior on border.color { ColorAnimation { duration: 180 } }
                                        RowLayout {
                                            anchors.centerIn: parent; spacing: root.s(6)
                                            Text {
                                                text: "󰆓"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14)
                                                color: rowSaveMa.containsMouse ? root.base : root.green
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                            }
                                            Text {
                                                text: "Save"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.weight: Font.Medium
                                                color: rowSaveMa.containsMouse ? root.base : root.green
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                            }
                                        }
                                        MouseArea {
                                            id: rowSaveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let validationResult = root.validateKeybind(outerIndex, model.mods, model.key, model.dispatcher, model.command);
                                                if (validationResult !== "VALID") { 
                                                    Quickshell.execDetached(["notify-send", "-u", "critical", "Keybind Error", validationResult]); 
                                                    return; 
                                                }
                                                dynamicKeybindsModel.setProperty(outerIndex, "isEditing", false);
                                                root.forceActiveFocus();
                                                root.saveAllKeybinds();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 


// ── Main Panel ─────────────────────────────────────────────────────────────
Rectangle {
    id: sidebarPanel
    anchors.fill: parent
    color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.97)
    radius: root.s(16)
    border.width: 1
    border.color: Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.9)
    clip: true

    Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: root.s(16)
        color: sidebarPanel.color
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: sidebarPanel.border.color }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: sidebarPanel.border.color }
        Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: sidebarPanel.border.color }
    }

    Item {
        anchors.fill: parent
        opacity: introContent
        scale: 0.96 + (0.04 * introContent)
        transform: Translate { y: root.s(40) * (1.0 - introContent) }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.s(20)
            spacing: root.s(12)

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: root.s(10)

                Rectangle {
                    width: root.s(8); height: root.s(8); radius: root.s(4)
                    color: root.activeColor
                    layer.enabled: true
                    layer.effect: MultiEffect { blurEnabled: true; blurMax: 15; blur: 1.0; colorizationColor: root.activeColor; colorization: 1.0 }
                    Layout.alignment: Qt.AlignVCenter
                }

                Text { 
                    text: "Settings"
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    font.pixelSize: root.s(18)
                    color: root.text
                    Layout.alignment: Qt.AlignVCenter 
                }

                Rectangle {
                    visible: root.isSearchMode
                    width: root.s(26); height: root.s(26); radius: root.s(6)
                    color: closeSearchMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent"
                    border.color: closeSearchMa.containsMouse ? root.red : "transparent"; border.width: 1
                    opacity: root.isSearchMode ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "✕"; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: closeSearchMa.containsMouse ? root.red : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                    MouseArea {
                        id: closeSearchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.isSearchMode = false; root.globalSearchQuery = ""; globalSearchInput.text = ""; root.searchHighlightIndex = -1; }
                    }
                }

                Item { Layout.fillWidth: true }

                // Save button
                Rectangle {
                    id: headerSaveBtn
                    visible: root.currentTab !== 2 && root.currentTab !== 4 && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: root.s(32)
                    Layout.preferredWidth: root.s(80)

                    radius: root.s(6)
                    color: headerSaveMa.containsMouse ? Qt.alpha(root.activeColor, 0.15) : "transparent"
                    border.color: headerSaveMa.containsMouse ? root.activeColor : Qt.alpha(root.activeColor, 0.4)
                    border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    Text { 
                        anchors.centerIn: parent
                        text: "Save"
                        font.family: "JetBrains Mono"
                        font.pixelSize: root.s(13)
                        color: root.text
                    }

                    MouseArea {
                        id: headerSaveMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentTab === 0) Config.saveAppSettings();
                            else if (root.currentTab === 1) Config.saveWeatherConfig();
                            else if (root.currentTab === 3) Config.applyMonitors();
                        }
                    }
                }
                
                // Add button
                Rectangle {
                    id: headerAddBtn
                    visible: (root.currentTab === 2 || root.currentTab === 4) && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: root.s(32)
                    Layout.preferredWidth: root.s(80)

                    radius: root.s(6)
                    color: headerAddMa.containsMouse ? Qt.alpha(root.activeColor, 0.15) : "transparent"
                    border.color: headerAddMa.containsMouse ? root.activeColor : Qt.alpha(root.activeColor, 0.4)
                    border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    Text { 
                        anchors.centerIn: parent
                        text: "+ Add"
                        font.family: "JetBrains Mono"
                        font.pixelSize: root.s(13)
                        color: root.text
                    }

                    MouseArea {
                        id: headerAddMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentTab === 2) {
                                dynamicKeybindsModel.append({ type: "bind", mods: "", key: "", dispatcher: "exec", command: "", isEditing: true });
                                scrollTimer.start();
                            } else if (root.currentTab === 4) {
                                dynamicStartupModel.append({ command: "", isEditing: true });
                                startupScrollTimer.start();
                            }
                        }
                    }
                }
            }

            // ── Search bar ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: root.s(40); radius: root.s(10)
                color: root.isSearchMode
                    ? Qt.alpha(root.sapphire, 0.06)
                    : (globalSearchBarMa.containsMouse ? Qt.alpha(root.surface1, 0.6) : Qt.alpha(root.surface0, 0.5))
                border.color: root.isSearchMode ? root.sapphire : (globalSearchBarMa.containsMouse ? root.surface2 : root.surface1)
                border.width: root.isSearchMode ? 2 : 1
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
                Behavior on border.width { NumberAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: root.s(11); anchors.rightMargin: root.s(11); spacing: root.s(9)
                    Text {
                        text: "󰍉"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15)
                        color: root.isSearchMode ? root.sapphire : root.subtext0
                        Behavior on color { ColorAnimation { duration: 200 } }
                        MouseArea { anchors.fill: parent; anchors.margins: -root.s(6); hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } }
                    }
                    TextInput {
                        id: globalSearchInput
                        Layout.fillWidth: true; Layout.fillHeight: true; verticalAlignment: TextInput.AlignVCenter
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: root.text; clip: true; selectByMouse: true
                        Text {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            text: root.isSearchMode ? "Cari pengaturan & pintasan..." : "Cari"
                            color: Qt.alpha(root.subtext0, 0.45)
                            visible: !globalSearchInput.text && !globalSearchInput.activeFocus
                            font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
                        }
                        onActiveFocusChanged: { if (activeFocus && !root.isSearchMode) root.isSearchMode = true; }
                        onTextChanged: { root.globalSearchQuery = text; if (!root.isSearchMode && text.length > 0) root.isSearchMode = true; }
                        Keys.onEscapePressed: { root.isSearchMode = false; root.globalSearchQuery = ""; text = ""; root.searchHighlightIndex = -1; root.forceActiveFocus(); }
                        Keys.onDownPressed: (event) => {
                            root.forceActiveFocus();
                            let total = root.searchResultItems.length;
                            if (total === 0) { event.accepted = true; return; }
                            root.searchHighlightIndex = root.searchHighlightIndex < total - 1 ? root.searchHighlightIndex + 1 : 0;
                            root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
                            event.accepted = true;
                        }
                        Keys.onUpPressed: (event) => {
                            root.forceActiveFocus();
                            let total = root.searchResultItems.length;
                            if (total === 0) { event.accepted = true; return; }
                            root.searchHighlightIndex = root.searchHighlightIndex > 0 ? root.searchHighlightIndex - 1 : (root.searchHighlightIndex === 0 ? total - 1 : total - 1);
                            root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
                            event.accepted = true;
                        }
                        Keys.onReturnPressed: (event) => {
                            if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; }
                        }
                        Keys.onEnterPressed: (event) => {
                            if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; }
                        }
                    }
                    Rectangle {
                        visible: root.isSearchMode && globalSearchInput.text.length > 0; width: root.s(20); height: root.s(20); radius: root.s(4)
                        color: clearSearchBtnMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent"
                        border.color: clearSearchBtnMa.containsMouse ? root.red : "transparent"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: root.s(10); color: clearSearchBtnMa.containsMouse ? root.red : Qt.alpha(root.subtext0, 0.6); Behavior on color { ColorAnimation { duration: 150 } } }
                        MouseArea { id: clearSearchBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { globalSearchInput.text = ""; globalSearchInput.forceActiveFocus(); } }
                    }
                }
                MouseArea { id: globalSearchBarMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !root.isSearchMode; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } }
            }

            // ── Tab bar ───────────────────────────────────────────────────
            Item {
                id: tabBarContainer
                Layout.fillWidth: true
                Layout.preferredHeight: root.s(38)
                visible: !root.isSearchMode
                opacity: root.isSearchMode ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                clip: true

                Rectangle {
                    anchors.fill: parent; radius: root.s(10)
                    color: root.surface0; border.color: root.surface1; border.width: 1
                }

                Flickable {
                    id: tabBarFlickable
                    anchors.fill: parent
                    clip: false
                    // UX Update: Elastic boundaries feel much more native and premium than stopping dead
                    boundsBehavior: Flickable.DragAndOvershootBounds

                    // Reduced the divisor to 2.5 so tabs don't squash and it's clear the list scrolls
                    property real tabItemW: (tabBarContainer.width - root.s(6)) / (root.tabNames.length <= 3 ? 3 : 2.5)
                    contentWidth: root.tabNames.length * tabItemW + root.s(6)
                    contentHeight: height

                    // Graceful smooth scrolling animation for tab selection
                    NumberAnimation {
                        id: smoothScrollAnim
                        target: tabBarFlickable
                        property: "contentX"
                        duration: 350
                        easing.type: Easing.OutCubic
                    }

                    // UX Update: Dedicated animation for hardware scroll wheels to prevent jagged jumps
                    NumberAnimation {
                        id: wheelScrollAnim
                        target: tabBarFlickable
                        property: "contentX"
                        duration: 150
                        easing.type: Easing.OutSine
                    }

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: (event) => {
                            smoothScrollAnim.stop(); // Cancel auto-scroll if user takes control
                            
                            // UX Update: Support both vertical mice and horizontal trackpads seamlessly
                            let delta = Math.abs(event.angleDelta.x) > 0 ? event.angleDelta.x : event.angleDelta.y;
                            
                            // Calculate the target with clamping so the animation doesn't break boundaries
                            let targetX = Math.max(0, Math.min(
                                tabBarFlickable.contentWidth - tabBarFlickable.width,
                                tabBarFlickable.contentX - delta * 0.75 // 0.75 smooths out hyper-fast scroll wheels
                            ));
                            
                            wheelScrollAnim.to = targetX;
                            wheelScrollAnim.start();
                            
                            event.accepted = true;
                        }
                    }

                    Rectangle {
                        id: tabHighlightPill
                        y: root.s(3)
                        height: root.s(32)
                        radius: root.s(8)

                        property color c0: root.teal
                        property color c1: root.blue
                        property color c2: root.peach
                        property color c3: root.green
                        property color c4: root.mauve
                        property color targetColor: {
                            if (root.currentTab === 0) return c0;
                            if (root.currentTab === 1) return c1;
                            if (root.currentTab === 2) return c2;
                            if (root.currentTab === 3) return c3;
                            return c4;
                        }
                        color: targetColor
                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }

                        property int prevTab: 0
                        property int curTab: root.currentTab

                        onCurTabChanged: {
                            if (curTab > prevTab) {
                                tabRightAnim.duration = 200; tabLeftAnim.duration = 350;
                            } else if (curTab < prevTab) {
                                tabLeftAnim.duration = 200; tabRightAnim.duration = 350;
                            }
                            prevTab = curTab;
                            
                            // Graceful scrolling: center the newly selected tab
                            let tLeft = root.s(3) + curTab * tabBarFlickable.tabItemW;
                            let targetX = tLeft - (tabBarFlickable.width / 2) + (tabBarFlickable.tabItemW / 2);
                            
                            // Clamp bounds
                            targetX = Math.max(0, Math.min(tabBarFlickable.contentWidth - tabBarFlickable.width, targetX));
                            
                            smoothScrollAnim.to = targetX;
                            smoothScrollAnim.start();
                        }

                        property real targetLeft: root.s(3) + curTab * tabBarFlickable.tabItemW
                        property real targetRight: targetLeft + tabBarFlickable.tabItemW

                        property real actualLeft: targetLeft
                        property real actualRight: targetRight

                        Behavior on actualLeft { NumberAnimation { id: tabLeftAnim; duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on actualRight { NumberAnimation { id: tabRightAnim; duration: 250; easing.type: Easing.OutExpo } }

                        x: actualLeft
                        width: actualRight - actualLeft
                    }

                    Row {
                        x: root.s(3)
                        spacing: 0
                        height: tabBarFlickable.height

                        Repeater {
                            model: root.tabNames.length
                            Item {
                                width: tabBarFlickable.tabItemW
                                height: parent.height

                                property bool isActive: root.currentTab === index

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: root.s(7)
                                    Text {
                                        text: root.tabIcons[index]
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: root.s(14)
                                        color: isActive ? root.base : root.subtext0
                                        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                    }
                                    Text {
                                        text: root.tabNames[index]
                                        font.family: "JetBrains Mono"
                                        font.weight: isActive ? Font.Bold : Font.Medium
                                        font.pixelSize: root.s(12)
                                        color: isActive ? root.base : root.subtext0
                                        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.currentTab = index; root.clearHighlight(); }
                                }
                            }
                        }
                    }
                }
            }

            // ── Content area ──────────────────────────────────────────────
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                // Search results
                Flickable {
                    id: searchResultsFlickable
                    anchors.fill: parent; contentWidth: width
                    contentHeight: searchResultsCol.implicitHeight + root.s(40)
                    boundsBehavior: Flickable.StopAtBounds; clip: true
                    visible: root.isSearchMode
                    opacity: root.isSearchMode ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

                    ColumnLayout {
                        id: searchResultsCol; width: parent.width; spacing: root.s(8)

                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: root.s(80)
                            visible: root.globalSearchQuery.trim() === ""
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: root.s(8)
                                Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(30); color: Qt.alpha(root.subtext0, 0.25) }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Type to search settings & keybinds..."; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: Qt.alpha(root.subtext0, 0.35) }
                            }
                        }

                        Repeater {
                            id: settingsCardRepeater
                            model: root.allSettingsCards.length
                            delegate: Item {
                                property var card: root.allSettingsCards[index]
                                property bool matches: root.globalSearchMatches(card, root.globalSearchQuery)
                                property int searchListIndex: {
                                    let pos = 0;
                                    for (let i = 0; i < root.searchResultItems.length; i++) {
                                        if (root.searchResultItems[i].kind === "card" && root.searchResultItems[i].cardIndex === index) { pos = i; break; }
                                    }
                                    return pos;
                                }
                                property bool isSearchHighlighted: matches && root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: matches ? root.s(58) : 0
                                visible: matches; opacity: matches ? 1.0 : 0.0; clip: true
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                                Rectangle {
                                    anchors.fill: parent; radius: root.s(10)
                                    color: isSearchHighlighted
                                        ? root.surface1
                                        : (searchCardMa.containsMouse ? root.surface1 : root.surface0)
                                    border.color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.surface1)
                                    border.width: isSearchHighlighted ? 2 : 1
                                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                                    Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }

                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: root.s(12); spacing: root.s(12)
                                        Rectangle {
                                            width: root.s(32); height: root.s(32); radius: root.s(8)
                                            color: Qt.alpha(root[card.color], 0.15)
                                            border.color: Qt.alpha(root[card.color], 0.3); border.width: 1
                                            Text {
                                                anchors.centerIn: parent; text: card.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15)
                                                color: root[card.color]
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: root.s(2)
                                            Text {
                                                text: card.label; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13)
                                                color: isSearchHighlighted ? root[card.color] : root.text; Layout.fillWidth: true
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                            Text {
                                                text: card.desc; font.family: "Inter"; font.pixelSize: root.s(10)
                                                color: Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                            }
                                        }
                                        Rectangle {
                                            height: root.s(20); width: tabBadgeText.implicitWidth + root.s(12); radius: root.s(10)
                                            color: Qt.alpha(root[root.tabColors[card.tab]], 0.15)
                                            border.color: Qt.alpha(root[root.tabColors[card.tab]], 0.4); border.width: 1
                                            Text {
                                                id: tabBadgeText; anchors.centerIn: parent; text: root.tabNames[card.tab]
                                                font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
                                                color: root[root.tabColors[card.tab]]
                                            }
                                        }
                                        Text {
                                            text: "›"; font.family: "Inter"; font.pixelSize: root.s(18)
                                            color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.subtext0)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }
                                    MouseArea {
                                        id: searchCardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            jumpToSettingTimer.targetTab = card.tab;
                                            jumpToSettingTimer.targetBox = card.boxIndex;
                                            jumpToSettingTimer.start();
                                            root.currentTab = card.tab;
                                            if (card.tab === 0) root.tab0Loaded = true;
                                            else if (card.tab === 1) root.tab1Loaded = true;
                                            else if (card.tab === 2) root.tab2Loaded = true;
                                            root.isSearchMode = false;
                                            root.forceActiveFocus();
                                            globalSearchInput.text = "";
                                            root.globalSearchQuery = "";
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0) ? root.s(30) : 0
                            visible: root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0
                            opacity: visible ? 1.0 : 0.0; clip: true
                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: root.s(4); spacing: root.s(8)
                                Rectangle { width: root.s(3); height: root.s(12); radius: root.s(2); color: root.peach }
                                Text { text: "Keybinds (" + root.matchingKeybindIndices.length + " match" + (root.matchingKeybindIndices.length !== 1 ? "es" : "") + ")"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(10); color: root.peach }
                            }
                        }

                        Repeater {
                            id: keybindResultRepeater
                            model: root.matchingKeybindIndices.length
                            delegate: Item {
                                property int kbIndex: root.matchingKeybindIndices[index]
                                property var kbItem: dynamicKeybindsModel.get(kbIndex)
                                property int searchListIndex: {
                                    let nCards = 0;
                                    for (let i = 0; i < root.allSettingsCards.length; i++) {
                                        if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
                                    }
                                    return nCards + index;
                                }
                                property bool isSearchHighlighted: root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.globalSearchQuery.trim() !== "" ? root.s(54) : 0
                                visible: root.globalSearchQuery.trim() !== ""; opacity: visible ? 1.0 : 0.0; clip: true
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }

                                Rectangle {
                                    anchors.fill: parent; radius: root.s(10)
                                    color: isSearchHighlighted ? root.surface1 : (kbResultMa.containsMouse ? root.surface1 : root.surface0)
                                    border.color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.surface1)
                                    border.width: isSearchHighlighted ? 2 : 1
                                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                                    Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }

                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: root.s(11); spacing: root.s(11)
                                        Rectangle {
                                            width: root.s(32); height: root.s(32); radius: root.s(8)
                                            color: Qt.alpha(root.peach, 0.12)
                                            border.color: Qt.alpha(root.peach, 0.25); border.width: 1
                                            Text {
                                                anchors.centerIn: parent; text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15)
                                                color: root.peach
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: root.s(3)
                                            Row {
                                                spacing: root.s(4)
                                                Rectangle {
                                                    width: modsT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(4)
                                                    color: root.surface1
                                                    border.color: root.surface2; border.width: 1
                                                    visible: kbItem && kbItem.mods !== ""
                                                    Text {
                                                        id: modsT; anchors.centerIn: parent; text: kbItem ? kbItem.mods : ""
                                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(8)
                                                        color: root.peach
                                                    }
                                                }
                                                Text {
                                                    text: "+"; font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
                                                    color: root.overlay0
                                                    visible: kbItem && kbItem.mods !== "" && kbItem.key !== ""; anchors.verticalCenter: parent.verticalCenter
                                                }
                                                Rectangle {
                                                    width: keyT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(4)
                                                    color: root.surface1
                                                    border.color: root.surface2; border.width: 1
                                                    visible: kbItem && kbItem.key !== ""
                                                    Text {
                                                        id: keyT; anchors.centerIn: parent; text: kbItem ? kbItem.key : ""
                                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(8)
                                                        color: root.peach
                                                    }
                                                }
                                            }
                                            Text {
                                                text: kbItem ? (kbItem.dispatcher + " " + kbItem.command).trim() : ""
                                                font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
                                                color: isSearchHighlighted ? root.peach : Qt.alpha(root.subtext0, 0.7)
                                                elide: Text.ElideRight; Layout.fillWidth: true
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                        }
                                        Rectangle {
                                            height: root.s(20); width: kbBadgeText.implicitWidth + root.s(12); radius: root.s(10)
                                            color: Qt.alpha(root.peach, 0.12)
                                            border.color: Qt.alpha(root.peach, 0.35); border.width: 1
                                            Text {
                                                id: kbBadgeText; anchors.centerIn: parent; text: "Keybinds"
                                                font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
                                                color: root.peach
                                            }
                                        }
                                        Text {
                                            text: "›"; font.family: "Inter"; font.pixelSize: root.s(18)
                                            color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.subtext0)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }
                                    MouseArea {
                                        id: kbResultMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            jumpToSettingTimer.targetTab = 2;
                                            jumpToSettingTimer.targetBox = kbIndex;
                                            jumpToSettingTimer.start();
                                            root.currentTab = 2;
                                            root.tab2Loaded = true;
                                            root.isSearchMode = false;
                                            root.forceActiveFocus();
                                            globalSearchInput.text = "";
                                            root.globalSearchQuery = "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: generalLoader
                    anchors.fill: parent
                    active: root.tab0Loaded && Config.dataReady
                    sourceComponent: generalTabComponent
                    visible: root.currentTab === 0 && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    function focusLangInput() { if (item) item.focusLangInput(); }
                    function focusWpDirInput() { if (item) item.focusWpDirInput(); }
                    function layoutListIncrementIndex() { if (item) item.layoutListIncrementIndex(); }
                    function layoutListDecrementIndex() { if (item) item.layoutListDecrementIndex(); }
                    function acceptLayoutSelection() { if (item) item.acceptLayoutSelection(); }
                    function scrollTo(y) { if (item) item.scrollTo(y); }
                    function scrollToBox(y) { if (item) item.scrollToBox(y); }
                }

                Loader {
                    id: weatherLoader
                    anchors.fill: parent
                    active: root.tab1Loaded && Config.dataReady
                    sourceComponent: weatherTabComponent
                    visible: root.currentTab === 1 && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    function focusApiKey() { if (item) item.focusApiKey(); }
                    function focusCityId() { if (item) item.focusCityId(); }
                    function scrollTo(y) { if (item) item.scrollTo(y); }
                    function scrollToBox(y) { if (item) item.scrollToBox(y); }
                }

                Loader {
                    id: keybindLoader
                    anchors.fill: parent
                    active: root.tab2Loaded && Config.dataReady
                    sourceComponent: keybindTabComponent
                    visible: root.currentTab === 2 && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    function scrollToBottom() { if (item) item.scrollToBottom(); }
                    function scrollTo(y) { if (item) item.scrollTo(y); }
                    function scrollToBox(y) { if (item) item.scrollToBox(y); }
                }

                Loader {
                    id: startupLoader
                    anchors.fill: parent
                    active: root.tab4Loaded && Config.dataReady
                    sourceComponent: startupTabComponent
                    visible: root.currentTab === 4 && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    function scrollToBottom() { if (item) item.scrollToBottom(); }
                    function scrollTo(y) { if (item) item.scrollTo(y); }
                    function scrollToBox(y) { if (item) item.scrollToBox(y); }
                }

                Loader {
                    id: profileLoader
                    anchors.fill: parent
                    active: root.tab5Loaded && Config.dataReady
                    sourceComponent: profileTabComponent
                    visible: root.currentTab === 5 && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    function scrollToBottom() { if (item) item.scrollToBottom(); }
                    function scrollTo(y) { if (item) item.scrollTo(y); }
                    function scrollToBox(y) { if (item) item.scrollToBox(y); }
                }

                Loader {
                    id: monitorsLoader
                    anchors.fill: parent
                    active: root.tab3Loaded
                    sourceComponent: monitorsTabComponent
                    visible: root.currentTab === 3 && !root.isSearchMode
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                }
            }
        }
    }
