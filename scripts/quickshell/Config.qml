pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "SettingsBackend.js" as Backend

Item {
    id: config

    Caching { id: paths }

    // =========================================================================
    // Core Paths & Environment
    // =========================================================================
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string hyprDir: homeDir + "/.config/hypr"
    readonly property string qsScriptsDir: hyprDir + "/scripts/quickshell"
    readonly property string cacheDir: paths.cacheDir
    
    readonly property string settingsJsonPath: hyprDir + "/settings.json"
    readonly property string weatherEnvPath: qsScriptsDir + "/calendar/.env"

    // State Tracking
    property bool dataReady: false
    property var rawSettings: ({})
    property var rawEnvs: ({})

    // =========================================================================
    // Generic Utilities (Use these in ANY widget!)
    // =========================================================================

    function sh(cmd) { Backend.sh(cmd); }
    function getSetting(key, fallbackValue) { return rawSettings.hasOwnProperty(key) ? rawSettings[key] : fallbackValue; }
    function setSetting(key, value) { Backend.setSetting(config, key, value); }
    function updateJsonBulk(dataObj) { Backend.updateJsonBulk(config, dataObj); }
    function getEnv(key, fallbackValue) { return rawEnvs.hasOwnProperty(key) ? rawEnvs[key] : fallbackValue; }
    function updateEnvBulk(filePath, envDict) { Backend.updateEnvBulk(config, filePath, envDict); }

    // =========================================================================
    // Legacy Specific Properties (Bound to Settings.qml)
    // =========================================================================
    property real uiScale: 1.0
    property bool openGuideAtStartup: true
    property bool topbarHelpIcon: true
    property int workspaceCount: 8
    property int initialWorkspaceCount: 8
    property string wallpaperDir: Quickshell.env("WALLPAPER_DIR") || (homeDir + "/Pictures/Wallpapers")
    property string language: ""
    property string kbOptions: "grp:alt_shift_toggle"

    property string weatherUnit: "metric"
    property string weatherLat: ""
    property string weatherLon: ""
    property string weatherLocName: ""

    // Top Bar Widget Visibility Flags
    property bool showTopHelp: getSetting("showTopHelp", true)
    property bool showTopSearch: getSetting("showTopSearch", true)
    property bool showTopSettings: getSetting("showTopSettings", true)
    property bool showTopKb: getSetting("showTopKb", true)
    property bool showTopTodo: getSetting("showTopTodo", true)
    property bool showTopNotif: getSetting("showTopNotif", true)
    property bool showTopWifi: getSetting("showTopWifi", true)
    property bool showTopBt: getSetting("showTopBt", false)
    property bool showTopVolume: getSetting("showTopVolume", true)
    property bool showTopBattery: getSetting("showTopBattery", true)

    property string profileGithub: "witya"
    property string profileDiscord: "widev71"
    property string profileInstagram: "widev71"
    property string profileTikTok: "widev71"

    property var keybindsData: []
    signal keybindsLoaded()

    property bool tpNaturalScroll: true
    property bool tpTapToClick: true
    property bool tpDisableWhileTyping: true
    property real tpSensitivity: 0.0
    property real tpScrollFactor: 1.0

    property string cursorTheme: "macOS"
    property int cursorSize: 24

    property var startupData: []
    signal startupLoaded()

    // =========================================================================
    // Settings Save Functions
    // =========================================================================
    function saveAppSettings() { Backend.saveAppSettings(config); }
    function saveWeatherConfig() { Backend.saveWeatherConfig(config); }
    function saveAllKeybinds(bindsArray) { Backend.saveAllKeybinds(config, bindsArray); }
    function saveAllStartup(startupArray) { Backend.saveAllStartup(config, startupArray); }

    // =========================================================================
    // Monitor Management
    // =========================================================================
    property alias monitorsModel: _monitorsModel
    ListModel { id: _monitorsModel }
    property int monActiveEditIndex: 0
    property real monUiScale: 0.10
    property int monOriginalOriginX: 0
    property int monOriginalOriginY: 0

    function monIsOverlapping(ax, ay, aw, ah, bx, by, bw, bh) { return Backend.monIsOverlapping(ax, ay, aw, ah, bx, by, bw, bh); }
    function monIsOverlappingAny(x, y, w, h, skipIdx) { return Backend.monIsOverlappingAny(config, x, y, w, h, skipIdx); }
    function monGetPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) { return Backend.monGetPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT); }
    function monForceLayoutUpdate() { Backend.monForceLayoutUpdate(config); }
    function applyMonitors() { Backend.applyMonitors(config); }

    property alias monDelayedLayoutUpdate: _monDelayedLayoutUpdate
    Timer {
        id: _monDelayedLayoutUpdate
        interval: 10; running: false; repeat: false
        onTriggered: config.monForceLayoutUpdate()
    }

    property alias displayPoller: _displayPoller
    Process {
        id: _displayPoller
        command: ["hyprctl", "monitors", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    config.monitorsModel.clear();
                    let minX = 999999, minY = 999999;
                    for (let i = 0; i < data.length; i++) {
                        if (data[i].x < minX) minX = data[i].x;
                        if (data[i].y < minY) minY = data[i].y;
                    }
                    config.monOriginalOriginX = minX !== 999999 ? minX : 0;
                    config.monOriginalOriginY = minY !== 999999 ? minY : 0;
                    for (let i = 0; i < data.length; i++) {
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0;
                        let tf = data[i].transform !== undefined ? data[i].transform : 0;
                        let normalizedX = (data[i].x - minX) * config.monUiScale;
                        let normalizedY = (data[i].y - minY) * config.monUiScale;
                        config.monitorsModel.append({
                            name: data[i].name, resW: data[i].width, resH: data[i].height,
                            sysScale: scl, rate: Math.round(data[i].refreshRate).toString(),
                            uiX: normalizedX, uiY: normalizedY, transform: tf,
                            availableModes: JSON.stringify(data[i].availableModes || [])
                        });
                        if (data[i].focused) config.monActiveEditIndex = i;
                    }
                    config.monForceLayoutUpdate();
                } catch(e) {}
            }
        }
    }

    // =========================================================================
    // Boot Initialization (Runs once on start)
    // =========================================================================
    Component.onCompleted: {
        Backend.init(Quickshell);
        settingsReader.running = true;
        envReader.running = true;
    }

    Process {
        id: envReader
        command: ["bash", "-c", `cat "${config.weatherEnvPath}" 2>/dev/null || echo ''`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text ? this.text.trim().split('\n') : [];
                for (let line of lines) {
                    line = line.trim();
                    let parts = line.split("=");
                    if (parts.length >= 2) {
                        let key = parts[0].trim();
                        let val = parts.slice(1).join("=").replace(/^['"]|['"]$/g, '').trim();
                        config.rawEnvs[key] = val;
                        
                        if (key === "OPENMETEO_LAT") config.weatherLat = val;
                        else if (key === "OPENMETEO_LON") config.weatherLon = val;
                        else if (key === "WEATHER_LOC_NAME") config.weatherLocName = val;
                        else if (key === "OPENWEATHER_UNIT") config.weatherUnit = val;
                    }
                }
            }
        }
    }

    Process {
        id: settingsReader
        command: ["bash", "-c", `cat "${config.settingsJsonPath}" 2>/dev/null || echo '{}'`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        config.rawSettings = JSON.parse(this.text);
                        
                        // Map explicitly defined properties
                        if (config.rawSettings.uiScale !== undefined) config.uiScale = config.rawSettings.uiScale;
                        if (config.rawSettings.openGuideAtStartup !== undefined) config.openGuideAtStartup = config.rawSettings.openGuideAtStartup;
                        if (config.rawSettings.topbarHelpIcon !== undefined) config.topbarHelpIcon = config.rawSettings.topbarHelpIcon;
                        if (config.rawSettings.wallpaperDir !== undefined) config.wallpaperDir = config.rawSettings.wallpaperDir;
                        if (config.rawSettings.language !== undefined && config.rawSettings.language !== "") config.language = config.rawSettings.language;
                        if (config.rawSettings.kbOptions !== undefined) config.kbOptions = config.rawSettings.kbOptions;
                        if (config.rawSettings.workspaceCount !== undefined) {
                            config.workspaceCount = config.rawSettings.workspaceCount;
                            config.initialWorkspaceCount = config.rawSettings.workspaceCount; 
                        }
                        if (config.rawSettings.profileGithub !== undefined) config.profileGithub = config.rawSettings.profileGithub;
                        if (config.rawSettings.profileDiscord !== undefined) config.profileDiscord = config.rawSettings.profileDiscord;
                        if (config.rawSettings.profileInstagram !== undefined) config.profileInstagram = config.rawSettings.profileInstagram;
                        if (config.rawSettings.profileTikTok !== undefined) config.profileTikTok = config.rawSettings.profileTikTok;
                        
                        if (config.rawSettings.tpNaturalScroll !== undefined) config.tpNaturalScroll = config.rawSettings.tpNaturalScroll;
                        if (config.rawSettings.tpTapToClick !== undefined) config.tpTapToClick = config.rawSettings.tpTapToClick;
                        if (config.rawSettings.tpDisableWhileTyping !== undefined) config.tpDisableWhileTyping = config.rawSettings.tpDisableWhileTyping;
                        if (config.rawSettings.tpSensitivity !== undefined) config.tpSensitivity = config.rawSettings.tpSensitivity;
                        if (config.rawSettings.tpScrollFactor !== undefined) config.tpScrollFactor = config.rawSettings.tpScrollFactor;
                        
                        if (config.rawSettings.cursorTheme !== undefined) config.cursorTheme = config.rawSettings.cursorTheme;
                        if (config.rawSettings.cursorSize !== undefined) config.cursorSize = config.rawSettings.cursorSize;
                        
                        // Map Keybinds
                        if (config.rawSettings.keybinds !== undefined && Array.isArray(config.rawSettings.keybinds)) {
                            let tempBinds = [];
                            for (let k of config.rawSettings.keybinds) {
                                tempBinds.push({
                                    type: k.type || "bind",
                                    mods: k.mods || "",
                                    key: k.key || "",
                                    dispatcher: k.dispatcher || "exec",
                                    command: k.command || "",
                                    isEditing: false
                                });
                            }
                            config.keybindsData = tempBinds;
                        } else {
                            config.keybindsData = [];
                        }

                        // Map Startups
                        if (config.rawSettings.startup !== undefined && Array.isArray(config.rawSettings.startup)) {
                            let tempStartup = [];
                            for (let s of config.rawSettings.startup) {
                                tempStartup.push({ command: s.command || "" });
                            }
                            config.startupData = tempStartup;
                        } else {
                            config.startupData = [];
                        }
                    } else {
                        config.saveAppSettings();
                        config.keybindsData = [];
                        config.saveAllKeybinds([]);
                        config.startupData = [];
                    }
                } catch (e) {
                    console.log("Error parsing global settings:", e);
                    config.keybindsData = [];
                    config.startupData = [];
                }
                config.keybindsLoaded();
                config.startupLoaded();
                config.dataReady = true;
            }
        }
    }
}
