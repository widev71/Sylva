import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

    Item {
        id: generalTabRoot

        function focusLangInput() { langInput.forceActiveFocus(); }
        function focusWpDirInput() { wpDirInput.forceActiveFocus(); }
        function layoutListIncrementIndex() { layoutListView.incrementCurrentIndex(); }
        function layoutListDecrementIndex() { layoutListView.decrementCurrentIndex(); }
        function acceptLayoutSelection() {
            if (layoutListView.currentIndex >= 0 && layoutListView.currentIndex < root.kbToggleModelArr.length) {
                Config.kbOptions = root.kbToggleModelArr[layoutListView.currentIndex].val;
            }
        }
        function scrollTo(y) {
            let maxY = Math.max(0, generalFlickable.contentHeight - generalFlickable.height);
            generalFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
        }
        function scrollToBox(approxItemY) {
            let viewH = generalFlickable.height;
            let itemTop = approxItemY;
            let itemBottom = approxItemY + root.s(80);
            let curY = generalFlickable.contentY;
            let maxY = Math.max(0, generalFlickable.contentHeight - viewH);
            if (itemTop < curY + root.s(10)) {
                generalFlickable.contentY = Math.max(0, itemTop - root.s(20));
            } else if (itemBottom > curY + viewH - root.s(10)) {
                generalFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
            }
        }

        Flickable {
            id: generalFlickable
            anchors.fill: parent
            contentWidth: width
            contentHeight: settingsMainCol.implicitHeight + root.s(100)
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: root.clearHighlight()
                z: -1
            }

            ColumnLayout {
                id: settingsMainCol
                width: parent.width
                spacing: root.s(10)

                // ── Box 0: Guide on startup ──────────────────────────────
                Rectangle {
                    id: box0
                    Layout.fillWidth: true
                    Layout.preferredHeight: guideRow.implicitHeight + root.s(28)
                    radius: root.s(12)

                    property bool isActive: root.highlightedBox === 0
                    color: isActive ? root.peach : root.surface0
                    border.color: isActive ? root.peach : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 0; z: -1 }

                    RowLayout {
                        id: guideRow
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: root.s(16)
                        spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22)
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent
                                text: "󰑊"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: root.s(18)
                                color: box0.isActive ? root.base : root.peach
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: root.s(3)
                            Text {
                                text: "Panduan saat mulai"
                                font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: box0.isActive ? root.base : root.text
                                Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Tampil otomatis saat login"
                                font.family: "Inter"; font.pixelSize: root.s(11)
                                color: box0.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7)
                                Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            Layout.preferredWidth: root.s(40)
                            Layout.preferredHeight: root.s(22)
                            radius: root.s(11)
                            scale: toggle1Ma.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            color: Config.openGuideAtStartup
                                ? (box0.isActive ? root.base : root.peach)
                                : Qt.alpha(root.surface2, box0.isActive ? 0.4 : 1.0)
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            Rectangle {
                                width: root.s(16); height: root.s(16); radius: root.s(8)
                                color: Config.openGuideAtStartup
                                    ? (box0.isActive ? root.peach : root.base)
                                    : (box0.isActive ? root.peach : root.surface0)
                                y: root.s(3); x: Config.openGuideAtStartup ? root.s(21) : root.s(3)
                                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            MouseArea { id: toggle1Ma; anchors.fill: parent; hoverEnabled: true; onClicked: Config.openGuideAtStartup = !Config.openGuideAtStartup; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                // ── Box 1: Help icon ─────────────────────────────────────
                Rectangle {
                    id: box1
                    Layout.fillWidth: true
                    Layout.preferredHeight: helpIconRow.implicitHeight + root.s(28)
                    radius: root.s(12)

                    property bool isActive: root.highlightedBox === 1
                    color: isActive ? root.blue : root.surface0
                    border.color: isActive ? root.blue : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 1; z: -1 }

                    RowLayout {
                        id: helpIconRow
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: root.s(16)
                        spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22)
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent; text: "󰋖"
                                font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                color: box1.isActive ? root.base : root.blue
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                            Text {
                                text: "Help icon"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: box1.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Show button in topbar"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: box1.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            Layout.preferredWidth: root.s(40); Layout.preferredHeight: root.s(22); radius: root.s(11)
                            scale: toggle2Ma.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            color: Config.topbarHelpIcon
                                ? (box1.isActive ? root.base : root.blue)
                                : Qt.alpha(root.surface2, box1.isActive ? 0.4 : 1.0)
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            Rectangle {
                                width: root.s(16); height: root.s(16); radius: root.s(8)
                                color: Config.topbarHelpIcon
                                    ? (box1.isActive ? root.blue : root.base)
                                    : (box1.isActive ? root.blue : root.surface0)
                                y: root.s(3); x: Config.topbarHelpIcon ? root.s(21) : root.s(3)
                                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            MouseArea { id: toggle2Ma; anchors.fill: parent; hoverEnabled: true; onClicked: Config.topbarHelpIcon = !Config.topbarHelpIcon; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                // ── Box 2: UI Scale ──────────────────────────────────────
                Rectangle {
                    id: box2
                    Layout.fillWidth: true
                    Layout.preferredHeight: col2.implicitHeight + root.s(32)
                    radius: root.s(12)

                    property bool isActive: root.highlightedBox === 2
                    color: isActive ? root.sapphire : root.surface0
                    border.color: isActive ? root.sapphire : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 2; z: -1 }

                    ColumnLayout {
                        id: col2
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(14)
                            Item {
                                Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent; text: "󰁦"
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                    color: box2.isActive ? root.base : root.sapphire
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                                Text {
                                    text: "UI Scale"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                    color: box2.isActive ? root.base : root.text; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Text {
                                    text: "Base size scalar"; font.family: "Inter"; font.pixelSize: root.s(11)
                                    color: box2.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10)
                                Rectangle {
                                    width: root.s(28); height: root.s(28); radius: root.s(6)
                                    color: sMinusMa.pressed
                                        ? Qt.alpha(root.base, 0.3)
                                        : (sMinusMa.containsMouse
                                            ? Qt.alpha(root.base, 0.2)
                                            : Qt.alpha(root.base, 0.15))
                                    scale: sMinusMa.pressed ? 0.90 : (sMinusMa.containsMouse ? 1.08 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Text {
                                        anchors.centerIn: parent; text: "-"
                                        font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(15)
                                        color: box2.isActive ? root.base : root.sapphire
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                    MouseArea { id: sMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.max(0.5, (Config.uiScale - 0.1).toFixed(1)) }
                                }
                                Text { 
                                    text: Config.uiScale.toFixed(1) + "x"
                                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(13)
                                    color: box2.isActive ? root.base : root.sapphire
                                    Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Rectangle {
                                    width: root.s(28); height: root.s(28); radius: root.s(6)
                                    color: sPlusMa.pressed
                                        ? Qt.alpha(root.base, 0.3)
                                        : (sPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                                    scale: sPlusMa.pressed ? 0.90 : (sPlusMa.containsMouse ? 1.08 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Text {
                                        anchors.centerIn: parent; text: "+"
                                        font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(15)
                                        color: box2.isActive ? root.base : root.sapphire
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                    MouseArea { id: sPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.min(2.0, (Config.uiScale + 0.1).toFixed(1)) }
                                }
                            }
                        }
                    }
                }

                // ── Box 3: Keyboard layouts ──────────────────────────────
                Rectangle {
                    id: box3
                    Layout.fillWidth: true
                    Layout.preferredHeight: col3lang.implicitHeight + root.s(32)
                    radius: root.s(12)

                    property bool isActive: root.highlightedBox === 3
                    color: isActive ? root.green : root.surface0
                    border.color: isActive ? root.green : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 3; z: -1 }

                    ColumnLayout {
                        id: col3lang
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        spacing: root.s(16)
                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(14)
                            Item {
                                Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
                                Text {
                                    anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                    text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                    color: box3.isActive ? root.base : root.green
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
                                Text {
                                    text: "Keyboard layouts"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                    color: box3.isActive ? root.base : root.text; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Text {
                                    text: "Matches hyprland.conf. Click ✖ to remove."; font.family: "Inter"; font.pixelSize: root.s(11)
                                    color: box3.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(8)
                                    Repeater {
                                        model: Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : []
                                        Rectangle {
                                            width: langChipLayout.implicitWidth + root.s(20); height: root.s(26); radius: root.s(13)
                                            color: box3.isActive ? Qt.alpha(root.base, 0.2) : root.surface1
                                            border.color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.4) : "transparent")
                                            border.width: chipMa.containsMouse ? 1 : 0
                                            scale: chipMa.containsMouse ? 1.05 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                            RowLayout {
                                                id: langChipLayout; anchors.centerIn: parent; spacing: root.s(6)
                                                Text {
                                                    text: modelData; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(11)
                                                    color: chipMa.containsMouse ? root.red : (box3.isActive ? root.base : root.text)
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                                Text {
                                                    text: "✖"; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                                    color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0)
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                            }
                                            MouseArea {
                                                id: chipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let arr = Config.language.split(",").filter(x => x.trim() !== "");
                                                    arr.splice(index, 1);
                                                    Config.language = arr.join(",");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
                            radius: root.s(7)
                            color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                            border.color: langInput.activeFocus
                                ? (box3.isActive ? root.base : root.green)
                                : (box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            TextInput {
                                id: langInput
                                anchors.fill: parent; anchors.margins: root.s(9)
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                color: box3.isActive ? root.base : root.text; clip: true; selectByMouse: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
                                        if (langSearchModel.count > 0) { langListView.incrementCurrentIndex(); event.accepted = true; }
                                    } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
                                        if (langSearchModel.count > 0) { langListView.decrementCurrentIndex(); event.accepted = true; }
                                    }
                                }
                                Keys.onReturnPressed: (event) => langInputAccept(event)
                                Keys.onEnterPressed: (event) => langInputAccept(event)
                                function langInputAccept(event) {
                                    if (langSearchModel.count > 0 && langListView.currentIndex >= 0) {
                                        let item = langSearchModel.get(langListView.currentIndex);
                                        let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : [];
                                        if (!arr.includes(item.code)) { arr.push(item.code); Config.language = arr.join(","); }
                                    }
                                    text = ""; focus = false; event.accepted = true;
                                }
                                onActiveFocusChanged: { if (activeFocus) root.updateLangSearch(text); }
                                onTextChanged: { root.updateLangSearch(text); }
                                Text {
                                    text: "Search to add..."
                                    color: box3.isActive ? Qt.alpha(root.base, 0.5) : Qt.alpha(root.subtext0, 0.7)
                                    visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: langInput.activeFocus && langSearchModel.count > 0 ? Math.min(root.s(160), langSearchModel.count * root.s(30) + root.s(8)) : 0
                            radius: root.s(7)
                            color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                            border.color: box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
                            border.width: 1
                            clip: true
                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            ListView {
                                id: langListView
                                anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
                                model: langSearchModel; interactive: true
                                opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
                                delegate: Rectangle {
                                    width: parent ? parent.width - root.s(8) : 0; height: root.s(30)
                                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined; radius: root.s(4)
                                    property bool isHovered: sMa.containsMouse
                                    color: isHovered
                                        ? Qt.alpha(box3.isActive ? root.base : root.green, 0.2)
                                        : (ListView.isCurrentItem ? Qt.alpha(box3.isActive ? root.base : root.green, 0.1) : "transparent")
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8); spacing: root.s(8)
                                        Text { text: model.code; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: box3.isActive ? root.base : root.text; Behavior on color { ColorAnimation { duration: 150 } } }
                                        Text { text: model.name; font.family: "Inter"; font.pixelSize: root.s(11); color: box3.isActive ? Qt.alpha(root.base, 0.7) : Qt.alpha(root.subtext0, 0.7); elide: Text.ElideRight; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 150 } } }
                                    }
                                    MouseArea {
                                        id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : [];
                                            if (!arr.includes(model.code)) { arr.push(model.code); Config.language = arr.join(","); }
                                            langInput.text = ""; langInput.focus = false;
                                        }
                                    }
                                }
                            }
                        }
                    }                       
                }

                // ── Box 4: Layout shortcut ───────────────────────────────
                Rectangle {
                    id: box4
                    Layout.fillWidth: true
                    Layout.preferredHeight: col4layout.implicitHeight + root.s(32)
                    radius: root.s(12)

                    property bool isActive: root.highlightedBox === 4
                    color: isActive ? root.teal : root.surface0
                    border.color: isActive ? root.teal : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 4; z: -1 }

                    ColumnLayout {
                        id: col4layout
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        spacing: root.s(16)
                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(14)
                            Item {
                                Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
                                Text {
                                    anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                    text: "󰯍"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                    color: box4.isActive ? root.base : root.teal
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
                                Text {
                                    text: "Layout shortcut"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                    color: box4.isActive ? root.base : root.text; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Text {
                                    text: "Toggle combination"; font.family: "Inter"; font.pixelSize: root.s(11)
                                    color: box4.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
                                    radius: root.s(7)
                                    color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                    border.color: root.isLayoutDropdownOpen
                                        ? (box4.isActive ? root.base : root.teal)
                                        : (box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                                    border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: root.s(9)
                                        Text {
                                            text: root.getKbToggleLabel(Config.kbOptions)
                                            font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                            color: box4.isActive ? root.base : root.text; Layout.fillWidth: true
                                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                        }
                                        Text {
                                            text: root.isLayoutDropdownOpen ? "▴" : "▾"; font.pixelSize: root.s(12)
                                            color: box4.isActive ? Qt.alpha(root.base, 0.7) : root.subtext0
                                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.isLayoutDropdownOpen = !root.isLayoutDropdownOpen;
                                            if (root.isLayoutDropdownOpen) {
                                                let idx = root.kbToggleModelArr.findIndex(x => x.val === Config.kbOptions);
                                                layoutListView.currentIndex = Math.max(0, idx);
                                            }
                                            root.forceActiveFocus();
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.isLayoutDropdownOpen ? root.kbToggleModelArr.length * root.s(30) + root.s(8) : 0
                                    radius: root.s(7)
                                    color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                    border.color: box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
                                    border.width: 1
                                    clip: true
                                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    ListView {
                                        id: layoutListView
                                        anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
                                        model: root.kbToggleModelArr; interactive: false
                                        opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                        delegate: Rectangle {
                                            width: parent ? parent.width - root.s(8) : 0; height: root.s(30)
                                            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined; radius: root.s(4)
                                            property bool isHovered: toggleMa.containsMouse
                                            color: isHovered
                                                ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.2)
                                                : (ListView.isCurrentItem ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.1) : "transparent")
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8)
                                                Text {
                                                    text: modelData.label; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                                    color: Config.kbOptions === modelData.val
                                                        ? (box4.isActive ? root.base : root.teal)
                                                        : (box4.isActive ? Qt.alpha(root.base, 0.8) : root.text)
                                                    Layout.fillWidth: true
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                            }
                                            MouseArea { id: toggleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Config.kbOptions = modelData.val; root.isLayoutDropdownOpen = false; } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Box 5: Wallpaper directory ───────────────────────────
                Rectangle {
                    id: box5
                    Layout.fillWidth: true
                    Layout.preferredHeight: col5wp.implicitHeight + root.s(32)
                    radius: root.s(12)

                    property bool isActive: root.highlightedBox === 5
                    color: isActive ? root.mauve : root.surface0
                    border.color: isActive ? root.mauve : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 5; z: -1 }

                    ColumnLayout {
                        id: col5wp
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(14)
                            Item {
                                Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
                                Text {
                                    anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                    text: "󰋩"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                    color: box5.isActive ? root.base : root.mauve
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
                                Text {
                                    text: "Wallpaper directory"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                    color: box5.isActive ? root.base : root.text; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Text {
                                    text: "Absolute source path"; font.family: "Inter"; font.pixelSize: root.s(11)
                                    color: box5.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
                                    radius: root.s(7)
                                    color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                    border.color: wpDirInput.activeFocus
                                        ? (box5.isActive ? root.base : root.mauve)
                                        : (box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                                    border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    TextInput {
                                        id: wpDirInput
                                        anchors.fill: parent; anchors.margins: root.s(9)
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: Config.wallpaperDir
                                        font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                        color: box5.isActive ? root.base : root.text; clip: true; selectByMouse: true
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                        Keys.onPressed: (event) => {
                                            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
                                                if (pathSuggestModel.count > 0) { wpSuggestListView.incrementCurrentIndex(); event.accepted = true; }
                                            } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
                                                if (pathSuggestModel.count > 0) { wpSuggestListView.decrementCurrentIndex(); event.accepted = true; }
                                            }
                                        }
                                        Keys.onReturnPressed: (event) => wpDirInputAccept(event)
                                        Keys.onEnterPressed: (event) => wpDirInputAccept(event)
                                        function wpDirInputAccept(event) {
                                            if (pathSuggestModel.count > 0 && wpSuggestListView.currentIndex >= 0) {
                                                let item = pathSuggestModel.get(wpSuggestListView.currentIndex);
                                                if (item) { text = item.path; Config.wallpaperDir = text; }
                                            }
                                            pathSuggestModel.clear(); focus = false; event.accepted = true;
                                        }
                                        onActiveFocusChanged: {
                                            if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; }
                                        }
                                        onTextChanged: {
                                            Config.wallpaperDir = text;
                                            if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; }
                                        }
                                        Text {
                                            text: "Enter directory..."; color: box5.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0
                                            visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: wpDirInput.activeFocus && pathSuggestModel.count > 0 ? pathSuggestModel.count * root.s(28) + root.s(8) : 0
                                    radius: root.s(7)
                                    color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                    border.color: box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
                                    border.width: 1
                                    clip: true
                                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    ListView {
                                        id: wpSuggestListView
                                        anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
                                        model: pathSuggestModel; interactive: false
                                        opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                        delegate: Rectangle {
                                            width: parent ? parent.width - root.s(8) : 0; height: root.s(28)
                                            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined; radius: root.s(4)
                                            property bool isHovered: suggestMa.containsMouse
                                            color: isHovered
                                                ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.2)
                                                : (ListView.isCurrentItem ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.1) : "transparent")
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter; x: root.s(8)
                                                text: model.path; font.family: "JetBrains Mono"; font.pixelSize: root.s(10)
                                                color: box5.isActive ? root.base : root.text
                                                elide: Text.ElideMiddle; width: parent.width - root.s(16)
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                            MouseArea { id: suggestMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { wpDirInput.text = model.path; pathSuggestModel.clear(); wpDirInput.focus = false; } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Box 6: Workspaces ────────────────────────────────────
                Rectangle {
                    id: box6
                    Layout.fillWidth: true
                    Layout.preferredHeight: col6ws.implicitHeight + root.s(32)
                    radius: root.s(12)

                    property bool isActive: root.highlightedBox === 6
                    color: isActive ? root.red : root.surface0
                    border.color: isActive ? root.red : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 6; z: -1 }

                    ColumnLayout {
                        id: col6ws
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(14)
                            Item {
                                Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent; text: "󰽿"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                    color: box6.isActive ? root.base : root.red
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                                Text {
                                    text: "Workspaces"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(14)
                                    color: box6.isActive ? root.base : root.text; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Text {
                                    text: "Static count in topbar"; font.family: "Inter"; font.pixelSize: root.s(11)
                                    color: box6.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10)
                                Rectangle {
                                    width: root.s(28); height: root.s(28); radius: root.s(6)
                                    color: wsMinusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsMinusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                                    scale: wsMinusMa.pressed ? 0.90 : (wsMinusMa.containsMouse ? 1.08 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Text {
                                        anchors.centerIn: parent; text: "-"
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(15)
                                        color: box6.isActive ? root.base : root.red
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                    MouseArea { id: wsMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.max(2, Config.workspaceCount - 1) }
                                }
                                Text { 
                                    text: Config.workspaceCount.toString()
                                    font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(14)
                                    color: box6.isActive ? root.base : root.red
                                    Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Rectangle {
                                    width: root.s(28); height: root.s(28); radius: root.s(6)
                                    color: wsPlusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                                    scale: wsPlusMa.pressed ? 0.90 : (wsPlusMa.containsMouse ? 1.08 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Text {
                                        anchors.centerIn: parent; text: "+"
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(15)
                                        color: box6.isActive ? root.base : root.red
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                    MouseArea { id: wsPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.min(10, Config.workspaceCount + 1) }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: box7
                    Layout.fillWidth: true; Layout.preferredHeight: col7tp.implicitHeight + root.s(20)
                    radius: root.s(12); clip: true
                    
                    property bool isActive: root.highlightedBox === 7
                    color: isActive ? root.mauve : root.surface0
                    border.color: isActive ? root.mauve : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                    
                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 7; z: -1 }

                    ColumnLayout {
                        id: col7tp
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        spacing: root.s(12)

                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(14)
                            Item {
                                Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent; text: "󰟥"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                    color: box7.isActive ? root.base : root.mauve
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                                Text {
                                    text: "Touchpad Settings"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(14)
                                    color: box7.isActive ? root.base : root.text; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Text {
                                    text: "Scrolling, clicks, and sensitivity"; font.family: "Inter"; font.pixelSize: root.s(11)
                                    color: box7.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                        }
                        
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: box7.isActive ? Qt.alpha(root.base, 0.2) : root.surface1 }

                        RowLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Natural Scroll"; font.family: "Inter"; font.pixelSize: root.s(13); color: box7.isActive ? root.base : root.text; Layout.fillWidth: true }
                            Rectangle {
                                width: root.s(40); height: root.s(22); radius: height/2
                                color: Config.tpNaturalScroll ? (box7.isActive ? root.base : root.mauve) : (box7.isActive ? Qt.alpha(root.base, 0.3) : root.surface1)
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.tpNaturalScroll = !Config.tpNaturalScroll }
                                Rectangle {
                                    width: root.s(16); height: root.s(16); radius: width/2; anchors.verticalCenter: parent.verticalCenter
                                    x: Config.tpNaturalScroll ? parent.width - width - root.s(3) : root.s(3)
                                    color: Config.tpNaturalScroll ? (box7.isActive ? root.mauve : root.base) : (box7.isActive ? root.base : root.text)
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Tap-to-click"; font.family: "Inter"; font.pixelSize: root.s(13); color: box7.isActive ? root.base : root.text; Layout.fillWidth: true }
                            Rectangle {
                                width: root.s(40); height: root.s(22); radius: height/2
                                color: Config.tpTapToClick ? (box7.isActive ? root.base : root.mauve) : (box7.isActive ? Qt.alpha(root.base, 0.3) : root.surface1)
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.tpTapToClick = !Config.tpTapToClick }
                                Rectangle {
                                    width: root.s(16); height: root.s(16); radius: width/2; anchors.verticalCenter: parent.verticalCenter
                                    x: Config.tpTapToClick ? parent.width - width - root.s(3) : root.s(3)
                                    color: Config.tpTapToClick ? (box7.isActive ? root.mauve : root.base) : (box7.isActive ? root.base : root.text)
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Disable while typing"; font.family: "Inter"; font.pixelSize: root.s(13); color: box7.isActive ? root.base : root.text; Layout.fillWidth: true }
                            Rectangle {
                                width: root.s(40); height: root.s(22); radius: height/2
                                color: Config.tpDisableWhileTyping ? (box7.isActive ? root.base : root.mauve) : (box7.isActive ? Qt.alpha(root.base, 0.3) : root.surface1)
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.tpDisableWhileTyping = !Config.tpDisableWhileTyping }
                                Rectangle {
                                    width: root.s(16); height: root.s(16); radius: width/2; anchors.verticalCenter: parent.verticalCenter
                                    x: Config.tpDisableWhileTyping ? parent.width - width - root.s(3) : root.s(3)
                                    color: Config.tpDisableWhileTyping ? (box7.isActive ? root.mauve : root.base) : (box7.isActive ? root.base : root.text)
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Cursor Sensitivity"; font.family: "Inter"; font.pixelSize: root.s(13); color: box7.isActive ? root.base : root.text; Layout.fillWidth: true }
                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(8)
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: sensMin.pressed ? Qt.alpha(root.base,0.3) : (sensMin.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: "-"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box7.isActive ? root.base : root.mauve }
                                    MouseArea { id: sensMin; anchors.fill: parent; hoverEnabled: true; onClicked: Config.tpSensitivity = Math.max(-1.0, Math.round((Config.tpSensitivity - 0.1) * 10) / 10) }
                                }
                                Text { text: Number(Config.tpSensitivity).toFixed(1); font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(13); color: box7.isActive ? root.base : root.mauve; Layout.minimumWidth: root.s(35); horizontalAlignment: Text.AlignHCenter }
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: sensPlus.pressed ? Qt.alpha(root.base,0.3) : (sensPlus.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: "+"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box7.isActive ? root.base : root.mauve }
                                    MouseArea { id: sensPlus; anchors.fill: parent; hoverEnabled: true; onClicked: Config.tpSensitivity = Math.min(10.0, Math.round((Config.tpSensitivity + 0.1) * 10) / 10) }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Scroll Speed"; font.family: "Inter"; font.pixelSize: root.s(13); color: box7.isActive ? root.base : root.text; Layout.fillWidth: true }
                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(8)
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: scrMin.pressed ? Qt.alpha(root.base,0.3) : (scrMin.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: "-"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box7.isActive ? root.base : root.mauve }
                                    MouseArea { id: scrMin; anchors.fill: parent; hoverEnabled: true; onClicked: Config.tpScrollFactor = Math.max(0.1, Math.round((Config.tpScrollFactor - 0.1) * 10) / 10) }
                                }
                                Text { text: Number(Config.tpScrollFactor).toFixed(1) + "x"; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(13); color: box7.isActive ? root.base : root.mauve; Layout.minimumWidth: root.s(35); horizontalAlignment: Text.AlignHCenter }
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: scrPlus.pressed ? Qt.alpha(root.base,0.3) : (scrPlus.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: "+"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box7.isActive ? root.base : root.mauve }
                                    MouseArea { id: scrPlus; anchors.fill: parent; hoverEnabled: true; onClicked: Config.tpScrollFactor = Math.min(5.0, Math.round((Config.tpScrollFactor + 0.1) * 10) / 10) }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: box8
                    Layout.fillWidth: true; Layout.preferredHeight: col8crs.implicitHeight + root.s(20)
                    radius: root.s(12); clip: true
                    
                    property bool isActive: root.highlightedBox === 8
                    color: isActive ? root.pink : root.surface0
                    border.color: isActive ? root.pink : root.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                    
                    MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 8; z: -1 }

                    ColumnLayout {
                        id: col8crs
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                        spacing: root.s(12)

                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(14)
                            Item {
                                Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent; text: "󰇄"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                    color: box8.isActive ? root.base : root.pink
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                                Text {
                                    text: "Cursor Configuration"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(14)
                                    color: box8.isActive ? root.base : root.text; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                Text {
                                    text: "Cursor theme and size"; font.family: "Inter"; font.pixelSize: root.s(11)
                                    color: box8.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                            }
                        }
                        
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: box8.isActive ? Qt.alpha(root.base, 0.2) : root.surface1 }

                        RowLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Cursor Theme"; font.family: "Inter"; font.pixelSize: root.s(13); color: box8.isActive ? root.base : root.text; Layout.fillWidth: true }
                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(8)
                                
                                property var themes: ["Adwaita", "macOS-White", "macOS"]
                                
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: themePrev.pressed ? Qt.alpha(root.base,0.3) : (themePrev.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: "<"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box8.isActive ? root.base : root.pink }
                                    MouseArea {
                                        id: themePrev; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            let idx = parent.parent.themes.indexOf(Config.cursorTheme);
                                            if (idx <= 0) idx = parent.parent.themes.length;
                                            Config.cursorTheme = parent.parent.themes[idx - 1];
                                        }
                                    }
                                }
                                Text { text: Config.cursorTheme; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(13); color: box8.isActive ? root.base : root.pink; Layout.minimumWidth: root.s(90); horizontalAlignment: Text.AlignHCenter }
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: themeNext.pressed ? Qt.alpha(root.base,0.3) : (themeNext.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: ">"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box8.isActive ? root.base : root.pink }
                                    MouseArea {
                                        id: themeNext; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            let idx = parent.parent.themes.indexOf(Config.cursorTheme);
                                            if (idx >= parent.parent.themes.length - 1 || idx === -1) idx = -1;
                                            Config.cursorTheme = parent.parent.themes[idx + 1];
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Cursor Size"; font.family: "Inter"; font.pixelSize: root.s(13); color: box8.isActive ? root.base : root.text; Layout.fillWidth: true }
                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(8)
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: cSizeMin.pressed ? Qt.alpha(root.base,0.3) : (cSizeMin.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: "-"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box8.isActive ? root.base : root.pink }
                                    MouseArea { id: cSizeMin; anchors.fill: parent; hoverEnabled: true; onClicked: Config.cursorSize = Math.max(16, Config.cursorSize - 4) }
                                }
                                Text { text: Config.cursorSize; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(13); color: box8.isActive ? root.base : root.pink; Layout.minimumWidth: root.s(30); horizontalAlignment: Text.AlignHCenter }
                                Rectangle {
                                    width: root.s(24); height: root.s(24); radius: root.s(4); color: cSizePlus.pressed ? Qt.alpha(root.base,0.3) : (cSizePlus.containsMouse ? Qt.alpha(root.base,0.2) : Qt.alpha(root.base,0.15))
                                    Text { anchors.centerIn: parent; text: "+"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: box8.isActive ? root.base : root.pink }
                                    MouseArea { id: cSizePlus; anchors.fill: parent; hoverEnabled: true; onClicked: Config.cursorSize = Math.min(64, Config.cursorSize + 4) }
                                }
                            }
                        }
                    }
                }
            }
        }        
    }
