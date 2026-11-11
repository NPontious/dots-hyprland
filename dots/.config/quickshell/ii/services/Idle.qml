pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Service managing idle and sleep inhibition.
 */
Singleton {
    id: root

    property bool inhibit: false

    Component.onCompleted: {
        if (Persistent.ready) {
            if (!Persistent.isNewHyprlandInstance) {
                root.inhibit = Persistent.states.idle.inhibit;
            } else {
                Persistent.states.idle.inhibit = root.inhibit;
            }
        }
    }

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Persistent.ready) {
                if (!Persistent.isNewHyprlandInstance) {
                    root.inhibit = Persistent.states.idle.inhibit;
                } else {
                    Persistent.states.idle.inhibit = root.inhibit;
                }
            }
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    IdleInhibitor {
        id: idleInhibitor
        enabled: root.inhibit
        window: PanelWindow {
            visible: root.inhibit
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region {
                item: null
            }
            Item {
                width: 1
                height: 1
            }
        }
    }

    Process {
        id: systemdInhibitProc
        running: root.inhibit
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickshell", "--why=Keep system awake", "sleep", "infinity"]
    }
}
