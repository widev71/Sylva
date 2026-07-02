import QtQuick
import Quickshell
import Quickshell.Io

// Polls network (WiFi/Ethernet) and Bluetooth state via watcher scripts
Item {
    id: root

    property string wifiStatus: "Off"
    property string wifiIcon: "󰤮"
    property string wifiSsid: ""
    property string ethStatus: "Ethernet"
    property string btStatus: "Off"
    property string btIcon: "󰂲"
    property string btDevice: ""

    // ── Network ──────────────────────────────────────────────────────
    Process {
        id: networkPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        if (root.wifiStatus !== data.status)     root.wifiStatus = data.status;
                        if (root.wifiIcon   !== data.icon)       root.wifiIcon   = data.icon;
                        if (root.wifiSsid   !== data.ssid)       root.wifiSsid   = data.ssid;
                        if (root.ethStatus  !== data.eth_status) root.ethStatus  = data.eth_status;
                    } catch (e) {}
                }
                networkWaiter.running = false;
                networkWaiter.running = true;
            }
        }
    }
    Process {
        id: networkWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]
        onExited: { networkPoller.running = false; networkPoller.running = true; }
    }

    // ── Bluetooth ────────────────────────────────────────────────────
    Process {
        id: btPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        if (root.btStatus !== data.status)    root.btStatus = data.status;
                        if (root.btIcon   !== data.icon)      root.btIcon   = data.icon;
                        if (root.btDevice !== data.connected) root.btDevice = data.connected;
                    } catch (e) {}
                }
                btWaiter.running = false;
                btWaiter.running = true;
            }
        }
    }
    Process {
        id: btWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]
        onExited: { btPoller.running = false; btPoller.running = true; }
    }
}
