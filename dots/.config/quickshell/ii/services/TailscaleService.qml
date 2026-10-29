pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

Singleton {
    id: root

    property bool available: false
    property bool connected: false
    property string backendState: "NoState"
    property var selfNode: ({ hostName: "", dnsName: "", ip: "", os: "", online: false, isSelf: true })
    property list<var> peers: []
    property list<var> machines: []
    property bool refreshing: false

    function refresh() {
        if (!fetchStatusProc.running) {
            root.refreshing = true
            fetchStatusProc.running = true
        }
    }

    function toggle() {
        if (connected) {
            down()
        } else {
            up()
        }
    }

    function up() {
        root.connected = true
        upProc.running = true
    }

    function down() {
        root.connected = false
        downProc.running = true
    }

    function copyIp(ip, hostName) {
        if (!ip || ip.length === 0) return
        Quickshell.execDetached(["wl-copy", ip])
        Quickshell.execDetached(["notify-send",
            Translation.tr("Tailscale"),
            Translation.tr("Copied %1 (%2) to clipboard").arg(hostName || ip).arg(ip),
            "-a", "Shell"
        ])
    }

    Process {
        id: upProc
        command: ["tailscale", "up"]
        onExited: (exitCode, exitStatus) => {
            root.refresh()
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
            root.refresh()
        }
    }

    Process {
        id: fetchStatusProc
        running: true
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                root.refreshing = false
                if (statusCollector.text.length === 0) return
                try {
                    const parsed = JSON.parse(statusCollector.text)
                    root.available = true
                    root.backendState = parsed.BackendState ?? "NoState"
                    root.connected = (parsed.BackendState === "Running")

                    const selfData = parsed.Self ?? {}
                    root.selfNode = {
                        hostName: selfData.HostName ?? "",
                        dnsName: (selfData.DNSName ?? "").split(".")[0],
                        ip: selfData.TailscaleIPs?.[0] ?? "",
                        os: selfData.OS ?? "",
                        online: selfData.Online ?? true,
                        active: false,
                        isSelf: true
                    }

                    const rawPeers = parsed.Peer ?? {}
                    const peerList = []
                    for (const key in rawPeers) {
                        const p = rawPeers[key]
                        if (p.ShareeNode) continue
                        const hostname = p.HostName ?? ""
                        if (!hostname || hostname === "funnel-ingress-node") continue

                        peerList.push({
                            hostName: hostname,
                            dnsName: (p.DNSName ?? "").split(".")[0],
                            ip: p.TailscaleIPs?.[0] ?? "",
                            os: p.OS ?? "",
                            online: Boolean(p.Online),
                            active: Boolean(p.Active),
                            isSelf: false,
                            lastSeen: p.LastSeen ?? ""
                        })
                    }

                    peerList.sort((a, b) => {
                        if (a.online !== b.online) {
                            return a.online ? -1 : 1
                        }
                        return a.hostName.localeCompare(b.hostName)
                    })

                    root.peers = peerList
                    root.machines = [root.selfNode, ...peerList]
                } catch (e) {
                    console.error("[TailscaleService] Error parsing status:", e)
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            root.refresh()
        }
    }
}
