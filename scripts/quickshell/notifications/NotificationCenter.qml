import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    property var notifModel: typeof masterWindow !== 'undefined' ? masterWindow.notifModel : null
    property var liveNotifs: typeof masterWindow !== 'undefined' ? masterWindow.liveNotifs : null

    // Ensure actionable notifications are continually bubbled to the top
    onNotifModelChanged: Qt.callLater(window.enforceNotificationSort)
    
    Connections {
        target: window.notifModel
        function onCountChanged() {
            Qt.callLater(window.enforceNotificationSort);
        }
    }

    function enforceNotificationSort() {
        if (!notifModel || notifModel.count <= 1) return;
        let firstNonAction = -1;
        for (let i = 0; i < notifModel.count; i++) {
            let item = notifModel.get(i);
            let hasAction = false;
            try {
                let parsed = item.actionsJson ? JSON.parse(item.actionsJson) : [];
                hasAction = parsed.length > 0;
            } catch(e) {}

            if (hasAction) {
                if (firstNonAction !== -1 && i > firstNonAction) {
                    notifModel.move(i, firstNonAction, 1);
                    firstNonAction++;
                }
            } else {
                if (firstNonAction === -1) {
                    firstNonAction = i;
                }
            }
        }
    }

    // Helper: Safely clear an entire group of notifications by AppName
    function clearGroup(appName) {
        if (!notifModel) return;
        for (let i = notifModel.count - 1; i >= 0; i--) {
            if (notifModel.get(i).appName === appName) {
                let uid = notifModel.get(i).uid;
                if (window.liveNotifs && window.liveNotifs[uid]) {
                    delete window.liveNotifs[uid];
                }
                notifModel.remove(i);
            }
        }
    }

    property var collapsedGroups: ({})

    function toggleGroup(groupName) {
        let temp = Object.assign({}, collapsedGroups);
        temp[groupName] = !temp[groupName];
        collapsedGroups = temp;
    }

    function isCollapsed(groupName) {
        return collapsedGroups[groupName] === true;
    }

    property bool dndEnabled: false

    property real introTop: 1.0
    property real introNotifs: 1.0

    function s(val) { return Math.round(val * 1.0); } // Fallback, will be overridden by parent if sf is passed

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color mauve: _theme.mauve
    readonly property color red: _theme.red
    readonly property color blue: _theme.blue
    readonly property color ambientPrimary: _theme.mauve
    Rectangle {
        anchors.fill: parent
        radius: window.s(20)
        color: window.base
        border.color: window.surface0 
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
                        anchors.margins: window.s(20)
                        spacing: window.s(15)

                        // --- Notification Header & DND Toggle ---
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: window.s(38)
                            spacing: window.s(12)
                            
                            transform: Translate { y: window.s(-20) * (1.0 - introTop) }
                            opacity: introTop

                            Text {
                                text: "Notifications"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: window.s(18)
                                color: window.text
                            }

                            Item { Layout.fillWidth: true } // Spacer

                            // DND Toggle Button
                            Rectangle {
                                Layout.preferredWidth: dndMa.containsMouse ? window.s(38) + dndText.implicitWidth + window.s(8) : window.s(38)
                                Layout.preferredHeight: window.s(38)
                                radius: window.s(12)
                                color: window.dndEnabled ? Qt.alpha(window.red, 0.15) : (dndMa.containsMouse ? window.surface1 : "transparent")
                                border.color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.surface2 : "transparent")
                                border.width: 1
                                clip: true

                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.right: parent.right
                                    anchors.rightMargin: window.s(10)
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: window.s(8)

                                    Text {
                                        id: dndText
                                        text: window.dndEnabled ? "Silent" : "Mute"
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: window.s(13)
                                        color: window.dndEnabled ? window.red : window.text
                                        anchors.verticalCenter: parent.verticalCenter
                                        opacity: dndMa.containsMouse ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 250 } }
                                    }

                                    Text {
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: window.s(18)
                                        color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.text : window.overlay0)
                                        text: window.dndEnabled ? "󰂛" : "󰂚"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    id: dndMa
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        window.dndEnabled = !window.dndEnabled;
                                        Quickshell.execDetached(["sh", "-c", "echo '" + (window.dndEnabled ? "1" : "0") + "' > " + paths.getCacheDir("dnd") + "/state"]);
                                    }
                                }
                            }
                        }

                        // --- Zero State ---
                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            font.pixelSize: window.s(14)
                            color: window.overlay0
                            text: "You're all caught up."
                            visible: !notifModel || notifModel.count === 0
                            opacity: introNotifs
                        }

                        // --- Notification List ---
                        ListView {
                            id: notifList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: window.notifModel
                            spacing: window.s(8)
                            clip: true
                            
                            opacity: introNotifs
                            transform: Translate { y: window.s(20) * (1 - introNotifs) }

                            ScrollBar.vertical: ScrollBar {
                                active: notifList.moving || notifList.movingVertically
                                width: window.s(4)
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle { implicitWidth: window.s(4); radius: window.s(2); color: window.surface2 }
                            }

                            // Fluid Animations
                            add: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
                                    NumberAnimation { property: "x"; from: window.s(-40); to: 0; duration: 500; easing.type: Easing.OutExpo }
                                    NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 500; easing.type: Easing.OutBack }
                                }
                            }
                            remove: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "opacity"; to: 0.0; duration: 300; easing.type: Easing.OutQuint }
                                    NumberAnimation { property: "scale"; to: 0.9; duration: 300; easing.type: Easing.OutQuint }
                                }
                            }
                            displaced: Transition {
                                NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutExpo }
                            }

                            // --- Grouping Configuration ---
                            section.property: "appName"
                            section.criteria: ViewSection.FullString
                            section.delegate: Item {
                                width: ListView.view.width
                                height: window.s(46)
                                
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: window.s(10)
                                    anchors.bottomMargin: window.s(4)
                                    color: headerMa.containsMouse ? window.surface1 : "transparent"
                                    radius: window.s(8)
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: window.s(6)
                                        anchors.rightMargin: window.s(6)
                                        spacing: window.s(8)

                                        // Clickable Area for Collapse Toggle
                                        MouseArea {
                                            id: headerMa
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: window.toggleGroup(section)

                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: window.s(8)
                                                
                                                Text {
                                                    font.family: "Iosevka Nerd Font"
                                                    font.pixelSize: window.s(14)
                                                    color: window.mauve
                                                    text: window.isCollapsed(section) ? "󰅂" : "󰅀"
                                                    Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                                }

                                                Text {
                                                    text: section.toUpperCase()
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Black
                                                    font.pixelSize: window.s(11)
                                                    color: window.text
                                                    Layout.fillWidth: true
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                            }
                                        }

                                        // Clear Group Button
                                        Rectangle {
                                            Layout.preferredWidth: window.s(26)
                                            Layout.preferredHeight: window.s(26)
                                            radius: window.s(13)
                                            color: groupClearMa.containsMouse ? window.surface2 : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: window.s(14)
                                                color: groupClearMa.containsMouse ? window.red : window.overlay0
                                                text: "󰅖"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            MouseArea {
                                                id: groupClearMa
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: window.clearGroup(section)
                                            }
                                        }
                                    }
                                }
                            }

                            // --- Individual Notification Card ---
                            delegate: Item {
                                id: delegateWrapper
                                width: ListView.view.width
                                property bool isHidden: window.isCollapsed(model.appName)
                                height: isHidden ? 0 : innerCard.height
                                visible: height > 0
                                opacity: isHidden ? 0 : 1
                                clip: true
                                
                                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

                                property var realNotif: window.liveNotifs ? window.liveNotifs[model.uid] : null

                                // Auto-clean linkage to DBus so if it's accepted via hotkey/elsewhere, it deletes here
                                Connections {
                                    target: delegateWrapper.realNotif || null
                                    function onClosed() {
                                        delegateWrapper.removeThisNotif();
                                    }
                                }

                                function removeThisNotif() {
                                    if (!window.notifModel) return;
                                    for (let i = 0; i < window.notifModel.count; i++) {
                                        if (window.notifModel.get(i).uid === model.uid) {
                                            if (window.liveNotifs && window.liveNotifs[model.uid]) {
                                                delete window.liveNotifs[model.uid];
                                            }
                                            window.notifModel.remove(i);
                                            break;
                                        }
                                    }
                                }

                                property var actionArray: {
                                    try {
                                        let parsed = model.actionsJson ? JSON.parse(model.actionsJson) : [];
                                        return parsed;
                                    } catch (e) {
                                        return [];
                                    }
                                }

                                Rectangle {
                                    id: innerCard
                                    width: parent.width
                                    height: cardContent.height + window.s(24)
                                    radius: window.s(16)
                                    color: cardHover.containsMouse ? Qt.alpha(window.surface1, 0.55) : Qt.alpha(window.surface0, 0.45)
                                    border.color: cardHover.containsMouse ? Qt.alpha(window.mauve, 0.5) : Qt.alpha(window.mauve, 0.3)
                                    border.width: 1
                                    clip: true
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on border.color { ColorAnimation { duration: 200 } }

                                    MouseArea {
                                        id: cardHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if ((model.appName === "Screenshot" || model.appName === "Screen Recorder") && model.iconPath !== "") {
                                                let folderPath = model.iconPath.substring(0, model.iconPath.lastIndexOf('/'))
                                                Quickshell.execDetached(["xdg-open", folderPath])
                                            } else {
                                                if (delegateWrapper.realNotif && delegateWrapper.realNotif.actions) {
                                                    for (var i = 0; i < delegateWrapper.realNotif.actions.length; i++) {
                                                        if (delegateWrapper.realNotif.actions[i].identifier === "default") {
                                                            delegateWrapper.realNotif.actions[i].invoke();
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                            if (delegateWrapper.realNotif && typeof delegateWrapper.realNotif.close === "function") {
                                                delegateWrapper.realNotif.close()
                                            }
                                            delegateWrapper.removeThisNotif();
                                        }
                                    }

                                    // Left side accent stripe
                                    Rectangle {
                                        width: window.s(4)
                                        height: parent.height
                                        anchors.left: parent.left
                                        color: window.ambientPrimary
                                    }

                                    ColumnLayout {
                                        id: cardContent
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: window.s(14)
                                        anchors.leftMargin: window.s(18) // make room for the accent stripe
                                        spacing: window.s(6)

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: window.s(8)

                                            Text {
                                                text: model.summary || "Notification"
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: window.s(13)
                                                color: window.text
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                                textFormat: Text.StyledText
                                            }

                                            // Individual Dismiss Button
                                            Rectangle {
                                                Layout.preferredWidth: window.s(22)
                                                Layout.preferredHeight: window.s(22)
                                                radius: window.s(11)
                                                color: itemClearMa.containsMouse ? Qt.alpha(window.red, 0.15) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    font.family: "Iosevka Nerd Font"
                                                    font.pixelSize: window.s(12)
                                                    color: itemClearMa.containsMouse ? window.red : window.overlay0
                                                    text: "󰅖"
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }

                                                MouseArea {
                                                    id: itemClearMa
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: delegateWrapper.removeThisNotif();
                                                }
                                            }
                                        }

                                        Text {
                                            text: model.body || ""
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            font.pixelSize: window.s(11)
                                            color: window.subtext0
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            visible: text !== ""
                                            textFormat: Text.StyledText 
                                            onLinkActivated: (link) => Quickshell.execDetached(["xdg-open", link])
                                        }

                                        // Action Buttons Dock 
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: delegateWrapper.actionArray.length > 0 ? window.s(6) : 0
                                            spacing: window.s(8)
                                            visible: delegateWrapper.actionArray.length > 0

                                            Repeater {
                                                model: delegateWrapper.actionArray
                                                delegate: Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: window.s(28)
                                                    radius: window.s(14)

                                                    property bool isPrimary: index === 0

                                                    color: {
                                                        if (isPrimary) {
                                                            return actionMouseArea.containsMouse ? Qt.alpha(window.blue, 0.8) : Qt.alpha(window.blue, 0.5)
                                                        } else {
                                                            return actionMouseArea.containsMouse ? Qt.alpha(window.surface2, 0.8) : Qt.alpha(window.surface1, 0.4)
                                                        }
                                                    }
                                                    
                                                    border.color: isPrimary ? window.blue : Qt.alpha(window.surface2, 0.6)
                                                    border.width: actionMouseArea.containsMouse ? 2 : 1
                                                    
                                                    Behavior on color { ColorAnimation { duration: 150 } }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.text || "Action"
                                                        font.family: "JetBrains Mono"
                                                        font.weight: Font.Bold
                                                        font.pixelSize: window.s(11)
                                                        color: isPrimary ? window.crust : window.text
                                                        opacity: actionMouseArea.containsMouse ? 1.0 : 0.85
                                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                                    }

                                                    MouseArea {
                                                        id: actionMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor

                                                        onClicked: {
                                                            if (delegateWrapper.realNotif && delegateWrapper.realNotif.actions) {
                                                                for (var i = 0; i < delegateWrapper.realNotif.actions.length; i++) {
                                                                    if (delegateWrapper.realNotif.actions[i].identifier === modelData.id) {
                                                                        delegateWrapper.realNotif.actions[i].invoke();
                                                                        break;
                                                                    }
                                                                }
                                                            }
                                                            delegateWrapper.removeThisNotif();
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
