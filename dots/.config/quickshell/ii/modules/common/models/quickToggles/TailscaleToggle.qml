import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: root
    name: Translation.tr("Tailscale")

    property string ipAddress: ""
    property string nodeName: ""

    toggled: false
    icon: "vpn_lock"
    statusText: toggled ? (ipAddress.length > 0 ? ipAddress : Translation.tr("Connected")) : Translation.tr("Disconnected")
    tooltipText: toggled ? (Translation.tr("Tailscale: %1 (%2)").arg(nodeName).arg(ipAddress) + Translation.tr("\nRight-click to copy IP")) : Translation.tr("Tailscale: Disconnected")

    mainAction: () => {
        if (toggled) {
            root.toggled = false
            downProc.running = true
        } else {
            root.toggled = true
            upProc.running = true
        }
    }

    altAction: () => {
        if (root.ipAddress.length > 0) {
            Quickshell.execDetached(["wl-copy", root.ipAddress])
            Quickshell.execDetached(["notify-send",
                Translation.tr("Tailscale"),
                Translation.tr("Copied %1 to clipboard").arg(root.ipAddress),
                "-a", "Shell"
            ])
        }
    }

    Process {
        id: upProc
        command: ["tailscale", "up"]
        onExited: (exitCode, exitStatus) => {
            fetchActiveState.running = true
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", 
                    Translation.tr("Tailscale"), 
                    Translation.tr("Connection failed. Check 'tailscale status'"),
                    "-a", "Shell"
                ])
            }
        }
    }

    Process {
        id: downProc
        command: ["tailscale", "down"]
        onExited: (exitCode, exitStatus) => {
            fetchActiveState.running = true
        }
    }

    Process {
        id: fetchActiveState
        running: true
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                if (statusCollector.text.length === 0) return
                try {
                    let parsed = JSON.parse(statusCollector.text)
                    root.available = true
                    if (parsed.BackendState === "Running") {
                        root.toggled = true
                        root.nodeName = parsed.Self?.HostName ?? ""
                        root.ipAddress = parsed.Self?.TailscaleIPs?.[0] ?? ""
                    } else {
                        root.toggled = false
                    }
                } catch (e) {
                    console.error("[TailscaleToggle] Error parsing status:", e)
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            fetchActiveState.running = true
        }
    }
}
