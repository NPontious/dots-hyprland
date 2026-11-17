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
    property string claudeSessionReset: ""

    // Antigravity
    property bool antigravityAvailable: false
    property bool antigravitySignedIn: false
    property string antigravityUser: ""
    property string antigravityTier: ""
    property real antigravityGeminiWeeklyRemaining: 1.0
    property string antigravityGeminiWeeklyReset: ""
    property real antigravityGemini5hRemaining: 1.0
    property string antigravityGemini5hReset: ""
    property real antigravity3pWeeklyRemaining: 1.0
    property string antigravity3pWeeklyReset: ""
    property real antigravity3p5hRemaining: 1.0
    property string antigravity3p5hReset: ""

    // Codex
    property bool codexAvailable: false
    property bool codexSignedIn: false
    property string codexUser: ""
    property string codexPlanType: ""
    property real codexPrimaryRemaining: 1.0
    property int codexPrimaryPercent: 0
    property string codexPrimaryReset: ""
    property real codexPrimaryWindowHours: 720
    property string codexPrimaryLabel: "30d:"
    property real codexSecondaryRemaining: 1.0
    property int codexSecondaryPercent: 0
    property string codexSecondaryReset: ""
    property real codexSecondaryWindowHours: 168
    property string codexSecondaryLabel: "Wk:"
    property bool codexHasSecondary: false

    readonly property bool anyAvailable: claudeAvailable || antigravityAvailable || codexAvailable

    readonly property string summarySubtitle: {
        let signed = []
        if (claudeAvailable && claudeSignedIn) signed.push("Claude Code")
        if (antigravityAvailable && antigravitySignedIn) signed.push("Antigravity")
        if (codexAvailable && codexSignedIn) signed.push("Codex")
        if (signed.length === 0) {
            let available = []
            if (claudeAvailable) available.push("Claude")
            if (antigravityAvailable) available.push("Antigravity")
            if (codexAvailable) available.push("Codex")
            if (available.length > 0) return Translation.tr("Signed out")
            return Translation.tr("No agents installed")
        }
        return signed.join(" & ")
    }

    readonly property string summaryText: {
        let parts = []
        if (claudeAvailable && claudeSignedIn) {
            parts.push(`Claude: ${claudeWeeklyPercent}% used`)
        }
        if (antigravityAvailable && antigravitySignedIn) {
            const geminiPct = Math.round(antigravityGeminiWeeklyRemaining * 100)
            parts.push(`Gemini: ${geminiPct}% left`)
        }
        if (codexAvailable && codexSignedIn) {
            const codexPct = Math.round(codexPrimaryRemaining * 100)
            parts.push(`Codex: ${codexPct}% left`)
        }
        if (parts.length === 0) {
            if (claudeAvailable || antigravityAvailable || codexAvailable) {
                return Translation.tr("Agents signed out")
            }
            return Translation.tr("No agents installed")
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
        loadCodexJson()
    }

    function loadClaudeJson() {
        try {
            const raw = claudeConfigFileView.text()
            if (!raw || raw.length === 0) {
                root.claudeUser = ""
                root.claudeTier = ""
                root.claudeSignedIn = false
                return
            }
            const parsed = JSON.parse(raw)
            if (parsed.oauthAccount && (parsed.oauthAccount.emailAddress || parsed.oauthAccount.displayName)) {
                root.claudeUser = parsed.oauthAccount.emailAddress || parsed.oauthAccount.displayName || ""
                const orgType = parsed.oauthAccount.organizationType ?? ""
                const billingType = parsed.oauthAccount.billingType ?? ""
                const hasActiveSub = billingType !== "" && billingType !== "none"
                if (hasActiveSub && orgType === "claude_pro") {
                    root.claudeTier = "Pro"
                } else if (hasActiveSub && orgType.length > 0) {
                    root.claudeTier = orgType
                } else {
                    root.claudeTier = "Free"
                }
                root.claudeSignedIn = true
            } else {
                root.claudeUser = ""
                root.claudeTier = ""
                root.claudeSignedIn = false
                root.claudeSessionPercent = 0
                root.claudeWeeklyPercent = 0
                root.claudeSessionReset = ""
                root.claudeWeeklyReset = ""
            }
            if (parsed.cachedUsageUtilization && parsed.cachedUsageUtilization.utilization && root.claudeSignedIn) {
                const u = parsed.cachedUsageUtilization.utilization
                if (u.five_hour && typeof u.five_hour.utilization === "number") {
                    root.claudeSessionPercent = Math.round(u.five_hour.utilization)
                    if (u.five_hour.resets_at) {
                        root.claudeSessionReset = formatResetTime(u.five_hour.resets_at)
                    }
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
            if (raw && raw.length > 0) {
                const parsed = JSON.parse(raw)
                if (parsed.active && parsed.active.length > 0) {
                    root.antigravityUser = parsed.active
                    root.antigravitySignedIn = true
                }
            }
        } catch (e) {
            console.error("[AgentUsageService] Error reading cached google_accounts.json:", e)
        }

        try {
            const tierRaw = agyTierCacheView.text()
            if (tierRaw && tierRaw.length > 0) {
                const tierData = JSON.parse(tierRaw)
                if (tierData.tier) root.antigravityTier = tierData.tier
                if (tierData.email && !root.antigravityUser) {
                    root.antigravityUser = tierData.email
                    root.antigravitySignedIn = true
                }
            }
        } catch (e) {}
    }

    function loadCodexJson() {
        try {
            const raw = codexAuthFileView.text()
            if (!raw || raw.length === 0) {
                root.codexSignedIn = false
                return
            }
            const parsed = JSON.parse(raw)
            if (parsed.tokens && (parsed.tokens.access_token || parsed.tokens.id_token)) {
                root.codexSignedIn = true
            } else {
                root.codexSignedIn = false
            }
        } catch (e) {
            console.error("[AgentUsageService] Error reading cached .codex/auth.json:", e)
        }
    }

    function parseProbeOutput(output) {
        if (!output || output.length === 0) return
        const lines = output.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (line.indexOf("claude:") === 0) {
                const p = line.substring(7).trim()
                root.claudeAvailable = p.length > 0
            } else if (line.indexOf("agy:") === 0) {
                const p = line.substring(4).trim()
                root.antigravityAvailable = p.length > 0
            } else if (line.indexOf("codex:") === 0) {
                const p = line.substring(6).trim()
                root.codexAvailable = p.length > 0
            }
        }
    }

    function parseClaudeOutput(output) {
        if (!output || output.length === 0) return
        try {
            const data = JSON.parse(output)
            root.claudeAvailable = true

            // When logged out, credential_expires_at is absent and result contains no session/weekly quotas.
            // When logged in via subscription or OAuth, credential_expires_at is present or result contains session/weekly usage.
            const hasSessionUsage = Boolean(data.result) && /Current session:\s*\d+%/i.test(data.result)
            const hasWeeklyUsage = Boolean(data.result) && /Current week.*:\s*\d+%/i.test(data.result)
            const hasCredentials = Boolean(data.credential_expires_at)

            if (!hasCredentials && !hasSessionUsage && !hasWeeklyUsage) {
                root.claudeSignedIn = false
                root.claudeUser = ""
                root.claudeTier = ""
                root.claudeSessionPercent = 0
                root.claudeWeeklyPercent = 0
                root.claudeSessionReset = ""
                root.claudeWeeklyReset = ""
                return
            }

            root.claudeSignedIn = true
            if (data.result) {
                const res = data.result
                const sessionMatch = res.match(/Current session:\s*(\d+)%\s*used(?:\s*·\s*resets\s*([^\n]+))?/i)
                if (sessionMatch) {
                    root.claudeSessionPercent = parseInt(sessionMatch[1])
                    if (sessionMatch[2]) {
                        root.claudeSessionReset = sessionMatch[2].trim()
                    }
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

    function parseCodexOutput(output) {
        if (!output || output.length === 0) return
        try {
            const data = JSON.parse(output)
            root.codexAvailable = data.available ?? true
            if (data.signedIn) {
                root.codexSignedIn = true
                if (data.user) root.codexUser = data.user
                if (data.planType) root.codexPlanType = data.planType

                if (data.primary) {
                    root.codexPrimaryRemaining = data.primary.remainingFraction ?? 1.0
                    root.codexPrimaryPercent = data.primary.usedPercent ?? 0
                    root.codexPrimaryReset = data.primary.resetTime || ""
                    const mins = data.primary.windowDurationMins || 0
                    const hours = mins > 0 ? (mins / 60) : 720
                    root.codexPrimaryWindowHours = hours
                    if (hours >= 720) {
                        root.codexPrimaryLabel = "30d:"
                    } else if (hours >= 168) {
                        root.codexPrimaryLabel = "Wk:"
                    } else {
                        root.codexPrimaryLabel = `${Math.round(hours)}h:`
                    }
                }

                if (data.secondary) {
                    root.codexHasSecondary = true
                    root.codexSecondaryRemaining = data.secondary.remainingFraction ?? 1.0
                    root.codexSecondaryPercent = data.secondary.usedPercent ?? 0
                    root.codexSecondaryReset = data.secondary.resetTime || ""
                    const mins = data.secondary.windowDurationMins || 0
                    const hours = mins > 0 ? (mins / 60) : 168
                    root.codexSecondaryWindowHours = hours
                    if (hours >= 168) {
                        root.codexSecondaryLabel = "Wk:"
                    } else {
                        root.codexSecondaryLabel = `${Math.round(hours)}h:`
                    }
                } else {
                    root.codexHasSecondary = false
                }
            } else {
                root.codexSignedIn = false
            }
        } catch (e) {
            console.error("[AgentUsageService] Error parsing codex output:", e)
        }
    }

    function launchActiveProcs() {
        if (root.claudeAvailable && !claudeProc.running) {
            claudeProc.running = true
        }
        if (root.antigravityAvailable) {
            if (!agyProc.running) agyProc.running = true
            if (!agyTierProc.running) agyTierProc.running = true
        }
        if (root.codexAvailable && !codexProc.running) {
            codexProc.running = true
        }
        root.checkDone()
    }

    function checkDone() {
        if (!probeProc.running && !claudeProc.running && !agyProc.running && !agyTierProc.running && !codexProc.running) {
            root.refreshing = false
            root.lastUpdated = new Date().toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" })
        }
    }

    function refresh() {
        root.refreshing = true
        claudeConfigFileView.reload()
        geminiAccountFileView.reload()
        agyTierCacheView.reload()
        codexAuthFileView.reload()
        loadCached()

        if (!probeProc.running) {
            probeProc.running = true
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

    FileView {
        id: agyTierCacheView
        path: FileUtils.trimFileProtocol(`${Directories.home}/.cache/quickshell/antigravity_tier.json`)
        watchChanges: true
        onFileChanged: {
            this.reload()
            root.loadGeminiJson()
        }
        onLoadedChanged: {
            root.loadGeminiJson()
        }
    }

    FileView {
        id: codexAuthFileView
        path: FileUtils.trimFileProtocol(`${Directories.home}/.codex/auth.json`)
        watchChanges: true
        onFileChanged: {
            this.reload()
            root.loadCodexJson()
        }
        onLoadedChanged: {
            root.loadCodexJson()
        }
    }

    Process {
        id: probeProc
        command: ["bash", "-c", "echo claude:$(command -v claude || (test -x ~/.npm-global/bin/claude && echo ~/.npm-global/bin/claude) || true); echo agy:$(command -v agy || (test -x ~/.local/bin/agy && echo ~/.local/bin/agy) || true); echo codex:$(command -v codex || (test -x ~/.cargo/bin/codex && echo ~/.cargo/bin/codex) || true)"]
        stdout: StdioCollector {
            id: probeCollector
            onStreamFinished: {
                root.parseProbeOutput(probeCollector.text)
                root.launchActiveProcs()
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.launchActiveProcs()
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
                if (exitCode === 127) {
                    root.claudeAvailable = false
                } else {
                    root.loadClaudeJson()
                }
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
            if (exitCode === 127) {
                root.antigravityAvailable = false
            }
            root.checkDone()
        }
    }

    Process {
        id: agyTierProc
        command: ["python3", Quickshell.shellPath("scripts/ai/antigravity-tier.py")]
        stdout: StdioCollector {
            id: agyTierCollector
            onStreamFinished: {
                try {
                    const data = JSON.parse(agyTierCollector.text)
                    if (data.tier) root.antigravityTier = data.tier
                    if (data.email && !root.antigravityUser) {
                        root.antigravityUser = data.email
                        root.antigravitySignedIn = true
                    }
                } catch (e) {}
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.checkDone()
        }
    }

    Process {
        id: codexProc
        command: ["python3", Quickshell.shellPath("scripts/ai/codex-usage.py")]
        stdout: StdioCollector {
            id: codexCollector
            onStreamFinished: {
                root.parseCodexOutput(codexCollector.text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.loadCodexJson()
            }
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
