import QtQuick
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

PanelWindow {
    id: lyricsWindow
    color: "transparent"

    WlrLayershell.namespace: "qs-lyrics-overlay"
    WlrLayershell.layer: WlrLayer.Bottom  // Behind all apps, above wallpaper only — no click blocking!
    exclusionMode: ExclusionMode.Ignore
    focusable: false

    // Always visible — on Bottom layer so it never blocks app clicks
    // Only show when lyrics are actually present
    visible: lyricsWindow.musicPlaying && lyricsWindow.currentLyricText !== ""

    anchors {
        bottom: true
        left: true
        right: true
    }
    margins.bottom: 80
    implicitHeight: 80

    MatugenColors { id: theme }

    property var lyrics: []
    property int activeLyricIndex: -1
    property string currentLyricText: ""
    property bool musicPlaying: false

    // ── Poll music status every 1s (process exits immediately with result) ──
    Process {
        id: statusPoller
        command: ["bash", "-c", "playerctl status 2>/dev/null | grep -q Playing && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: lyricsWindow.musicPlaying = (this.text.trim() === "1")
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: statusPoller.running = true
    }

    property string currentSongKey: ""

    FileView {
        id: lyricsStateFile
        path: "/tmp/lyrics_state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let txt = text().trim();
            if (txt === "") return;
            try {
                let obj = JSON.parse(txt);
                if (lyricsWindow.currentSongKey !== obj.song) {
                    lyricsWindow.currentSongKey = obj.song || "";
                    lyricsWindow.lyrics = obj.lines || [];
                }
                
                let idx = obj.index ?? -1;
                if (idx !== lyricsWindow.activeLyricIndex) lyricsWindow.activeLyricIndex = idx;
            } catch(e) {}
        }
    }

    onActiveLyricIndexChanged: {
        if (activeLyricIndex >= 0 && activeLyricIndex < lyrics.length) {
            currentLyricText = lyrics[activeLyricIndex].text || "♪";
        } else {
            currentLyricText = "";
        }
    }

    onLyricsChanged: {
        if (activeLyricIndex >= 0 && activeLyricIndex < lyrics.length) {
            currentLyricText = lyrics[activeLyricIndex].text || "♪";
        } else {
            currentLyricText = "";
        }
    }

    Item {
        anchors.fill: parent

        // Subtle dark pill behind the text — dim tapi ga terlalu redup
        Rectangle {
            anchors.centerIn: parent
            width: lyricText.implicitWidth + 48
            height: lyricText.implicitHeight + 18
            radius: 20
            color: Qt.rgba(0, 0, 0, 0.35)
        }

        Text {
            id: lyricText
            anchors.centerIn: parent
            text: lyricsWindow.currentLyricText
            color: "white"
            font.pixelSize: 32
            font.weight: Font.Bold
            font.family: "Inter"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            width: parent.width * 0.85

            opacity: (text !== "" && lyricsWindow.musicPlaying) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.6
                shadowColor: "#000000"
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 2
            }
        }
    }
}
