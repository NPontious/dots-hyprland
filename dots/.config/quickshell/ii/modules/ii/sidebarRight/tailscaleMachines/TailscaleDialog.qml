import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 600

    WindowDialogTitle {
        text: Translation.tr("Tailscale machines")
    }

    WindowDialogSeparator {
        visible: !TailscaleService.refreshing
    }

    StyledIndeterminateProgressBar {
        visible: TailscaleService.refreshing
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }

    StyledListView {
        id: machinesListView
        visible: TailscaleService.connected
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0
        animateAppearance: false

        model: ScriptModel {
            values: [TailscaleService.selfNode, ...TailscaleService.peers]
        }
        delegate: TailscaleMachineItem {
            required property var modelData
            anchors {
                left: parent?.left
                right: parent?.right
            }
        }
    }

    ColumnLayout {
        visible: !TailscaleService.connected
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter
        spacing: 12

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            iconSize: 48
            text: "cloud_off"
            color: Appearance.colors.colSubtext
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Appearance.colors.colSubtext
            text: Translation.tr("Tailscale is disconnected")
            font.pixelSize: Appearance.font.pixelSize.medium
        }

        DialogButton {
            Layout.alignment: Qt.AlignHCenter
            buttonText: Translation.tr("Connect")
            onClicked: TailscaleService.up()
        }
    }

    WindowDialogSeparator {}

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Refresh")
            onClicked: TailscaleService.refresh()
        }

        DialogButton {
            buttonText: TailscaleService.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")
            onClicked: TailscaleService.toggle()
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
