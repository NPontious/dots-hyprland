import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    id: root
    name: Translation.tr("Tailscale")

    available: TailscaleService.available
    toggled: TailscaleService.connected
    icon: "vpn_lock"
    statusText: toggled ? (TailscaleService.selfNode?.ip?.length > 0 ? TailscaleService.selfNode.ip : Translation.tr("Connected")) : Translation.tr("Disconnected")
    tooltipText: toggled ? (Translation.tr("Tailscale: %1 (%2)").arg(TailscaleService.selfNode?.hostName ?? "").arg(TailscaleService.selfNode?.ip ?? "") + Translation.tr("\nRight-click for machines")) : Translation.tr("Tailscale: Disconnected")

    mainAction: () => {
        TailscaleService.toggle()
    }

    hasMenu: true
}
