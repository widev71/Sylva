import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

    Item {
        id: profileTabRoot
        
        function scrollTo(y) {
            let maxY = Math.max(0, profileFlickable.contentHeight - profileFlickable.height);
            profileFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
        }
        function scrollToBox(y) {
            let maxY = Math.max(0, profileFlickable.contentHeight - profileFlickable.height);
            profileFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
        }

        Flickable {
            id: profileFlickable
            anchors.fill: parent
            contentWidth: width
            contentHeight: profileColLayout.implicitHeight + root.s(100)
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: root.clearHighlight()
                z: -1
            }

            ColumnLayout {
                id: profileColLayout
                width: parent.width
                spacing: root.s(10)

                // Helper to create input fields
                Component {
                    id: profileInputBox
                    Rectangle {
                        id: profileBox
                        property string title: ""
                        property string subtitle: ""
                        property string icon: ""
                        property string colorName: "pink"
                        property alias text: inputField.text
                        property int boxIndex: 0
                        
                        width: parent ? parent.width : 0
                        implicitHeight: col.implicitHeight + root.s(32)
                        height: implicitHeight
                        radius: root.s(12)
                        
                        property bool isActive: root.highlightedBox === boxIndex
                        color: isActive ? root[colorName] : root.surface0
                        border.color: isActive ? root[colorName] : root.surface1
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = profileBox.boxIndex; z: -1 }

                        ColumnLayout {
                            id: col
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                            spacing: root.s(16)
                            RowLayout {
                                Layout.fillWidth: true; spacing: root.s(14)
                                Item {
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
                                    Text {
                                        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                        text: profileBox.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
                                        color: profileBox.isActive ? root.base : root[colorName]
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
                                    Text {
                                        text: profileBox.title; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                        color: profileBox.isActive ? root.base : root.text; Layout.fillWidth: true
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                    Text {
                                        text: profileBox.subtitle; font.family: "Inter"; font.pixelSize: root.s(11)
                                        color: profileBox.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(40)
                                radius: root.s(6); color: profileBox.isActive ? Qt.alpha(root.base, 0.15) : root.crust
                                border.color: profileBox.isActive ? Qt.alpha(root.base, 0.3) : root.surface1; border.width: 1
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                TextInput {
                                    id: inputField
                                    anchors.fill: parent; anchors.margins: root.s(12)
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(13)
                                    color: profileBox.isActive ? root.base : root.text
                                    selectionColor: profileBox.isActive ? Qt.alpha(root.base, 0.3) : root.surface2
                                    selectedTextColor: color
                                    clip: true
                                    onFocusChanged: if (focus) root.highlightedBox = profileBox.boxIndex
                                    onTextChanged: {
                                        if (profileBox.boxIndex === 0) Config.profileGithub = text;
                                        else if (profileBox.boxIndex === 1) Config.profileDiscord = text;
                                        else if (profileBox.boxIndex === 2) Config.profileInstagram = text;
                                        else if (profileBox.boxIndex === 3) Config.profileTikTok = text;
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    sourceComponent: profileInputBox
                    onLoaded: {
                        item.boxIndex = 0;
                        item.title = "GitHub Username";
                        item.subtitle = "Your GitHub username for the profile widget";
                        item.icon = "";
                        item.colorName = "text";
                        item.text = Config.profileGithub;
                    }
                }
                Loader {
                    Layout.fillWidth: true
                    sourceComponent: profileInputBox
                    onLoaded: {
                        item.boxIndex = 1;
                        item.title = "Discord Username";
                        item.subtitle = "Your Discord username";
                        item.icon = "󰙯";
                        item.colorName = "blue";
                        item.text = Config.profileDiscord;
                    }
                }
                Loader {
                    Layout.fillWidth: true
                    sourceComponent: profileInputBox
                    onLoaded: {
                        item.boxIndex = 2;
                        item.title = "Instagram Username";
                        item.subtitle = "Your Instagram handle";
                        item.icon = "";
                        item.colorName = "pink";
                        item.text = Config.profileInstagram;
                    }
                }
                Loader {
                    Layout.fillWidth: true
                    sourceComponent: profileInputBox
                    onLoaded: {
                        item.boxIndex = 3;
                        item.title = "TikTok Username";
                        item.subtitle = "Your TikTok handle (without @)";
                        item.icon = "";
                        item.colorName = "red";
                        item.text = Config.profileTikTok;
                    }
                }

                Item { Layout.preferredHeight: root.s(16) }
            }
        }
    }
}
