import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

QuickToggleButton {
    id: root
    toggled: TailscaleService.connected
    visible: TailscaleService.available
    buttonIcon: "vpn_lock"

    onClicked: {
        TailscaleService.toggle()
    }

    StyledToolTip {
        text: root.toggled ? (Translation.tr("Tailscale: %1 (%2)").arg(TailscaleService.selfNode?.hostName ?? "").arg(TailscaleService.selfNode?.ip ?? "") + Translation.tr("\nRight-click for machines")) : Translation.tr("Tailscale: Disconnected")
    }
}
