//@ pragma UseQApplication
import QtQuick
import Quickshell
import "music"
import "volume"

ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup() }
    }

    Main {}
    TopBar {}
    Floating {}
    
    // Custom Overlays
    LyricsOverlay {}
    Osd {}
}

