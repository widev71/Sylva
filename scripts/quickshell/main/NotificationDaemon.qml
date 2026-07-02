import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../notifications" as Notifs

// Notification daemon: receives D-Bus notifications, maintains history model,
// fires OSD popups, and exposes the live notif object map to the master window.
Item {
    id: root

    // ── Exposed properties ────────────────────────────────────────────
    property var  notifModel:  globalNotificationHistory
    property var  liveNotifs:  ({})
    property real uiScale:     1.0

    // ── Startup grace period (suppress popups on boot) ────────────────
    property bool isStartup: true
    Timer { interval: 500; running: true; onTriggered: root.isStartup = false }

    // ── History + active popups models ────────────────────────────────
    ListModel { id: globalNotificationHistory }
    ListModel { id: activePopupsModel }
    property int _popupCounter: 0

    function removePopup(uid) {
        for (let i = 0; i < activePopupsModel.count; i++) {
            if (activePopupsModel.get(i).uid === uid) {
                activePopupsModel.remove(i);
                break;
            }
        }
    }

    // ── D-Bus notification server ─────────────────────────────────────
    NotificationServer {
        id: globalNotificationServer
        bodySupported:    true
        actionsSupported: true
        imageSupported:   true

        onNotification: (n) => {
            n.tracked = true;

            let extractedActions = [];
            if (n.actions) {
                for (let i = 0; i < n.actions.length; i++) {
                    extractedActions.push({
                        "id":   n.actions[i].identifier || "",
                        "text": n.actions[i].text || n.actions[i].name || "Action"
                    });
                }
            }

            root._popupCounter++;
            let uid = root._popupCounter;
            root.liveNotifs[uid] = n;

            let notifData = {
                "appName":     n.appName  !== "" ? n.appName  : "System",
                "summary":     n.summary  !== "" ? n.summary  : "No Title",
                "body":        n.body     !== "" ? n.body     : "",
                "iconPath":    n.appIcon  !== "" ? n.appIcon  : "",
                "actionsJson": JSON.stringify(extractedActions),
                "uid":         uid,
                "notif":       n
            };

            globalNotificationHistory.insert(0, notifData);

            if (!root.isStartup) {
                activePopupsModel.append(notifData);
                osdPopups.storeNotif(uid, n);
            }
        }
    }

    // ── OSD popup overlay ─────────────────────────────────────────────
    Notifs.NotificationPopups {
        id: osdPopups
        popupModel: activePopupsModel
        uiScale:    root.uiScale
        onRemoveRequested: (uid) => root.removePopup(uid)
    }
}
