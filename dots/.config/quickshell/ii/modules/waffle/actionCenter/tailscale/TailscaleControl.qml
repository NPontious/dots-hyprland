import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

Item {
    id: root

    Component.onCompleted: {
        TailscaleService.refresh()
    }

    WPanelPageColumn {
        anchors.fill: parent

        BodyRectangle {
            implicitHeight: 400
            implicitWidth: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                ColumnLayout {
                    implicitHeight: headerRow.implicitHeight
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        HeaderRow {
                            id: headerRow
                            Layout.fillWidth: true
                            title: Translation.tr("Tailscale")
                        }
                        WSwitch {
                            id: toggleSwitch
                            Layout.rightMargin: 12
                            checked: TailscaleService.connected
                            onCheckedChanged: {
                                if (checked !== TailscaleService.connected) {
                                    TailscaleService.toggle()
                                }
                            }
                        }
                    }
                    FadeLoader {
                        Layout.leftMargin: -4
                        Layout.rightMargin: -4
                        Layout.fillWidth: true
                        shown: TailscaleService.refreshing
                        visible: true
                        sourceComponent: WIndeterminateProgressBar {}
                    }
                }

                StyledListView {
                    id: listView
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    animateAppearance: false

                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true
                    spacing: 4

                    model: TailscaleService.machines
                    delegate: WTailscaleMachineItem {
                        required property var modelData
                        machine: modelData
                        width: ListView.view.width
                    }
                }
            }
        }

        WPanelSeparator {}

        FooterRectangle {
            WTextButton {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                }
                text: Translation.tr("Copy My IP (%1)").arg(TailscaleService.selfNode?.ip ?? "")
                visible: (TailscaleService.selfNode?.ip?.length ?? 0) > 0
                onClicked: {
                    TailscaleService.copyIp(TailscaleService.selfNode?.ip, TailscaleService.selfNode?.hostName)
                }
            }
            WBorderlessButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 12
                enabled: !TailscaleService.refreshing

                onClicked: {
                    TailscaleService.refresh()
                }

                contentItem: FluentIcon {
                    icon: "arrow-counterclockwise"
                }
            }
        }
    }
}
