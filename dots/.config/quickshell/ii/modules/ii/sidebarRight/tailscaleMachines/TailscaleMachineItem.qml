import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    property var machine: null

    verticalPadding: 5
    horizontalPadding: 10
    buttonRadius: Appearance.rounding.small

    onClicked: {
        TailscaleService.copyIp(root.machine?.ip, root.machine?.hostName)
    }

    function getDeviceIcon() {
        if (!root.machine) return "devices"
        const name = (root.machine.hostName || "").toLowerCase()
        const dns = (root.machine.dnsName || "").toLowerCase()
        const os = (root.machine.os || "").toLowerCase()
        const tags = (root.machine.tags || []).map(t => (t || "").toLowerCase())
        const combined = `${name} ${dns} ${tags.join(" ")}`

        // 1. TVs & Media Players
        if (name.includes("tv") || combined.includes("appletv") || combined.includes("chromecast") ||
            combined.includes("roku") || combined.includes("kodi") || combined.includes("shield") ||
            combined.includes("firetv") || combined.includes("smarttv")) {
            return "tv"
        }

        // 2. Tablets
        if (combined.includes("tablet") || combined.includes("ipad")) {
            return "tablet"
        }

        // 3. IoT, SBCs, Automotive, Embedded hardware
        if (combined.includes("wican") || combined.includes("obd") || combined.includes("rpi") ||
            combined.includes("raspberry") || combined.includes("esp32") || combined.includes("arduino") ||
            combined.includes("iot") || combined.includes("sensor")) {
            return "developer_board"
        }

        // 4. Routers & Networking gear
        if (combined.includes("router") || combined.includes("gateway") || combined.includes("switch")) {
            return "router"
        }

        // 5. Servers, NAS, Storage & Homelab infrastructure
        if (tags.some(t => t.includes("server") || t.includes("nas") || t.includes("storage")) ||
            combined.includes("server") || combined.includes("nas") || combined.includes("storage") ||
            combined.includes("share") || combined.includes("proxmox") || combined.includes("unraid") ||
            combined.includes("truenas") || combined.includes("synology") || combined.includes("homelab") ||
            combined.includes("vault") || combined.includes("cluster") || combined.includes("backup")) {
            return "dns"
        }

        // 6. Laptops / Notebooks
        if (combined.includes("laptop") || combined.includes("notebook") || combined.includes("yoga") ||
            combined.includes("thinkpad") || combined.includes("zenbook") || combined.includes("macbook") ||
            combined.includes("xps") || combined.includes("framework") ||
            (root.machine.isSelf && (root.machine.isLaptop || Battery.available))) {
            return "laptop"
        }

        // 7. Desktop PCs & Workstations
        if (combined.includes("desktop") || combined.includes("workstation") || combined.includes("tower") ||
            combined.includes("rig") || combined.includes("gaming") || combined.includes("nuc") ||
            combined.includes("imac") || combined.includes("mac-mini") || combined.includes("macmini") ||
            combined.includes("pc")) {
            return "computer"
        }

        // 8. OS-based fallbacks
        if (os === "android" || os === "ios") {
            return "smartphone"
        }
        if (os === "linux" || os === "windows" || os === "macos" || os === "darwin") {
            return "computer"
        }

        return "devices"
    }

    contentItem: RowLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 10

        MaterialSymbol {
            iconSize: 20
            text: root.getDeviceIcon()
            color: root.machine?.online ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
        }

        ColumnLayout {
            spacing: 1
            Layout.fillWidth: true

            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                StyledText {
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: root.machine?.hostName || root.machine?.dnsName || Translation.tr("Unknown machine")
                    textFormat: Text.PlainText
                    font.weight: root.machine?.isSelf ? 600 : 400
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                StyledText {
                    visible: root.machine?.isSelf ?? false
                    color: Appearance.colors.colPrimary
                    font.pixelSize: 11
                    text: Translation.tr("(This machine)")
                }
            }

            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                Rectangle {
                    implicitWidth: 5
                    implicitHeight: 5
                    radius: 2.5
                    color: root.machine?.online ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: {
                        if (!root.machine) return ""
                        let status = root.machine.online ? Translation.tr("Online") : Translation.tr("Offline")
                        if (root.machine.active) status += " • " + Translation.tr("Active")
                        if (root.machine.ip) status += " • " + root.machine.ip
                        return status
                    }
                }
            }
        }

        MaterialSymbol {
            id: copyIcon
            iconSize: 16
            text: "content_copy"
            color: root.hovered ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer3

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            StyledToolTip {
                text: Translation.tr("Copy IP")
                extraVisibleCondition: root.hovered
                horizontalPadding: 8
                verticalPadding: 3
                font.pixelSize: 11
            }
        }
    }
}
