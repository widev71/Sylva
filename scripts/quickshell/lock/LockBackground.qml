import QtQuick
import QtQuick.Effects

// Wallpaper + blur + dark overlay + ambient orbit orbs
Item {
    id: root
    anchors.fill: parent

    required property color baseColor
    required property color mauveColor
    required property color blueColor
    required property string wallpaperPath
    required property real sc
    required property real globalOrbitAngle

    // Base color fill
    Rectangle {
        anchors.fill: parent
        color: root.baseColor
    }

    // Blurred wallpaper
    Image {
        id: bgWallpaper
        anchors.fill: parent
        source: root.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        cache: false
    }
    MultiEffect {
        source: bgWallpaper
        anchors.fill: bgWallpaper
        blurEnabled: true
        blurMax: 64 * root.sc
        blur: 1.0
    }

    // Dark overlay
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    // Ambient orb 1 (mauve)
    Rectangle {
        width: parent.width * 0.6; height: width; radius: width / 2
        x: (parent.width * 0.05)  + Math.cos(root.globalOrbitAngle) * (60 * root.sc)
        y: (parent.height * 0.1)  + Math.sin(root.globalOrbitAngle) * (40 * root.sc)
        color: root.mauveColor
        opacity: 0.06
    }

    // Ambient orb 2 (blue)
    Rectangle {
        width: parent.width * 0.5; height: width; radius: width / 2
        x: (parent.width * 0.5)   + Math.sin(root.globalOrbitAngle * 1.3) * (80 * root.sc)
        y: (parent.height * 0.3)  + Math.cos(root.globalOrbitAngle * 1.3) * (50 * root.sc)
        color: root.blueColor
        opacity: 0.04
    }
}
