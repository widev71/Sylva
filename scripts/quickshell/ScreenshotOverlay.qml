import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./screenshot"

PanelWindow {
    id: root
    color: "transparent"

    WlrLayershell.namespace:     "qs-screenshot-overlay"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    screen: Quickshell.cursorScreen
    width:  screen.width
    height: screen.height

    // ── Theme + scaling ────────────────────────────────────────────────
    Caching { id: paths }
    Scaler { id: scaler; currentWidth: width }
    function s(val) { return scaler.s(val); }
    MatugenColors { id: _theme }

    property color dimColor:      Qt.alpha(_theme.crust, 0.50)
    property color selectionTint: Qt.alpha(_theme.mauve, 0.05)
    property color handleColor:   _theme.text
    property color accentColor:   _theme.mauve

    // ── Mode state ─────────────────────────────────────────────────────
    property bool isEditMode:  Quickshell.env("QS_SCREENSHOT_EDIT") === "true"
    property string cachedMode: Quickshell.env("QS_CACHED_MODE") || "false"
    property bool isVideoMode: cachedMode === "true"

    onIsVideoModeChanged: {
        Quickshell.execDetached(["bash", "-c",
            "echo '" + (root.isVideoMode ? "true" : "false") + "' > " + paths.getCacheDir("screenshot") + "/video_mode"]);
        if (root.isVideoMode) {
            root.preStartX = root.startX; root.preStartY = root.startY;
            root.preEndX   = root.endX;   root.preEndY   = root.endY;
            root.startX = 0; root.startY = 0; root.endX = root.width; root.endY = root.height;
            root.hasSelection = true;
        } else {
            root.startX = root.preStartX; root.startY = root.preStartY;
            root.endX   = root.preEndX;   root.endY   = root.preEndY;
            if (Math.abs(root.endX - root.startX) < 10 || Math.abs(root.endY - root.startY) < 10)
                root.hasSelection = false;
        }
    }

    // ── Audio persistence ──────────────────────────────────────────────
    property real   deskVol:   Quickshell.env("QS_DESK_VOL")  ? parseFloat(Quickshell.env("QS_DESK_VOL")) : 1.0
    property bool   deskMute:  Quickshell.env("QS_DESK_MUTE") === "true"
    property real   micVol:    Quickshell.env("QS_MIC_VOL")   ? parseFloat(Quickshell.env("QS_MIC_VOL"))  : 1.0
    property bool   micMute:   Quickshell.env("QS_MIC_MUTE")  === "true"
    property string micDevice: Quickshell.env("QS_MIC_DEV")   || ""

    function saveAudioPrefs() {
        let data = `${deskVol},${deskMute},${micVol},${micMute},${micDevice}`
        Quickshell.execDetached(["bash", "-c", `echo '${data}' > ${paths.getStateDir("screenshot")}/audio_prefs`])
    }

    // ── Mic device list ────────────────────────────────────────────────
    ListModel { id: micModel }

    Component.onCompleted: {
        let micData = Quickshell.env("QS_MIC_LIST") || ""
        if (micData.trim() !== "") {
            let lines = micData.trim().split('\n')
            for (let line of lines) {
                let parts = line.split('|')
                if (parts.length >= 2) micModel.append({ devName: parts[0], devDesc: parts.slice(1).join('|') })
            }
        }
        if (root.micDevice === "" && micModel.count > 0) {
            root.micDevice = micModel.get(0).devName;
            saveAudioPrefs();
        }
    }

    // ── Geometry state ─────────────────────────────────────────────────
    property string cachedGeom:  Quickshell.env("QS_CACHED_GEOM") || ""
    property var    cachedParts: cachedGeom.trim() !== "" ? cachedGeom.trim().split(",") : []
    property bool   hasValidCache: cachedParts.length === 4 && parseFloat(cachedParts[2]) > 10

    property real startX: hasValidCache ? parseFloat(cachedParts[0]) : 0
    property real startY: hasValidCache ? parseFloat(cachedParts[1]) : 0
    property real endX:   hasValidCache ? (parseFloat(cachedParts[0]) + parseFloat(cachedParts[2])) : 0
    property real endY:   hasValidCache ? (parseFloat(cachedParts[1]) + parseFloat(cachedParts[3])) : 0

    Behavior on startX { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on startY { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on endX   { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on endY   { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    property bool hasSelection:    hasValidCache
    property bool isSelecting:     false
    property bool isMaximized:     false
    property real preStartX: 0; property real preStartY: 0
    property real preEndX:   0; property real preEndY:   0

    property real selX: Math.min(startX, endX)
    property real selY: Math.min(startY, endY)
    property real selW: Math.abs(endX - startX)
    property real selH: Math.abs(endY - startY)

    property string geometryString: `${Math.round(selX + screen.x)},${Math.round(selY + screen.y)} ${Math.round(selW)}x${Math.round(selH)}`
    property int  interactionMode: 0
    property real anchorX: 0; property real anchorY: 0
    property real initX:   0; property real initY:   0
    property real initW:   0; property real initH:   0

    // ── QR state ───────────────────────────────────────────────────────
    property bool isScanningQr: false
    property bool showQrPopup:  false
    property bool isQrSuccess:  false
    ListModel { id: qrModel }

    // ── Cache helpers ──────────────────────────────────────────────────
    function saveCache() {
        if (root.hasSelection && !root.isVideoMode) {
            let data = Math.round(root.selX) + "," + Math.round(root.selY) + "," + Math.round(root.selW) + "," + Math.round(root.selH)
            Quickshell.execDetached(["bash", "-c", "echo '" + data + "' > " + paths.getCacheDir("screenshot") + "/geometry"])
        }
    }

    // ── Maximize animation ─────────────────────────────────────────────
    ParallelAnimation {
        id: maximizeAnim
        property real targetStartX; property real targetStartY
        property real targetEndX;   property real targetEndY
        NumberAnimation { target: root; property: "startX"; to: maximizeAnim.targetStartX; duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "startY"; to: maximizeAnim.targetStartY; duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "endX";   to: maximizeAnim.targetEndX;   duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "endY";   to: maximizeAnim.targetEndY;   duration: 250; easing.type: Easing.InOutQuad }
        onFinished: root.saveCache()
    }

    function toggleMaximize() {
        if (root.isVideoMode) return;
        if (!isMaximized) {
            preStartX = root.startX; preStartY = root.startY;
            preEndX   = root.endX;   preEndY   = root.endY;
            maximizeAnim.targetStartX = 0; maximizeAnim.targetStartY = 0;
            maximizeAnim.targetEndX = root.width; maximizeAnim.targetEndY = root.height;
            isMaximized = true;
        } else {
            maximizeAnim.targetStartX = preStartX; maximizeAnim.targetStartY = preStartY;
            maximizeAnim.targetEndX   = preEndX;   maximizeAnim.targetEndY   = preEndY;
            isMaximized = false;
        }
        maximizeAnim.restart();
    }

    // ── Keyboard shortcuts ─────────────────────────────────────────────
    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    Shortcut { sequence: "Return"; onActivated: { if (root.hasSelection) root.executeCapture(root.isEditMode && !root.isVideoMode, root.isVideoMode) } }
    Shortcut { sequence: "Tab";   onActivated: root.isVideoMode = !root.isVideoMode }
    Shortcut { sequence: "Left";  onActivated: root.isVideoMode = false }
    Shortcut { sequence: "Right"; onActivated: root.isVideoMode = true }
    Shortcut { sequence: "F11";   onActivated: root.toggleMaximize() }

    // ── Drag + resize MouseArea ────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 20

        function getInteractionMode(mx, my, mods) {
            if (!root.hasSelection) return 1;
            if (mods & Qt.ShiftModifier) return 2;
            let m = s(20)
            let onL = Math.abs(mx - root.selX) <= m
            let onR = Math.abs(mx - (root.selX + root.selW)) <= m
            let onT = Math.abs(my - root.selY) <= m
            let onB = Math.abs(my - (root.selY + root.selH)) <= m
            let inX = mx >= (root.selX - m) && mx <= (root.selX + root.selW + m)
            let inY = my >= (root.selY - m) && my <= (root.selY + root.selH + m)
            if (onT && onL) return 3;  if (onT && onR) return 5;
            if (onB && onL) return 8;  if (onB && onR) return 10;
            if (onT && inX) return 4;  if (onB && inX) return 9;
            if (onL && inY) return 6;  if (onR && inY) return 7;
            return 1;
        }

        onPositionChanged: function(mouse) {
            if (root.isVideoMode) { cursorShape = Qt.ArrowCursor; return; }
            let mode = root.isSelecting ? root.interactionMode : getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
            switch(mode) {
                case 2: cursorShape = Qt.ClosedHandCursor; break;
                case 3: case 10: cursorShape = Qt.SizeFDiagCursor; break;
                case 5: case 8:  cursorShape = Qt.SizeBDiagCursor; break;
                case 4: case 9:  cursorShape = Qt.SizeVerCursor; break;
                case 6: case 7:  cursorShape = Qt.SizeHorCursor; break;
                default: cursorShape = Qt.CrossCursor; break;
            }
            if (!root.isSelecting) return;
            let dx = mouse.x - root.anchorX; let dy = mouse.y - root.anchorY
            let clamp = (val, min, max) => Math.max(min, Math.min(max, val))
            if (root.interactionMode === 1) {
                root.endX = clamp(mouse.x, 0, root.width); root.endY = clamp(mouse.y, 0, root.height)
            } else if (root.interactionMode === 2) {
                let tx = clamp(root.initX + dx, 0, root.width - root.initW); let ty = clamp(root.initY + dy, 0, root.height - root.initH)
                root.startX = tx; root.startY = ty; root.endX = tx + root.initW; root.endY = ty + root.initH;
            } else {
                let nx = root.initX, ny = root.initY, nw = root.initW, nh = root.initH
                if ([3,6,8].includes(root.interactionMode)) { nx = clamp(root.initX + dx, 0, root.initX + root.initW - 10); nw = root.initW + (root.initX - nx) }
                if ([5,7,10].includes(root.interactionMode)) { nw = clamp(root.initW + dx, 10, root.width - root.initX) }
                if ([3,4,5].includes(root.interactionMode)) { ny = clamp(root.initY + dy, 0, root.initY + root.initH - 10); nh = root.initH + (root.initY - ny) }
                if ([8,9,10].includes(root.interactionMode)) { nh = clamp(root.initH + dy, 10, root.height - root.initY) }
                root.startX = nx; root.startY = ny; root.endX = nx + nw; root.endY = ny + nh;
            }
        }
        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) { Qt.quit(); return; }
            if (root.isVideoMode) return;
            root.isScanningQr = false; root.showQrPopup = false; qrWaitTimer.stop();
            maximizeAnim.stop()
            root.interactionMode = getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
            root.isSelecting = true
            if (root.interactionMode !== 1) root.isMaximized = false;
            root.anchorX = mouse.x; root.anchorY = mouse.y
            root.initX = root.selX; root.initY = root.selY; root.initW = root.selW; root.initH = root.selH;
            if (root.interactionMode === 1) {
                let clamp = (val, min, max) => Math.max(min, Math.min(max, val))
                root.startX = clamp(mouse.x, 0, root.width); root.startY = clamp(mouse.y, 0, root.height);
                root.endX = root.startX; root.endY = root.startY; root.hasSelection = false; root.isMaximized = false;
            }
        }
        onReleased: {
            if (root.isSelecting) {
                root.isSelecting = false
                if (root.selW > 10 && root.selH > 10) { root.hasSelection = true; root.saveCache() }
                else { root.hasSelection = false }
            }
        }
    }

    // ── UI components ──────────────────────────────────────────────────
    SelectionOverlay {
        selX: root.selX; selY: root.selY; selW: root.selW; selH: root.selH
        dimColor:      root.dimColor
        selectionTint: root.selectionTint
        accentColor:   root.accentColor
        greenColor:    _theme.green
        redColor:      _theme.red
        isSelecting:   root.isSelecting
        hasSelection:  root.hasSelection
        isVideoMode:   root.isVideoMode
        showQrPopup:   root.showQrPopup
        isQrSuccess:   root.isQrSuccess
    }

    CornerHandles {
        selX: root.selX; selY: root.selY; selW: root.selW; selH: root.selH
        handleColor:   root.handleColor
        accentColor:   root.accentColor
        hasSelection:  root.hasSelection
        isSelecting:   root.isSelecting
        isScanningQr:  root.isScanningQr
        showQrPopup:   root.showQrPopup
        isVideoMode:   root.isVideoMode
    }

    ToolbarPanel {
        id: toolbar
        z: 30
        theme:        _theme
        isVideoMode:  root.isVideoMode
        hasSelection: root.hasSelection
        isSelecting:  root.isSelecting
        isScanningQr: root.isScanningQr
        showQrPopup:  root.showQrPopup
        isMaximized:  root.isMaximized
        accentColor:  root.accentColor
        micModel:     micModel
        deskVol:      root.deskVol;  deskMute: root.deskMute
        micVol:       root.micVol;   micMute:  root.micMute
        micDevice:    root.micDevice
        s:            root.s

        fitsOutsideBottom: (root.selY + root.selH + totalHeight + s(15)) <= root.height
        x: (root.width - width) / 2
        y: root.height - height - s(40)

        onCaptureClicked:        function(openEditor, isRecord) { root.executeCapture(openEditor, isRecord) }
        onToggleMaximizeClicked: root.toggleMaximize()
        onQrScanClicked:         root.performQrScan()
        onEditCaptureClicked:    root.executeCapture(true, false)
        onRequestDeskVolChange:  function(v) { root.deskVol   = v; root.saveAudioPrefs() }
        onRequestDeskMuteChange: function(m) { root.deskMute  = m; root.saveAudioPrefs() }
        onRequestMicVolChange:   function(v) { root.micVol    = v; root.saveAudioPrefs() }
        onRequestMicMuteChange:  function(m) { root.micMute   = m; root.saveAudioPrefs() }
        onRequestMicDeviceChange:function(d) { root.micDevice = d; root.saveAudioPrefs() }
    }

    QrResultPopup {
        anchors.fill: parent
        qrModel:     qrModel
        theme:       _theme
        showQrPopup: root.showQrPopup
        isSelecting: root.isSelecting
        s:           root.s
        onCopyText:  function(txt) { Quickshell.execDetached(["bash", "-c", `echo -n '${txt.replace(/'/g, "'\\''")}' | wl-copy`]) }
        onOpenUrl:   function(url) { Quickshell.execDetached(["xdg-open", url]); Qt.quit() }
        onDismiss:   root.showQrPopup = false
    }

    // ── QR process ─────────────────────────────────────────────────────
    Process {
        id: qrReaderProcess
        property string accumulated: ""
        command: ["cat", paths.getRunDir("screenshot") + "/qr_result"]
        stdout: SplitParser { splitMarker: ""; onRead: function(data) { qrReaderProcess.accumulated += data } }

        onExited: function(exitCode) {
            let res = qrReaderProcess.accumulated.trim()
            qrReaderProcess.accumulated = ""
            root.isScanningQr = false
            qrModel.clear()

            if (exitCode !== 0 || res === "") {
                qrModel.append({ qX: root.selX + (root.selW/2), qY: root.selY + (root.selH/2), qW: 0, qH: 0,
                    qText: "Scan timed out or failed.", qSuccess: false,
                    qTargetX: root.selX + (root.selW/2) - s(100), qTargetY: root.selY + (root.selH/2), qBaseScale: 1.0, fitsTop: false })
                root.isQrSuccess = false; root.showQrPopup = true; return
            }

            let lines = res.split('\n'); let anySuccess = false; let qrs = []
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim(); if (line === "") continue;
                let di = line.indexOf('|||'); if (di === -1) continue;
                let coordStr = line.substring(0, di);
                let actualText = line.substring(di + 3).replace(/\\n/g, '\n').replace(/\\\\/g, '\\');
                let coords = coordStr.split(',');
                if (coords.length === 4 && !isNaN(parseInt(coords[0]))) {
                    let x=parseInt(coords[0]),y=parseInt(coords[1]),w=parseInt(coords[2]),h=parseInt(coords[3]);
                    let ok = !(actualText==="NOT_FOUND"||actualText.startsWith("ERROR:"));
                    if (ok) anySuccess = true;
                    let txt = ok ? actualText.replace(/^QR-Code:/, "") : (actualText==="NOT_FOUND"?"No QR code found.":actualText);
                    let estW=Math.min(s(400),txt.length*s(8.5)); let pw=estW+(ok?s(140):s(40)); let ph=s(52);
                    let absX=root.selX+x,absY=root.selY+y; let cx=absX+(w/2);
                    let fitsTop=(absY-ph-s(15))>=root.selY;
                    let tX=Math.max(s(10),Math.min(root.width-pw-s(10),cx-(pw/2)));
                    let tY=fitsTop?(absY-ph-s(15)):(absY+h+s(15));
                    qrs.push({qX:absX,qY:absY,qW:w,qH:h,qText:txt,qSuccess:ok,pw:pw,ph:ph,targetX:tX,targetY:tY,cx:tX+(pw/2),cy:tY+(ph/2),scale:1.0,fitsTop:fitsTop});
                }
            }

            // Overlap scale-down passes
            for (let pass=0;pass<5;pass++) {
                for (let i=0;i<qrs.length;i++) for (let j=i+1;j<qrs.length;j++) {
                    let A=qrs[i],B=qrs[j];
                    let dx=Math.abs(A.cx-B.cx),dy=Math.abs(A.cy-B.cy);
                    let rx=(A.pw*A.scale+B.pw*B.scale)/2+s(10), ry=(A.ph*A.scale+B.ph*B.scale)/2+s(10);
                    if (dx<rx&&dy<ry) {
                        let fx=dx>0?(dx-s(10))*2/(A.pw+B.pw):0, fy=dy>0?(dy-s(10))*2/(A.ph+B.ph):0;
                        let mf=Math.max(0.35,Math.max(fx,fy));
                        A.scale=Math.min(A.scale,mf); B.scale=Math.min(B.scale,mf);
                    }
                }
            }

            if (qrs.length===0) {
                qrModel.append({qX:root.selX+(root.selW/2),qY:root.selY+(root.selH/2),qW:0,qH:0,
                    qText:"No QR code found.",qSuccess:false,
                    qTargetX:root.selX+(root.selW/2)-s(100),qTargetY:root.selY+(root.selH/2),qBaseScale:1.0,fitsTop:false});
            } else {
                for (let i=0;i<qrs.length;i++) qrModel.append({qX:qrs[i].qX,qY:qrs[i].qY,qW:qrs[i].qW,qH:qrs[i].qH,qText:qrs[i].qText,qSuccess:qrs[i].qSuccess,qTargetX:qrs[i].targetX,qTargetY:qrs[i].targetY,qBaseScale:qrs[i].scale,fitsTop:qrs[i].fitsTop});
            }

            root.isQrSuccess = anySuccess; root.showQrPopup = true
            Quickshell.execDetached(["bash", "-c", "rm -f " + paths.getRunDir("screenshot") + "/qr_result"])
        }
    }

    Timer { id: qrWaitTimer; interval: 1200; repeat: false; onTriggered: qrReaderProcess.running = true }

    function performQrScan() {
        Quickshell.execDetached(["bash", "-c", "rm -f " + paths.getRunDir("screenshot") + "/qr_result"])
        root.isScanningQr = true; root.showQrPopup = false; qrModel.clear()
        Quickshell.execDetached(["bash", "-c", `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}" --scan-qr`])
        qrWaitTimer.start()
    }

    Timer {
        id: captureTimer; interval: 200; repeat: false
        property string pendingCmd: ""
        onTriggered: { Quickshell.execDetached(["bash", "-c", pendingCmd]); Qt.quit() }
    }

    function executeCapture(openEditor, isRecord) {
        let cmd = `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}"`
        if (isRecord) {
            cmd += " --record"
            cmd += ` --desk-vol ${root.deskVol} --desk-mute ${root.deskMute}`
            cmd += ` --mic-vol ${root.micVol} --mic-mute ${root.micMute}`
            if (root.micDevice !== "") cmd += ` --mic-dev "${root.micDevice}"`
        }
        if (openEditor) cmd += " --edit"
        root.visible = false
        captureTimer.pendingCmd = cmd
        captureTimer.start()
    }
}
