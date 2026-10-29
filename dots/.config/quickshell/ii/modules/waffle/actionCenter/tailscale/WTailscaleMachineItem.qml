import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

ExpandableChoiceButton {
    id: root
    required property var machine

    function getDeviceIcon() {
        if (!root.machine) return "desktop"
        const name = (root.machine.hostName || "").toLowerCase()
        const os = (root.machine.os || "").toLowerCase()
        if (os === "android" || os === "ios") return "phone"
        if (name.includes("server") || root.machine.tags?.length > 0) return "server"
        return "desktop"
    }

    contentItem: RowLayout {
        id: contentItem
        spacing: 16

        FluentIcon {
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            Layout.alignment: Qt.AlignTop
            icon: root.getDeviceIcon()
            implicitSize: 18
            color: root.machine?.online ? Looks.colors.accent : Looks.colors.fg2
        }

        ColumnLayout {
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                WText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: Looks.font.pixelSize.large
                    font.weight: root.machine?.isSelf ? 600 : 400
                    text: root.machine?.hostName || root.machine?.dnsName || Translation.tr("Unknown machine")
                    textFormat: Text.PlainText
                }

                WText {
                    visible: root.machine?.isSelf ?? false
                    color: Looks.colors.accent
                    font.pixelSize: Looks.font.pixelSize.small
                    text: Translation.tr("(This machine)")
                }
            }

            WText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.medium
                color: Looks.colors.subfg
                text: {
                    if (!root.machine) return ""
                    let status = root.machine.online ? Translation.tr("Online") : Translation.tr("Offline")
                    if (root.machine.active) status += " • " + Translation.tr("Active")
                    if (root.machine.ip) status += " • " + root.machine.ip
                    return status
                }
            }

            WButton {
                Layout.alignment: Qt.AlignRight
                horizontalAlignment: Text.AlignHCenter
                visible: root.expanded
                colBackground: Looks.colors.bg2
                colBackgroundHover: Looks.colors.bg2Hover
                colBackgroundActive: Looks.colors.bg2Active
                implicitHeight: 30
                implicitWidth: 148
                text: Translation.tr("Copy IP")

                onClicked: {
                    TailscaleService.copyIp(root.machine?.ip, root.machine?.hostName)
                }
            }
        }
    }
}
