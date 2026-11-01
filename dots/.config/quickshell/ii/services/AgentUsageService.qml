pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtCore
import QtQuick
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property bool refreshing: false
    property string lastUpdated: ""

    // Claude Code
    property bool claudeAvailable: false
    property bool claudeSignedIn: false
    property string claudeUser: ""
    property string claudeTier: ""
    property int claudeSessionPercent: 0
    property int claudeWeeklyPercent: 0
    property string claudeWeeklyReset: ""

    // Antigravity
    property bool antigravityAvailable: false
    property bool antigravitySignedIn: false
    property string antigravityUser: ""
    property real antigravityGeminiWeeklyRemaining: 1.0
    property string antigravityGeminiWeeklyReset: ""
    property real antigravityGemini5hRemaining: 1.0
    property string antigravityGemini5hReset: ""
    property real antigravity3pWeeklyRemaining: 1.0
    property string antigravity3pWeeklyReset: ""
    property real antigravity3p5hRemaining: 1.0
    property string antigravity3p5hReset: ""

    readonly property string summarySubtitle: {
        let signed = []
        if (claudeSignedIn) signed.push("Claude Code")
        if (antigravitySignedIn) signed.push("Antigravity")
        if (signed.length === 0) return Translation.tr("No agents connected")
        return signed.join(" & ")
    }

    readonly property string summaryText: {
        let parts = []
        if (claudeSignedIn) {
            parts.push(`Claude: ${claudeWeeklyPercent}% used`)
        }
        if (antigravitySignedIn) {
            const geminiPct = Math.round(antigravityGeminiWeeklyRemaining * 100)
            parts.push(`Gemini: ${geminiPct}% left`)
        }
        if (parts.length === 0) {
            return Translation.tr("No agents active")
        }
        return parts.join("  •  ")
    }

    function formatResetTime(isoStr) {
        if (!isoStr || isoStr.length === 0) return ""
        try {
            const d = new Date(isoStr)
            if (isNaN(d.getTime())) return isoStr
            const now = new Date()
            const diffMs = d.getTime() - now.getTime()
            if (diffMs <= 0) return Translation.tr("Resetting soon")
            const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
            const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
            let rel = ""
            if (diffHours >= 24) {
                const days = Math.floor(diffHours / 24)
                const remHours = diffHours % 24
                rel = `${days}d ${remHours}h`
            } else if (diffHours > 0) {
                rel = `${diffHours}h ${diffMinutes}m`
            } else {
                rel = `${diffMinutes}m`
            }
            const timeStr = d.toLocaleDateString(undefined, { month: "short", day: "numeric" }) + ", " +
                            d.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" })
            return `${timeStr} (in ${rel})`
        } catch (e) {
            return isoStr
        }
    }

    function load() {
        loadCached()
        refresh()
    }

    function loadCached() {
        loadClaudeJson()
        loadGeminiJson()
    }

    function loadClaudeJson() {
        try {
            const raw = claudeConfigFileView.text()
            if (!raw || raw.length === 0) return
            const parsed = JSON.parse(raw)
            root.claudeAvailable = true
            if (parsed.oauthAccount) {
                root.claudeUser = parsed.oauthAccount.emailAddress || parsed.oauthAccount.displayName || ""
                const orgType = parsed.oauthAccount.organizationType ?? ""
                root.claudeTier = orgType === "claude_pro" ? "Pro" : orgType
                root.claudeSignedIn = true
            }
            if (parsed.cachedUsageUtilization && parsed.cachedUsageUtilization.utilization) {
                const u = parsed.cachedUsageUtilization.utilization
                if (u.five_hour && typeof u.five_hour.utilization === "number") {
                    root.claudeSessionPercent = Math.round(u.five_hour.utilization)
                }
                if (u.seven_day && typeof u.seven_day.utilization === "number") {
                    root.claudeWeeklyPercent = Math.round(u.seven_day.utilization)
                    if (u.seven_day.resets_at) {
                        root.claudeWeeklyReset = formatResetTime(u.seven_day.resets_at)
                    }
                }
            }
        } catch (e) {
            console.error("[AgentUsageService] Error reading cached .claude.json:", e)
        }
    }

    function loadGeminiJson() {
        try {
            const raw = geminiAccountFileView.text()
            if (!raw || raw.length === 0) return
            const parsed = JSON.parse(raw)
            root.antigravityAvailable = true
            if (parsed.active && parsed.active.length > 0) {
                root.antigravityUser = parsed.active
                root.antigravitySignedIn = true
            }
        } catch (e) {
            console.error("[AgentUsageService] Error reading cached google_accounts.json:", e)
        }
    }

    function parseClaudeOutput(output) {
        if (!output || output.length === 0) return
        try {
            const data = JSON.parse(output)
            root.claudeAvailable = true
            if (data.result) {
                root.claudeSignedIn = true
                const res = data.result
                const sessionMatch = res.match(/Current session:\s*(\d+)%\s*used/i)
                if (sessionMatch) {
                    root.claudeSessionPercent = parseInt(sessionMatch[1])
                }
                const weekMatch = res.match(/Current week(?:\s*\([^)]+\))?:\s*(\d+)%\s*used(?:\s*·\s*resets\s*([^\n]+))?/i)
                if (weekMatch) {
                    root.claudeWeeklyPercent = parseInt(weekMatch[1])
                    if (weekMatch[2]) {
                        root.claudeWeeklyReset = weekMatch[2].trim()
                    }
                }
            }
        } catch (e) {
            console.error("[AgentUsageService] Error parsing claude output:", e)
        }
    }

    function parseAgyOutput(output) {
        if (!output || output.length === 0) return
        try {
            const data = JSON.parse(output)
            root.antigravityAvailable = true
            if (data.status === "SUCCESS" && data.command && data.command.data && data.command.data.groups) {
                root.antigravitySignedIn = true
                const groups = data.command.data.groups
                for (let i = 0; i < groups.length; i++) {
                    const grp = groups[i]
                    const name = grp.name || ""
                    const buckets = grp.buckets || []
                    if (name.indexOf("Gemini") !== -1) {
                        for (let j = 0; j < buckets.length; j++) {
                            const b = buckets[j]
                            if (b.window === "weekly" || (b.id && b.id.indexOf("weekly") !== -1)) {
                                root.antigravityGeminiWeeklyRemaining = b.remaining_fraction !== undefined ? b.remaining_fraction : 1.0
                                root.antigravityGeminiWeeklyReset = b.reset_time || ""
                            } else if (b.window === "5h" || (b.id && b.id.indexOf("5h") !== -1)) {
                                root.antigravityGemini5hRemaining = b.remaining_fraction !== undefined ? b.remaining_fraction : 1.0
                                root.antigravityGemini5hReset = b.reset_time || ""
                            }
                        }
                    } else if (name.indexOf("Claude") !== -1 || name.indexOf("GPT") !== -1) {
                        for (let j = 0; j < buckets.length; j++) {
                            const b = buckets[j]
                            if (b.window === "weekly" || (b.id && b.id.indexOf("weekly") !== -1)) {
                                root.antigravity3pWeeklyRemaining = b.remaining_fraction !== undefined ? b.remaining_fraction : 1.0
                                root.antigravity3pWeeklyReset = b.reset_time || ""
                            } else if (b.window === "5h" || (b.id && b.id.indexOf("5h") !== -1)) {
                                root.antigravity3p5hRemaining = b.remaining_fraction !== undefined ? b.remaining_fraction : 1.0
                                root.antigravity3p5hReset = b.reset_time || ""
                            }
                        }
                    }
                }
            }
        } catch (e) {
            console.error("[AgentUsageService] Error parsing agy output:", e)
        }
    }

    function checkDone() {
        if (!claudeProc.running && !agyProc.running) {
            root.refreshing = false
            root.lastUpdated = new Date().toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" })
        }
    }

    function refresh() {
        root.refreshing = true
        claudeConfigFileView.reload()
        geminiAccountFileView.reload()
        loadCached()

        if (!claudeProc.running) {
            claudeProc.running = true
        }
        if (!agyProc.running) {
            agyProc.running = true
        }
    }

    FileView {
        id: claudeConfigFileView
        path: FileUtils.trimFileProtocol(`${Directories.home}/.claude.json`)
        watchChanges: true
        onFileChanged: {
            this.reload()
            root.loadClaudeJson()
        }
        onLoadedChanged: {
            root.loadClaudeJson()
        }
    }

    FileView {
        id: geminiAccountFileView
        path: FileUtils.trimFileProtocol(`${Directories.home}/.gemini/google_accounts.json`)
        watchChanges: true
        onFileChanged: {
            this.reload()
            root.loadGeminiJson()
        }
        onLoadedChanged: {
            root.loadGeminiJson()
        }
    }

    Process {
        id: claudeProc
        command: ["claude", "-p", "/usage", "--output-format", "json"]
        stdout: StdioCollector {
            id: claudeCollector
            onStreamFinished: {
                root.parseClaudeOutput(claudeCollector.text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.loadClaudeJson()
            }
            root.checkDone()
        }
    }

    Process {
        id: agyProc
        command: ["agy", "-p", "/usage", "--output-format", "json"]
        stdout: StdioCollector {
            id: agyCollector
            onStreamFinished: {
                root.parseAgyOutput(agyCollector.text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.checkDone()
        }
    }

    Timer {
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        onTriggered: {
            root.refresh()
        }
    }
}
