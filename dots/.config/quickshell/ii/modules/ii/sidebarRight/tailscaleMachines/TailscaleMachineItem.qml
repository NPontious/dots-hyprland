import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    property var machine: null

    onClicked: {
        TailscaleService.copyIp(root.machine?.ip, root.machine?.hostName)
    }

    function getDeviceIcon() {
        if (!root.machine) return "devices"
        if (root.machine.isSelf) return "laptop_chromebook"
        const name = (root.machine.hostName || "").toLowerCase()
        const os = (root.machine.os || "").toLowerCase()
        if (name.includes("tv")) return "tv"
        if (os === "android" || os === "ios") return "smartphone"
        if (os === "linux" || os === "windows" || os === "macos" || os === "darwin") return "computer"
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
        spacing: 12

        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.larger
            text: root.getDeviceIcon()
            color: root.machine?.online ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
        }

        ColumnLayout {
            spacing: 2
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
                }

                StyledText {
                    visible: root.machine?.isSelf ?? false
                    color: Appearance.colors.colPrimary
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: Translation.tr("(This machine)")
                }
            }

            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    radius: 3
                    color: root.machine?.online ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
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
            iconSize: 18
            text: "content_copy"
            color: Appearance.colors.colOnLayer3
        }
    }

    StyledToolTip {
        text: Translation.tr("Click to copy IP (%1)").arg(root.machine?.ip ?? "")
    }
}
