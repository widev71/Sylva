import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"
import "../notifications"

Item {
    id: window

    Caching { id: paths }

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }

    function s(val) {
        return scaler.s(val);
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext1: _theme.subtext1
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay2: _theme.overlay2
    readonly property color overlay1: _theme.overlay1
    readonly property color overlay0: _theme.overlay0
    readonly property color surface2: _theme.surface2
    readonly property color surface1: _theme.surface1
    readonly property color surface0: _theme.surface0

    readonly property color blue: _theme.blue
    readonly property color lavender: _theme.lavender
    readonly property color sapphire: _theme.sapphire
    readonly property color sky: _theme.sky
    readonly property color teal: _theme.teal
    readonly property color green: _theme.green
    readonly property color yellow: _theme.yellow
    readonly property color peach: _theme.peach
    readonly property color maroon: _theme.maroon
    readonly property color red: _theme.red
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color flamingo: _theme.flamingo
    readonly property color rosewater: _theme.rosewater

    property real introMain: 0
    NumberAnimation { 
        target: window
        property: "introMain"
        from: 0; to: 1.0
        duration: 800
        easing.type: Easing.OutQuart
        running: true 
    }

    // Shadow & Blur Background Layer
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: window.s(24)
        color: Qt.rgba(window.mantle.r, window.mantle.g, window.mantle.b, 0.75)
        border.color: Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, 0.5)
        border.width: 1

        scale: 0.95 + (0.05 * window.introMain)
        opacity: window.introMain
        transform: Translate { y: window.s(15) * (1.0 - window.introMain) }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: window.crust
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurEnabled: false
            colorizationColor: window.base
            colorization: 0.2
        }

        NotificationCenter {
            anchors.fill: parent
            anchors.margins: window.s(16)
        }
    }
}
