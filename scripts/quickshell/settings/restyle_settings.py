import re

with open("/home/witya/.config/hypr/scripts/quickshell/settings/SettingsPopup.qml", "r") as f:
    content = f.read()

# 1. Update the Header Block
header_regex = re.compile(
    r'(// ── Header ────────────────────────────────────────────────────.*?)(?=// ── Search bar ────────────────────────────────────────────────)',
    re.DOTALL
)

new_header = """// ── Header ────────────────────────────────────────────────────
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

                """

content = header_regex.sub(new_header, content, count=1)

# 2. Update the Tab Bar
tabbar_regex = re.compile(
    r'(// ── Tab Bar ───────────────────────────────────────────────────.*?)(?=// ── Content area ──────────────────────────────────────────────)',
    re.DOTALL
)

new_tabbar = """// ── Tab Bar ───────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.s(36)
                    Layout.topMargin: root.s(10)
                    Layout.bottomMargin: root.s(10)
                    
                    Row {
                        id: tabRow
                        spacing: root.s(24)
                        anchors.fill: parent
                        
                        Repeater {
                            model: root.tabNames.length
                            Item {
                                id: tabItem
                                width: tabText.implicitWidth
                                height: parent.height

                                property bool isActive: root.currentTab === index

                                Text {
                                    id: tabText
                                    anchors.centerIn: parent
                                    text: root.tabNames[index]
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: root.s(13)
                                    color: isActive ? root.text : root.subtext0
                                    Behavior on color { ColorAnimation { duration: 200 } }
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
                    
                    Rectangle {
                        id: tabIndicator
                        height: root.s(2)
                        radius: root.s(1)
                        color: root.activeColor
                        y: parent.height - height
                        
                        property var currentItem: tabRow.children[root.currentTab]
                        property real targetX: currentItem ? currentItem.x : 0
                        property real targetW: currentItem ? currentItem.width : 0
                        
                        x: targetX
                        width: targetW
                        
                        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                """

content = tabbar_regex.sub(new_tabbar, content, count=1)

with open("/home/witya/.config/hypr/scripts/quickshell/settings/SettingsPopup.qml", "w") as f:
    f.write(content)

print("Header and TabBar replaced!")
