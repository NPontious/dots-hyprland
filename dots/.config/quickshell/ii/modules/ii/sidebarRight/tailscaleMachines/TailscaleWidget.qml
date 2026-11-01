import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Component.onCompleted: {
        TailscaleService.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: "vpn_lock"
                color: TailscaleService.connected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    font.weight: 600
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurface
                    text: Translation.tr("Tailscale")
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: {
                        const status = TailscaleService.connected
                            ? (TailscaleService.selfNode?.ip ? TailscaleService.selfNode.ip : Translation.tr("Connected"))
                            : Translation.tr("Disconnected");
                        return TailscaleService.lastUpdated
                            ? `${status} • ${Translation.tr("Updated %1").arg(TailscaleService.lastUpdated)}`
                            : status;
                    }
                }
            }

            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 20
                    text: "refresh"
                    color: Appearance.colors.colOnSurface
                }
                onClicked: TailscaleService.refresh()
                StyledToolTip {
                    text: Translation.tr("Refresh")
                }
            }

            StyledSwitch {
                checked: TailscaleService.connected
                onClicked: TailscaleService.toggle()
                StyledToolTip {
                    text: TailscaleService.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.5
        }

        // Machines list
        StyledListView {
            id: listView
            visible: TailscaleService.connected
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            spacing: 2
            animateAppearance: false

            model: TailscaleService.machines
            delegate: TailscaleMachineItem {
                required property var modelData
                machine: modelData
                width: ListView.view.width
            }
        }

        // Disconnected empty state
        ColumnLayout {
            visible: !TailscaleService.connected
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            spacing: 12

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 42
                text: "cloud_off"
                color: Appearance.colors.colSubtext
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Appearance.colors.colSubtext
                text: Translation.tr("Tailscale is disconnected")
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            DialogButton {
                Layout.alignment: Qt.AlignHCenter
                buttonText: Translation.tr("Connect")
                onClicked: TailscaleService.up()
            }
        }
    }
}
