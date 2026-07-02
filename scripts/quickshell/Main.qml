import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "WindowRegistry.js" as Registry
import "./main"

PanelWindow {
    id: masterWindow
    color: "transparent"

    Caching { id: paths }

    WlrLayershell.namespace: "qs-master"
    WlrLayershell.layer:     WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    focusable:     true

    implicitWidth:  masterWindow.screen.width
    implicitHeight: masterWindow.screen.height

    visible: isVisible

    mask: Region { item: topBarHole; intersection: Intersection.Xor }

    // ── IPC handler ────────────────────────────────────────────────────
    IpcHandler {
        target: "main"

        function forceReload(): void { Quickshell.reload(true) }

        function handleCommand(cmd: string, targetWidget: string, arg: string): void {
            cmd          = cmd          || "";
            targetWidget = targetWidget || "";
            arg          = arg          || "";

            let isClosing       = (masterWindow.currentActive !== "hidden" && !masterWindow.isVisible);
            let effectiveActive = isClosing ? "hidden" : masterWindow.currentActive;

            if (cmd === "close") {
                switchWidget("hidden", "");
            } else if (cmd === "toggle" || cmd === "open") {
                delayedClear.stop();
                if (targetWidget === effectiveActive) {
                    let ci = widgetStack.currentItem;
                    if (arg !== "" && ci && ci.activeMode !== undefined && ci.activeMode !== arg)
                        ci.activeMode = arg;
                    else if (cmd === "toggle")
                        switchWidget("hidden", "");
                } else if (getLayout(targetWidget)) {
                    switchWidget(targetWidget, arg);
                }
            } else if (getLayout(cmd)) {
                let legacyArg = targetWidget;
                delayedClear.stop();
                if (cmd === effectiveActive) {
                    let ci = widgetStack.currentItem;
                    if (legacyArg !== "" && ci && ci.activeMode !== undefined && ci.activeMode !== legacyArg)
                        ci.activeMode = legacyArg;
                    else
                        switchWidget("hidden", "");
                } else {
                    switchWidget(cmd, legacyArg);
                }
            }
        }
        
        function showOsd(type: string, value: string): void {
            osdDaemon.showOsd(type, parseInt(value) || 0);
        }

        function toggleDnd(): void {
            Quickshell.execDetached(["bash", "-c", `
                dnd_dir="` + paths.getCacheDir("dnd") + `"
                mkdir -p "$dnd_dir"
                state_file="$dnd_dir/state"
                if [ "$(cat "$state_file" 2>/dev/null)" = "1" ]; then
                    echo "0" > "$state_file"
                    notify-send -t 2000 "DND Disabled" "Notifications will now pop up."
                else
                    echo "1" > "$state_file"
                    notify-send -t 2000 "DND Enabled" "Notifications are hidden."
                fi
            `]);
        }
    }

    // ── Top bar mask hole ──────────────────────────────────────────────
    Item {
        id: topBarHole
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 48
        anchors.leftMargin:  (masterWindow.currentActive !== "hidden" && masterWindow.animX < 10 && masterWindow.animY < height) ? masterWindow.animW : 0
        anchors.rightMargin: (masterWindow.currentActive !== "hidden" && (masterWindow.animX + masterWindow.animW) > (parent.width - 10) && masterWindow.animY < height) ? masterWindow.animW : 0
        Behavior on anchors.leftMargin  { enabled: masterWindow.currentActive !== "hidden"; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutCubic } }
        Behavior on anchors.rightMargin { enabled: masterWindow.currentActive !== "hidden"; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutCubic } }
    }

    // Background dismiss click
    MouseArea { anchors.fill: parent; enabled: masterWindow.isVisible; onClicked: switchWidget("hidden", "") }

    // ── Daemons ────────────────────────────────────────────────────────
    NotificationDaemon {
        id: notifDaemon
        uiScale: masterWindow.globalUiScale
    }

    PreloadDaemon {
        id: preloadDaemon
        getLayout:    masterWindow.getLayout
        notifModel:   notifDaemon.notifModel
        liveNotifs:   notifDaemon.liveNotifs
        windowWidth:  masterWindow.width
        windowHeight: masterWindow.height
        onUiScaleChanged: function(v) { masterWindow.globalUiScale = v; handleNativeScreenChange(); }
    }

    OsdDaemon {
        id: osdDaemon
        uiScale: masterWindow.globalUiScale
    }

    // ── Core state ─────────────────────────────────────────────────────
    property string currentActive:  "hidden"
    property bool   isVisible:      false
    property string activeArg:      ""
    property bool   disableMorph:   false

    property int  morphDuration:       230
    property int  morphDurationSwitch: 210
    property int  exitDuration:        160

    property real animW: 1; property real animH: 1
    property real animX: 0; property real animY: 0
    property real targetW: 1; property real targetH: 1

    property real globalUiScale: 1.0

    // Pass shorthand aliases down for widgets that need them
    property var  notifModel: notifDaemon.notifModel
    property var  liveNotifs: notifDaemon.liveNotifs

    onCurrentActiveChanged: {
        Quickshell.execDetached(["bash", "-c", "echo '" + currentActive + "' > " + paths.runDir + "/current_widget"]);
    }

    onIsVisibleChanged: { if (isVisible) widgetStack.forceActiveFocus(); }

    // ── Layout cache ───────────────────────────────────────────────────
    property var    _layoutCache:    ({})
    property string _layoutCacheKey: ""

    function getLayout(name) {
        let key = name + "|" + masterWindow.width + "|" + masterWindow.height + "|" + masterWindow.globalUiScale;
        if (_layoutCacheKey === key) return _layoutCache[key];
        let result = Registry.getLayout(name, 0, 0, masterWindow.width, masterWindow.height, masterWindow.globalUiScale);
        _layoutCache = {};
        _layoutCache[key] = result;
        _layoutCacheKey = key;
        return result;
    }

    Connections {
        target: masterWindow
        function onWidthChanged()  { _layoutCacheKey = ""; handleNativeScreenChange(); }
        function onHeightChanged() { _layoutCacheKey = ""; handleNativeScreenChange(); }
    }

    function handleNativeScreenChange() {
        if (masterWindow.currentActive === "hidden") return;
        let t = getLayout(masterWindow.currentActive);
        if (!t) return;
        let ci     = widgetStack.currentItem;
        let finalW = (ci && ci.targetMasterWidth  !== undefined) ? ci.targetMasterWidth  : t.w;
        let finalH = (ci && ci.targetMasterHeight !== undefined) ? ci.targetMasterHeight : t.h;
        let finalX = t.rx;
        if (ci && ci.targetMasterWidth !== undefined && finalW !== t.w)
            finalX = Math.floor((masterWindow.width / 2) - (finalW / 2));
        masterWindow.animX = finalX; masterWindow.animY = t.ry;
        masterWindow.animW = finalW; masterWindow.animH = finalH;
        masterWindow.targetW = finalW; masterWindow.targetH = finalH;
    }

    // ── Animated bounding box + StackView ──────────────────────────────
    Item {
        x: masterWindow.animX; y: masterWindow.animY
        width: masterWindow.animW; height: masterWindow.animH
        clip: true

        Behavior on x      { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutCubic } }
        Behavior on y      { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutCubic } }
        Behavior on width  { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutCubic } }

        opacity: masterWindow.isVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: masterWindow.isVisible ? Easing.OutCubic : Easing.InCubic } }

        MouseArea { anchors.fill: parent }

        Item {
            anchors.fill: parent

            StackView {
                id: widgetStack
                anchors.fill: parent; focus: true

                Keys.onEscapePressed: { switchWidget("hidden", ""); event.accepted = true; }
                onCurrentItemChanged: { if (currentItem) currentItem.forceActiveFocus(); }

                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: masterWindow.morphDurationSwitch; easing.type: Easing.OutQuint }
                        NumberAnimation { property: "scale";   from: 0.98; to: 1.0; duration: masterWindow.morphDurationSwitch; easing.type: Easing.OutCubic }
                    }
                }
                replaceExit: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: masterWindow.morphDurationSwitch; easing.type: Easing.InQuint }
                        NumberAnimation { property: "scale";   from: 1.0; to: 0.98; duration: masterWindow.morphDurationSwitch; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    // ── Widget switching ───────────────────────────────────────────────
    function switchWidget(newWidget, arg) {
        delayedClear.stop();

        if (newWidget === "hidden") {
            if (currentActive !== "hidden") {
                masterWindow.morphDuration = masterWindow.exitDuration;
                masterWindow.disableMorph  = false;
                masterWindow.animW = 1; masterWindow.animH = 1;
                masterWindow.isVisible = false;
                delayedClear.start();
            }
        } else {
            if (currentActive === "hidden" || !masterWindow.isVisible) {
                masterWindow.morphDuration = 230;
                masterWindow.disableMorph  = false;
                let t = getLayout(newWidget);
                masterWindow.animX = t.rx; masterWindow.animY = t.ry;
                masterWindow.animW = t.w;  masterWindow.animH = t.h;
                masterWindow.targetW = t.w; masterWindow.targetH = t.h;
            } else {
                masterWindow.morphDuration = masterWindow.morphDurationSwitch;
                masterWindow.disableMorph  = false;
            }
            Qt.callLater(executeSwitch, newWidget, arg, false);
        }
    }

    function executeSwitch(newWidget, arg, immediate) {
        masterWindow.currentActive = newWidget;
        masterWindow.activeArg     = arg;

        let t = getLayout(newWidget);
        masterWindow.animX = t.rx; masterWindow.animY = t.ry;
        masterWindow.animW = t.w;  masterWindow.animH = t.h;
        masterWindow.targetW = t.w; masterWindow.targetH = t.h;

        let wc = preloadDaemon.widgetCache;
        let cached = wc[newWidget];
        if (!cached) {
            preloadDaemon.preloadWidget(newWidget);
            cached = preloadDaemon.widgetCache[newWidget];
        }

        if (cached) {
            if (cached.notifModel  !== undefined) cached.notifModel  = masterWindow.notifModel;
            if (cached.liveNotifs  !== undefined) cached.liveNotifs  = masterWindow.liveNotifs;
            if (cached.layoutWidth !== undefined) cached.layoutWidth = t.w;
            if (cached.layoutHeight !== undefined) cached.layoutHeight = t.h;
            if (newWidget === "wallpaper" && cached.widgetArg !== undefined) cached.widgetArg = arg;
            if (arg !== "" && cached.activeMode !== undefined) cached.activeMode = arg;
            cached.visible = true;
            immediate ? widgetStack.replace(cached, {}, StackView.Immediate) : widgetStack.replace(cached, {});
        } else {
            immediate ? widgetStack.replace(t.comp, {}, StackView.Immediate) : widgetStack.replace(t.comp, {});
        }

        let ci = widgetStack.currentItem;
        if (ci) {
            if (ci.targetMasterWidth !== undefined) {
                let dynW = ci.targetMasterWidth;
                masterWindow.animW = dynW; masterWindow.targetW = dynW;
                masterWindow.animX = Math.floor((masterWindow.width / 2) - (dynW / 2));
            }
            if (ci.targetMasterHeight !== undefined) {
                masterWindow.animH = ci.targetMasterHeight;
                masterWindow.targetH = ci.targetMasterHeight;
            }
        }
        masterWindow.isVisible = true;
    }

    Timer {
        id: delayedClear; interval: 200
        onTriggered: { masterWindow.currentActive = "hidden"; widgetStack.clear(); masterWindow.disableMorph = false; }
    }
}
