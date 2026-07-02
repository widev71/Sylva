import QtQuick
import Quickshell
import Quickshell.Io

// Widget preloader: eagerly instantiates widgets into a hidden container
// so they're ready to display without a cold-start stutter.
// Also watches settings.json for uiScale changes.
Item {
    id: root

    // ── Props injected by master window ───────────────────────────────
    required property var  getLayout        // function(name) → layout object
    required property var  notifModel
    required property var  liveNotifs
    required property real windowWidth
    required property real windowHeight

    // ── Exposed output ────────────────────────────────────────────────
    property var  widgetCache:   ({})
    property real globalUiScale: 1.0

    signal uiScaleChanged(real newScale)

    // ── Hidden preload container ──────────────────────────────────────
    Item { id: preloaderContainer; visible: false }

    function preloadWidget(name) {
        if (widgetCache[name]) return;
        let t = root.getLayout(name);
        if (!t || !t.comp) return;

        let comp = Qt.createComponent(t.comp);
        if (comp.status === Component.Error) {
            console.log("Error preloading widget " + name + ":", comp.errorString());
            return;
        }

        let obj = comp.createObject(preloaderContainer, { "visible": false });
        if (obj) {
            if (obj.notifModel  !== undefined) obj.notifModel  = root.notifModel;
            if (obj.liveNotifs  !== undefined) obj.liveNotifs  = root.liveNotifs;
            if (obj.layoutWidth !== undefined) obj.layoutWidth = t.w;
            if (obj.layoutHeight !== undefined) obj.layoutHeight = t.h;
            widgetCache[name] = obj;
        }
    }

    // ── Staggered startup preload ─────────────────────────────────────
    Component.onCompleted: {
        Qt.callLater(() => preloadWidget("settings"));
        preloadStaggerTimer.start();
    }

    Timer {
        id: preloadStaggerTimer; interval: 900; repeat: false
        onTriggered: { preloadWidget("search"); preloadWidget("help"); }
    }

    // ── settings.json reader ──────────────────────────────────────────
    Process {
        id: settingsReader
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        let parsed = JSON.parse(this.text);
                        if (parsed.uiScale !== undefined && root.globalUiScale !== parsed.uiScale) {
                            root.globalUiScale = parsed.uiScale;
                            root.uiScaleChanged(parsed.uiScale);
                        }
                    }
                } catch (e) {
                    console.log("Error parsing settings.json:", e);
                }
            }
        }
    }

    // ── settings.json watcher ─────────────────────────────────────────
    Process {
        id: settingsWatcher
        command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                settingsReader.running = false;
                settingsReader.running = true;
                settingsWatcher.running = false;
                settingsWatcher.running = true;
            }
        }
    }
}
