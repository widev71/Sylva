.pragma library

var Quickshell = null; // Will be injected

function init(qs) {
    Quickshell = qs;
}

function sh(cmd) {
    Quickshell.execDetached(["bash", "-c", cmd]);
}

function setSetting(config, key, value) {
    config.rawSettings[key] = value;
    let safeValue = typeof value === "string" ? `"${value}"` : value;
    if (typeof value === "object") safeValue = JSON.stringify(value).replace(/'/g, "'\\''");

    let cmd = `mkdir -p "$(dirname '${config.settingsJsonPath}')" && ` +
              `[ ! -f '${config.settingsJsonPath}' ] && echo '{}' > '${config.settingsJsonPath}'; ` +
              `jq '. + {"${key}": ${safeValue}}' '${config.settingsJsonPath}' > '${config.settingsJsonPath}.tmp' && ` +
              `mv '${config.settingsJsonPath}.tmp' '${config.settingsJsonPath}'`;
    sh(cmd);
}

function updateJsonBulk(config, dataObj) {
    let jsonStr = JSON.stringify(dataObj).replace(/'/g, "'\\''");
    let cmd = `mkdir -p "$(dirname '${config.settingsJsonPath}')" && ` +
              `[ ! -f '${config.settingsJsonPath}' ] && echo '{}' > '${config.settingsJsonPath}'; ` +
              `jq '. + ${jsonStr}' '${config.settingsJsonPath}' > '${config.settingsJsonPath}.tmp' && ` +
              `mv '${config.settingsJsonPath}.tmp' '${config.settingsJsonPath}'`;
    sh(cmd);
    
    for (let key in dataObj) config.rawSettings[key] = dataObj[key];
}

function updateEnvBulk(config, filePath, envDict) {
    let cmds = [`mkdir -p "$(dirname '${filePath}')"`, `touch '${filePath}'`];
    for (let key in envDict) {
        config.rawEnvs[key] = envDict[key];
        let safeVal = envDict[key].toString().replace(/'/g, "'\\''");
        cmds.push(`if grep -q "^${key}=" '${filePath}'; then ` +
                  `sed -i "s|^${key}=.*|${key}='${safeVal}'|" '${filePath}'; ` +
                  `else echo "${key}='${safeVal}'" >> '${filePath}'; fi`);
    }
    sh(cmds.join(" && "));
}

function saveAppSettings(config) {
    let configObj = {
        "uiScale": config.uiScale,
        "openGuideAtStartup": config.openGuideAtStartup,
        "topbarHelpIcon": config.topbarHelpIcon,
        "wallpaperDir": config.wallpaperDir,
        "language": config.language,
        "kbOptions": config.kbOptions,
        "workspaceCount": config.workspaceCount,
        "showTopHelp": config.showTopHelp,
        "showTopSearch": config.showTopSearch,
        "showTopSettings": config.showTopSettings,
        "showTopKb": config.showTopKb,
        "showTopTodo": config.showTopTodo,
        "showTopNotif": config.showTopNotif,
        "showTopWifi": config.showTopWifi,
        "showTopBt": config.showTopBt,
        "showTopVolume": config.showTopVolume,
        "showTopBattery": config.showTopBattery,
        "profileGithub": config.profileGithub,
        "profileDiscord": config.profileDiscord,
        "profileInstagram": config.profileInstagram,
        "profileTikTok": config.profileTikTok,
        "tpNaturalScroll": config.tpNaturalScroll,
        "tpTapToClick": config.tpTapToClick,
        "tpDisableWhileTyping": config.tpDisableWhileTyping,
        "tpSensitivity": config.tpSensitivity,
        "tpScrollFactor": config.tpScrollFactor,
        "cursorTheme": config.cursorTheme,
        "cursorSize": config.cursorSize
    };

    updateJsonBulk(config, configObj);
    sh("notify-send 'Quickshell' 'Settings Applied Successfully!'");

    if (config.workspaceCount !== config.initialWorkspaceCount) {
        sh(`qs -p "${config.qsScriptsDir}/TopBar.qml" ipc call topbar queueReload`);
        config.initialWorkspaceCount = config.workspaceCount;
    }
    
    sh(`bash "${config.qsScriptsDir}/../fetch_github_cards.sh" &`);
}

function saveWeatherConfig(config) {
    let envs = {
        "OPENMETEO_LAT": config.weatherLat,
        "OPENMETEO_LON": config.weatherLon,
        "WEATHER_LOC_NAME": config.weatherLocName,
        "OPENWEATHER_UNIT": config.weatherUnit
    };
    
    updateEnvBulk(config, config.weatherEnvPath, envs);
    sh(`rm -rf "${config.cacheDir}/weather"`);
    sh("notify-send 'Weather' 'API configuration saved successfully!'");
}

function saveAllKeybinds(config, bindsArray) {
    config.keybindsData = bindsArray;
    setSetting(config, "keybinds", bindsArray);
    sh("notify-send 'Quickshell' 'Keybinds Saved Successfully!'");
}

function saveAllStartup(config, startupArray) {
    config.startupData = startupArray;
    setSetting(config, "startup", startupArray);
    sh("notify-send 'Quickshell' 'Startup entries saved!'");
}

function monIsOverlapping(ax, ay, aw, ah, bx, by, bw, bh) {
    return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
}

function monIsOverlappingAny(config, x, y, w, h, skipIdx) {
    for (let i = 0; i < config.monitorsModel.count; i++) {
        if (i === skipIdx) continue;
        let m = config.monitorsModel.get(i);
        let isP = m.transform === 1 || m.transform === 3;
        let mW = ((isP ? m.resH : m.resW) / m.sysScale) * config.monUiScale;
        let mH = ((isP ? m.resW : m.resH) / m.sysScale) * config.monUiScale;
        if (monIsOverlapping(x, y, w, h, m.uiX, m.uiY, mW, mH)) return true;
    }
    return false;
}

function monGetPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
    let edges = [
        { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH },
        { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH },
        { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH },
        { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }
    ];
    let bestX = pX, bestY = pY, minDist = 999999;
    for (let i = 0; i < 4; i++) {
        let e = edges[i];
        let cx = Math.max(e.x1, Math.min(pX, e.x2));
        let cy = Math.max(e.y1, Math.min(pY, e.y2));
        if (Math.abs(cx - sX) < snapT) cx = sX;
        if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;
        if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;
        if (Math.abs(cy - sY) < snapT) cy = sY;
        if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;
        if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;
        let dist = Math.hypot(pX - cx, pY - cy);
        if (dist < minDist) { minDist = dist; bestX = cx; bestY = cy; }
    }
    return { x: bestX, y: bestY };
}

function monForceLayoutUpdate(config) {
    if (config.monitorsModel.count < 2) return;
    let mIdx = config.monActiveEditIndex;
    let mModel = config.monitorsModel.get(mIdx);
    let isP = mModel.transform === 1 || mModel.transform === 3;
    let mW = ((isP ? mModel.resH : mModel.resW) / mModel.sysScale) * config.monUiScale;
    let mH = ((isP ? mModel.resW : mModel.resH) / mModel.sysScale) * config.monUiScale;
    let bestX = mModel.uiX, bestY = mModel.uiY, bestDist = 999999;
    for (let i = 0; i < config.monitorsModel.count; i++) {
        if (i === mIdx) continue;
        let sModel = config.monitorsModel.get(i);
        let sIsP = sModel.transform === 1 || sModel.transform === 3;
        let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * config.monUiScale;
        let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * config.monUiScale;
        let snapped = monGetPerimeterSnap(mModel.uiX, mModel.uiY, sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);
        let dist = Math.hypot(snapped.x - mModel.uiX, snapped.y - mModel.uiY);
        if (dist < bestDist) { bestDist = dist; bestX = snapped.x; bestY = snapped.y; }
    }
    config.monitorsModel.setProperty(mIdx, "uiX", bestX);
    config.monitorsModel.setProperty(mIdx, "uiY", bestY);
}

function applyMonitors(config) {
    if (config.monitorsModel.count === 0) return;
    if (config.monitorsModel.count === 1) {
        let m = config.monitorsModel.get(0);
        let monitorStr = m.name + "," + m.resW + "x" + m.resH + "@" + m.rate + ",0x0," + m.sysScale;
        if (m.transform !== 0) monitorStr += ",transform," + m.transform;
        let jsonArr = [{ name: m.name, resW: m.resW, resH: m.resH, rate: parseInt(m.rate), x: 0, y: 0, scale: m.sysScale, transform: m.transform }];
        setSetting(config, "monitors", jsonArr);
        sh("hyprctl keyword monitor " + monitorStr + " ; awww kill ; sleep 0.2 ; awww-daemon &");
        Quickshell.execDetached(["notify-send", "Display Update", "Applied: " + m.resW + "x" + m.resH + " @ " + m.rate + "Hz"]);
    } else {
        let rects = [];
        for (let i = 0; i < config.monitorsModel.count; i++) {
            let m = config.monitorsModel.get(i);
            let isP = m.transform === 1 || m.transform === 3;
            let physW = Math.round((isP ? m.resH : m.resW) / m.sysScale);
            let physH = Math.round((isP ? m.resW : m.resH) / m.sysScale);
            rects.push({ x: m.uiX / config.monUiScale, y: m.uiY / config.monUiScale, w: physW, h: physH, resW: m.resW, resH: m.resH, name: m.name, rate: m.rate, sysScale: m.sysScale, transform: m.transform });
        }
        function getTightSnap(pX, pY, sX, sY, sW, sH, mW, mH, t) {
            let cx = pX; let cy = pY;
            if (Math.abs(cx - (sX - mW)) < t) cx = sX - mW;
            else if (Math.abs(cx - (sX + sW)) < t) cx = sX + sW;
            else if (Math.abs(cx - sX) < t) cx = sX;
            else if (Math.abs(cx - (sX + sW - mW)) < t) cx = sX + sW - mW;
            if (Math.abs(cy - (sY - mH)) < t) cy = sY - mH;
            else if (Math.abs(cy - (sY + sH)) < t) cy = sY + sH;
            else if (Math.abs(cy - sY) < t) cy = sY;
            else if (Math.abs(cy - (sY + sH - mH)) < t) cy = sY + sH - mH;
            return {x: cx, y: cy};
        }
        for (let i = 1; i < rects.length; i++) {
            let bestX = rects[i].x, bestY = rects[i].y, bestDist = 999999;
            for (let j = 0; j < i; j++) {
                let r0 = rects[j];
                let snapped = getTightSnap(rects[i].x, rects[i].y, r0.x, r0.y, r0.w, r0.h, rects[i].w, rects[i].h, 25);
                let dist = Math.hypot(rects[i].x - snapped.x, rects[i].y - snapped.y);
                if (dist < bestDist) { bestDist = dist; bestX = Math.round(snapped.x); bestY = Math.round(snapped.y); }
            }
            rects[i].x = bestX; rects[i].y = bestY;
        }
        let finalMinX = 999999, finalMinY = 999999;
        for (let i = 0; i < rects.length; i++) {
            if (rects[i].x < finalMinX) finalMinX = rects[i].x;
            if (rects[i].y < finalMinY) finalMinY = rects[i].y;
        }
        let batchCmds = [], summaryString = "", jsonArr = [];
        for (let i = 0; i < rects.length; i++) {
            let r = rects[i];
            r.x = Math.round(r.x - finalMinX);
            r.y = Math.round(r.y - finalMinY);
            let monitorStr = r.name + "," + r.resW + "x" + r.resH + "@" + r.rate + "," + r.x + "x" + r.y + "," + r.sysScale;
            if (r.transform !== 0) monitorStr += ",transform," + r.transform;
            batchCmds.push("keyword monitor " + monitorStr);
            summaryString += r.name + " ";
            jsonArr.push({ name: r.name, resW: r.resW, resH: r.resH, rate: parseInt(r.rate), x: r.x, y: r.y, scale: r.sysScale, transform: r.transform });
        }
        setSetting(config, "monitors", jsonArr);
        sh("hyprctl --batch '" + batchCmds.join(" ; ") + "' ; awww kill ; sleep 0.2 ; awww-daemon &");
        Quickshell.execDetached(["notify-send", "Display Update", "Applied layout for: " + summaryString.trim()]);
    }
}
