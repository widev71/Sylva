import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick3D
import "assets" as Assets
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    focus: true

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color mauve: _theme.mauve || "#cba6f7"

    property var allApps: []
    
    // When hovering over an app, slow down the orbit
    property real orbitSpeed: isHoveringAny ? 0.05 : 0.4
    Behavior on orbitSpeed { NumberAnimation { duration: 500 } }
    
    // Global transform properties
    property real moonRotX: 15
    property real moonRotY: 0
    property real universeZoom: 1.0
    property real povPitch: 1.0
    
    property bool isHoveringAny: false

    Process {
        id: appFetcher
        running: true
        command: ["bash", "-c", "python3 " + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/applauncher/app_fetcher.py"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        window.allApps = JSON.parse(this.text);
                        filterApps("");
                    }
                } catch(e) {
                    console.log("Error parsing apps list: ", e);
                }
            }
        }
    }

    ListModel {
        id: appModel
    }

    function filterApps(query) {
        let q = query.toLowerCase();
        let filtered = [];
        for (let i = 0; i < allApps.length; i++) {
            if (allApps[i].name.toLowerCase().includes(q) || allApps[i].exec.toLowerCase().includes(q)) {
                filtered.push(allApps[i]);
            }
        }
        
        // Populate model
        appModel.clear();
        
        // Calculate orbit parameters so they don't jump around randomly when filtering
        // We give each app a deterministic orbit radius and phase based on its name hash or index
        for (let i = 0; i < filtered.length; i++) {
            let app = filtered[i];
            
            // simple hash for phase
            let hash = 0;
            for (let j = 0; j < app.name.length; j++) {
                hash = app.name.charCodeAt(j) + ((hash << 5) - hash);
            }
            
            let orbitPhase = Math.abs(hash) % 100 / 100.0 * Math.PI * 2;
            let orbitRadiusX = window.s(450) + (Math.abs(hash * 31) % window.s(500));
            let orbitRadiusY = window.s(150) + (Math.abs(hash * 17) % window.s(250));
            let speedMult = 0.5 + (Math.abs(hash * 7) % 100 / 100.0);
            if (hash % 2 === 0) speedMult *= -1; // some orbit backwards
            
            appModel.append({
                "name": app.name,
                "icon": app.icon,
                "exec": app.exec,
                "orbitPhase": orbitPhase,
                "orbitRadiusX": orbitRadiusX,
                "orbitRadiusY": orbitRadiusY,
                "speedMult": speedMult
            });
        }
    }

    // Intro Animation
    property real introPhase: 0
    property real outroPhase: 0
    
    NumberAnimation on introPhase {
        id: introPhaseAnim
        from: 0; to: 1; duration: 1500; easing.type: Easing.OutQuart; running: true
    }
    
    NumberAnimation on outroPhase {
        id: outroPhaseAnim
        from: 0; to: 1; duration: 800; easing.type: Easing.InBack; running: false
        onFinished: {
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
            outroPhase = 0; // reset for next time
        }
    }

    Connections {
        target: window
        function onVisibleChanged() {
            if (window.visible) {
                introPhase = 0;
                outroPhase = 0;
                searchInput.text = "";
                searchInput.forceActiveFocus();
                introPhaseAnim.restart();
                filterApps("");
                load3DTimer.restart();
            } else {
                planet3DLoader.sourceComponent = undefined;
                load3DTimer.stop();
            }
        }
    }

    Keys.onEscapePressed: {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
        event.accepted = true;
    }

    // -------------------------------------------------------------------------
    // COSMIC BACKGROUND
    // -------------------------------------------------------------------------
    Image {
        id: cosmicBg
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/applauncher/assets/background2.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: window.introPhase
        scale: 1.2 - (window.introPhase * 0.2) // slight zoom in on appear
    }

    // Global Drag & Wheel for POV and Zoom
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.OpenHandCursor
        
        // Disable drag if outro is playing
        enabled: outroPhase === 0
        
        property real lastX: 0
        property real lastY: 0
        
        onDoubleClicked: {
            if (window.outroPhase === 0) outroPhaseAnim.restart();
        }
        
        onPressed: function(mouse) {
            cursorShape = Qt.ClosedHandCursor
            lastX = mouse.x
            lastY = mouse.y
        }
        onReleased: {
            cursorShape = Qt.OpenHandCursor
        }
        onPositionChanged: function(mouse) {
            if (pressed) {
                let dx = mouse.x - lastX
                let dy = mouse.y - lastY
                
                window.moonRotY += dx * 0.5
                
                // Dragging Y changes the POV pitch
                window.povPitch -= dy * 0.005
                window.povPitch = Math.max(0.0, Math.min(2.5, window.povPitch))
                window.moonRotX = window.povPitch * 15.0
                
                lastX = mouse.x
                lastY = mouse.y
            }
        }
        
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                window.universeZoom += 0.1;
            } else {
                window.universeZoom -= 0.1;
                if (window.universeZoom < 0.2) window.universeZoom = 0.2;
            }
        }
    }

    // -------------------------------------------------------------------------
    // THE UNIVERSE (Draggable & Zoomable)
    // -------------------------------------------------------------------------
    Item {
        id: universe
        width: window.width
        height: window.height
        x: 0
        y: 0
        scale: window.universeZoom

        // -------------------------------------------------------------------------
        // 3D PLANET (Deferred load to prevent Wayland crash)
        // -------------------------------------------------------------------------
        Loader {
            id: planet3DLoader
            z: 5 // Put moon at z-level 5 so apps at z: 0 go behind it, and z: 10 go in front!
            width: window.s(3000)
            height: window.s(3000)
            anchors.centerIn: parent
            
            // Float up on intro, fade out on outro
            y: (parent.height / 2 - height / 2) + ((1.0 - window.introPhase) * -500)
            opacity: window.introPhase * (1.0 - window.outroPhase)
            scale: 1.0 - window.outroPhase // Shrink planet on close
        }
        
        Timer {
            id: load3DTimer
            interval: 500
            running: false
            onTriggered: planet3DLoader.sourceComponent = planet3DComponent
        }
        
        Component {
            id: planet3DComponent
            View3D {
                anchors.fill: parent
                
                environment: SceneEnvironment {
                    clearColor: "transparent"
                    backgroundMode: SceneEnvironment.Transparent
                }

                PerspectiveCamera {
                    id: camera
                    z: 600
                }

                DirectionalLight {
                    eulerRotation.x: -30
                    eulerRotation.y: -70
                    ambientColor: Qt.rgba(0.2, 0.2, 0.3, 1.0)
                    brightness: 2.0
                }

                Node {
                    id: moonContainer
                    
                    eulerRotation.x: window.moonRotX
                    eulerRotation.y: window.moonRotY
                    
                    // Auto-spin gently (1 degree per second)
                    FrameAnimation {
                        running: true
                        onTriggered: window.moonRotY += frameTime * 1.0
                    }
                    
                    // Load the converted .glb mesh directly!
                    Assets.Ceres {
                        scale: Qt.vector3d(22.0, 22.0, 22.0)
                    }
                }
            }
        }

        // -------------------------------------------------------------------------
        // ASTEROID APPS (2D Orbiting)
        // -------------------------------------------------------------------------
        Repeater {
            model: appModel
            
            delegate: Item {
                id: appDelegate
                width: window.s(80)
                height: window.s(100)
                
                // -------------------------------------------------------------
                // SEARCH FILTER LOGIC
                // -------------------------------------------------------------
                property string searchStr: searchInput.text.trim().toLowerCase()
                property bool isMatch: searchStr === "" || model.name.toLowerCase().indexOf(searchStr) !== -1
                
                // Orbit Math
                property real currentAngle: model.orbitPhase
                
                FrameAnimation {
                    running: true
                    onTriggered: {
                        appDelegate.currentAngle += (frameTime * window.orbitSpeed * model.speedMult);
                    }
                }
                
                // Hyperdrive out effect: expand orbit greatly based on outroPhase
                property real dynamicOrbitX: model.orbitRadiusX * (1.0 + window.outroPhase * 15.0)
                property real dynamicOrbitY: (model.orbitRadiusY * window.povPitch) * (1.0 + window.outroPhase * 15.0)
                
                // Position in orbit
                x: (parent.width / 2) + Math.cos(currentAngle) * dynamicOrbitX - (width / 2)
                y: (parent.height / 2) + Math.sin(currentAngle) * dynamicOrbitY - (height / 2)
                
                // Z-Depth scaling (simulating 3D)
                property real zDepth: Math.sin(currentAngle)
                
                z: zDepth > 0 ? 10 : 0 // Bring to front when in front of planet (z: 5)
                // Base scale from depth
                property real baseScale: 0.5 + ((zDepth + 1.0) / 2.0) * 0.8
                
                // Hover scale bonus
                property real hoverScale: appMa.containsMouse ? 1.3 : 1.0
                
                // Hyperdrive out makes them fly past the screen (scale up)
                scale: baseScale * (1.0 + window.outroPhase * 2.0) * hoverScale
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                
                // Instead of fading out too much, let the moon naturally hide it!
                // Fade to 0 during outro. Also fade out if it doesn't match the search!
                property real searchOpacity: isMatch ? 1.0 : 0.05
                property real depthOpacity: zDepth > 0 ? 1.0 : 0.6 + ((zDepth + 1.0) / 2.0) * 0.4
                opacity: depthOpacity * window.introPhase * (1.0 - window.outroPhase) * searchOpacity
                Behavior on opacity { NumberAnimation { duration: 300 } }
                
                // Highlight glow when hovered or matching search
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 1.2
                    height: parent.height * 1.2
                    radius: width / 2
                    color: window.mauve
                    opacity: (appMa.containsMouse || (searchStr !== "" && isMatch)) ? 0.3 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    z: -1
                }
                
                // Hover Interaction
                MouseArea {
                    id: appMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onEntered: window.isHoveringAny = true
                    onExited: window.isHoveringAny = false
                    
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", model.exec]);
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                    }
                }
                
                // App Icon & Label
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: window.s(8)
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: window.s(64)
                        height: window.s(64)
                        radius: width / 2
                        color: appMa.containsMouse ? Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.7) : "transparent"
                        border.color: appMa.containsMouse ? window.mauve : "transparent"
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        
                        Image {
                            anchors.centerIn: parent
                            width: window.s(48)
                            height: window.s(48)
                            source: (model.icon && model.icon !== "") ? ("image://icon/" + model.icon) : "image://icon/application-x-executable"
                            sourceSize: Qt.size(width, height)
                            
                            scale: appMa.pressed ? 0.9 : (appMa.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            
                            layer.enabled: appMa.containsMouse
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: window.mauve
                                shadowBlur: 1.0
                            }
                        }
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: model.name
                        color: window.text
                        font.family: "Inter"
                        font.pixelSize: window.s(12)
                        font.weight: Font.Bold
                        width: window.s(100)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        
                        // Add a nice glass backdrop to text for readability
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: window.s(-4)
                            radius: window.s(4)
                            color: Qt.rgba(window.crust.r, window.crust.g, window.crust.b, 0.5)
                            z: -1
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // FLOATING SEARCH BAR
    // -------------------------------------------------------------------------
    Rectangle {
        id: searchContainer
        width: window.s(500)
        height: window.s(60)
        anchors.top: parent.top
        anchors.topMargin: window.s(80)
        anchors.horizontalCenter: parent.horizontalCenter
        
        radius: window.s(30)
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.85)
        border.color: searchInput.activeFocus ? window.mauve : Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
        border.width: 1
        
        transform: Translate { y: (window.introPhase - 1) * window.s(-100) - (window.outroPhase * window.s(200)) }
        opacity: window.introPhase * (1.0 - window.outroPhase)

        RowLayout {
            anchors.fill: parent
            anchors.margins: window.s(15)
            spacing: window.s(15)

            Text {
                font.family: "Iosevka Nerd Font"
                font.pixelSize: window.s(22)
                text: ""
                color: searchInput.activeFocus ? window.mauve : window.subtext0
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                
                font.family: "Inter"
                font.pixelSize: window.s(18)
                color: window.text
                
                clip: true
                selectByMouse: true
                
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search Cosmos..."
                    color: window.subtext0
                    font: searchInput.font
                    visible: searchInput.text.length === 0
                }

                onTextChanged: {
                    window.filterApps(text);
                }
                
                Keys.onReturnPressed: {
                    if (appModel.count > 0) {
                        Quickshell.execDetached(["bash", "-c", appModel.get(0).exec]);
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                    }
                }
            }
        }
    }
}
