import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Component.onCompleted: {
        AgentUsageService.load()
    }

    // --- Helper Functions ---

    // Extracts compact relative time like "(2d 2h)" or "(4h 59m)" from reset strings
    function extractShortCountdown(resetStr) {
        if (!resetStr || resetStr.length === 0) return "";
        const formatted = AgentUsageService.formatResetTime ? AgentUsageService.formatResetTime(resetStr) : resetStr;
        const parenMatch = formatted.match(/\(([^)]+)\)/);
        if (parenMatch) return `(${parenMatch[1]})`;
        return "";
    }

    // Parses remaining time ratio (0.0 to 1.0) from a reset string or ISO timestamp
    function computeTimeRemainingRatio(resetStr, windowHours) {
        if (!resetStr || resetStr.length === 0) return -1;
        const totalMs = windowHours * 3600 * 1000;

        // 1. Try parsing direct ISO / standard date string first
        const parsedDate = Date.parse(resetStr);
        if (!isNaN(parsedDate)) {
            const diffMs = parsedDate - Date.now();
            return Math.max(0.0, Math.min(1.0, diffMs / totalMs));
        }

        // 2. Fallback: parse relative duration text like "in 2d 2h" or "4h 59m"
        const formatted = AgentUsageService.formatResetTime ? AgentUsageService.formatResetTime(resetStr) : resetStr;
        let remHours = 0;
        const dMatch = formatted.match(/(\d+)\s*d/);
        const hMatch = formatted.match(/(\d+)\s*h/);
        const mMatch = formatted.match(/(\d+)\s*m/);

        if (dMatch || hMatch || mMatch) {
            if (dMatch) remHours += parseInt(dMatch[1], 10) * 24;
            if (hMatch) remHours += parseInt(hMatch[1], 10);
            if (mMatch) remHours += parseInt(mMatch[1], 10) / 60.0;
            return Math.max(0.0, Math.min(1.0, remHours / windowHours));
        }

        return -1; // Hide tick if reset timestamp isn't provided
    }

    // --- Reusable Component: Semantic Segmented Track + Pacing Tick ---
    component SemanticPipTrack: Item {
        id: track
        property int segments: 5              // 5 for 5h window, 7 for weekly window
        property real remainingRatio: 1.0     // 0.0 to 1.0 remaining quota
        property real timeRemainingRatio: -1  // 0.0 to 1.0 remaining time (-1 hides tick)
        property color fillColor: remainingRatio < 0.25
            ? Appearance.colors.colError
            : (remainingRatio < 0.5 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)

        implicitHeight: 6

        RowLayout {
            anchors.fill: parent
            spacing: track.segments === 5 ? 5 : 4

            Repeater {
                model: track.segments
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 2
                    color: Appearance.colors.colLayer1
                    clip: true

                    // Calculate partial fill for this specific segment (0.0 -> 1.0)
                    property real segmentFill: {
                        const scaled = Math.max(0.0, Math.min(1.0, track.remainingRatio)) * track.segments;
                        return Math.max(0.0, Math.min(1.0, scaled - index));
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * parent.segmentFill
                        radius: 2
                        color: track.fillColor

                        Behavior on width {
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        // Time Pacing Tickmark
        // Bar left of tick = overshooting pace | Bar right of tick = undershooting (surplus)
        Rectangle {
            visible: track.timeRemainingRatio >= 0.0 && track.timeRemainingRatio <= 1.0
            width: 2
            height: parent.height + 4
            anchors.verticalCenter: parent.verticalCenter
            radius: 1
            color: Appearance.colors.colOnSurface
            x: Math.max(0, Math.min(parent.width - width, (parent.width * track.timeRemainingRatio) - (width / 2)))
            z: 2
        }
    }

    // --- Reusable Component: Dual-Track Model Pool Box ---
    component DualTrackModelRow: Rectangle {
        id: modelRow
        property string title: ""
        property string primaryLabel: "5h:"
        property real fiveHourRemaining: 1.0
        property string fiveHourReset: ""
        property real primaryWindowHours: 5
        property int primarySegments: 5

        property bool hasSecondary: true
        property string secondaryLabel: "Wk:"
        property real weeklyRemaining: 1.0
        property string weeklyReset: ""
        property real secondaryWindowHours: 168
        property int secondarySegments: 7

        readonly property int fiveHourPct: Math.round(Math.max(0, Math.min(1, fiveHourRemaining)) * 100)
        readonly property int weeklyPct: Math.round(Math.max(0, Math.min(1, weeklyRemaining)) * 100)

        Layout.fillWidth: true
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1
        implicitHeight: rowCol.implicitHeight + 16

        ColumnLayout {
            id: rowCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Top Inline Summary Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: modelRow.title
                    font.weight: 600
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Primary Readout
                RowLayout {
                    spacing: 2
                    StyledText {
                        text: modelRow.primaryLabel
                        font.pixelSize: 10
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: `${modelRow.fiveHourPct}%`
                        font.pixelSize: 10
                        font.weight: 700
                        color: modelRow.fiveHourPct < 25 ? Appearance.colors.colError : Appearance.colors.colPrimary
                    }
                    StyledText {
                        readonly property string cd: root.extractShortCountdown(modelRow.fiveHourReset)
                        visible: cd.length > 0
                        text: cd
                        font.pixelSize: 10
                        color: Appearance.colors.colSubtext
                    }
                }

                // Secondary Readout
                RowLayout {
                    visible: modelRow.hasSecondary
                    Layout.leftMargin: 4
                    spacing: 2
                    StyledText {
                        text: modelRow.secondaryLabel
                        font.pixelSize: 10
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: `${modelRow.weeklyPct}%`
                        font.pixelSize: 10
                        font.weight: 700
                        color: modelRow.weeklyPct < 25 ? Appearance.colors.colError : Appearance.colors.colPrimary
                    }
                    StyledText {
                        readonly property string cd: root.extractShortCountdown(modelRow.weeklyReset)
                        visible: cd.length > 0
                        text: cd
                        font.pixelSize: 10
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Dual Semantic Pip Tracks (Top = Primary, Bottom = Secondary)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                SemanticPipTrack {
                    Layout.fillWidth: true
                    segments: modelRow.primarySegments
                    remainingRatio: modelRow.fiveHourRemaining
                    timeRemainingRatio: root.computeTimeRemainingRatio(modelRow.fiveHourReset, modelRow.primaryWindowHours)
                }

                SemanticPipTrack {
                    visible: modelRow.hasSecondary
                    Layout.fillWidth: true
                    segments: modelRow.secondarySegments
                    remainingRatio: modelRow.weeklyRemaining
                    timeRemainingRatio: root.computeTimeRemainingRatio(modelRow.weeklyReset, modelRow.secondaryWindowHours)
                }
            }
        }
    }

    // --- Main Layout ---
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        // Compact Top Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: "smart_toy"
                color: ((AgentUsageService.claudeAvailable && AgentUsageService.claudeSignedIn) ||
                        (AgentUsageService.antigravityAvailable && AgentUsageService.antigravitySignedIn) ||
                        (AgentUsageService.codexAvailable && AgentUsageService.codexSignedIn))
                    ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    font.weight: 600
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurface
                    text: Translation.tr("Usage Quotas")
                }

                StyledText {
                    visible: AgentUsageService.lastUpdated && AgentUsageService.lastUpdated.length > 0
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: AgentUsageService.lastUpdated
                }

                Item { Layout.fillWidth: true }
            }

            RippleButton {
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: 14
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 18
                    text: "refresh"
                    color: Appearance.colors.colOnSurface
                }
                onClicked: AgentUsageService.refresh()
                StyledToolTip {
                    text: Translation.tr("Refresh")
                }
            }
        }

        // Scrollable Harness Cards
        StyledFlickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: contentCol.implicitHeight
            contentWidth: width

            ColumnLayout {
                id: contentCol
                width: flickable.width
                spacing: 10

                // Empty State (None installed)
                Rectangle {
                    visible: !AgentUsageService.claudeAvailable && !AgentUsageService.antigravityAvailable && !AgentUsageService.codexAvailable
                    Layout.fillWidth: true
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colOutlineVariant
                    border.width: 1
                    implicitHeight: emptyCol.implicitHeight + 24

                    ColumnLayout {
                        id: emptyCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        MaterialSymbol {
                            iconSize: 24
                            text: "info"
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: Translation.tr("No AI Agent CLI tools installed")
                            font.weight: 600
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurface
                        }

                        StyledText {
                            text: Translation.tr("Install Claude Code ('claude'), Google Antigravity ('agy'), or OpenAI Codex ('codex') to monitor quota usage.")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // =============================================================
                // HARNESS 1: Claude Code
                // =============================================================
                Rectangle {
                    visible: AgentUsageService.claudeAvailable
                    Layout.fillWidth: true
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colOutlineVariant
                    border.width: 1
                    implicitHeight: claudeCol.implicitHeight + 20

                    ColumnLayout {
                        id: claudeCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Inline Uniform Harness Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            CustomIcon {
                                width: 18
                                height: 18
                                source: "claude-symbolic.svg"
                                colorize: true
                                color: AgentUsageService.claudeSignedIn ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "Claude Code"
                                font.weight: 600
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurface
                            }

                            StyledText {
                                visible: AgentUsageService.claudeUser.length > 0
                                text: AgentUsageService.claudeUser
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Item {
                                visible: AgentUsageService.claudeUser.length === 0
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: AgentUsageService.claudeSignedIn
                                radius: 10
                                color: (AgentUsageService.claudeTier && AgentUsageService.claudeTier.toLowerCase() !== "free")
                                    ? Appearance.colors.colPrimaryContainer
                                    : Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: claudeTierText.implicitWidth + 12
                                StyledText {
                                    id: claudeTierText
                                    anchors.centerIn: parent
                                    text: AgentUsageService.claudeTier || Translation.tr("Free")
                                    font.pixelSize: 10
                                    font.weight: 600
                                    color: (AgentUsageService.claudeTier && AgentUsageService.claudeTier.toLowerCase() !== "free")
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colSubtext
                                }
                            }

                            Rectangle {
                                visible: !AgentUsageService.claudeSignedIn
                                radius: 10
                                color: Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: notSignedText.implicitWidth + 12
                                StyledText {
                                    id: notSignedText
                                    anchors.centerIn: parent
                                    text: Translation.tr("Signed out")
                                    font.pixelSize: 10
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Dual-Track Model Box (Normalized from "% used" to "% remaining")
                        DualTrackModelRow {
                            visible: AgentUsageService.claudeSignedIn
                            title: Translation.tr("All Models")
                            fiveHourRemaining: 1.0 - (AgentUsageService.claudeSessionPercent / 100.0)
                            fiveHourReset: AgentUsageService.claudeSessionReset !== undefined ? AgentUsageService.claudeSessionReset : ""
                            weeklyRemaining: 1.0 - (AgentUsageService.claudeWeeklyPercent / 100.0)
                            weeklyReset: AgentUsageService.claudeWeeklyReset
                        }

                        // Signed out hint
                        StyledText {
                            visible: !AgentUsageService.claudeSignedIn
                            text: Translation.tr("Run 'claude auth login' in a terminal to link your subscription.")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // =============================================================
                // HARNESS 2: Google Antigravity
                // =============================================================
                Rectangle {
                    visible: AgentUsageService.antigravityAvailable
                    Layout.fillWidth: true
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colOutlineVariant
                    border.width: 1
                    implicitHeight: agyCol.implicitHeight + 20

                    ColumnLayout {
                        id: agyCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Inline Uniform Harness Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            CustomIcon {
                                width: 18
                                height: 18
                                source: "antigravity-symbolic.svg"
                                colorize: true
                                color: AgentUsageService.antigravitySignedIn ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "Antigravity"
                                font.weight: 600
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurface
                            }

                            StyledText {
                                visible: AgentUsageService.antigravityUser.length > 0
                                text: AgentUsageService.antigravityUser
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Item {
                                visible: AgentUsageService.antigravityUser.length === 0
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: AgentUsageService.antigravitySignedIn
                                radius: 10
                                color: (AgentUsageService.antigravityTier && AgentUsageService.antigravityTier.toLowerCase() !== "free")
                                    ? Appearance.colors.colPrimaryContainer
                                    : Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: agyTierText.implicitWidth + 12
                                StyledText {
                                    id: agyTierText
                                    anchors.centerIn: parent
                                    text: AgentUsageService.antigravityTier || Translation.tr("Pro")
                                    font.pixelSize: 10
                                    font.weight: 600
                                    color: (AgentUsageService.antigravityTier && AgentUsageService.antigravityTier.toLowerCase() !== "free")
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colSubtext
                                }
                            }

                            Rectangle {
                                visible: !AgentUsageService.antigravitySignedIn
                                radius: 10
                                color: Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: agySignedOutText.implicitWidth + 12
                                StyledText {
                                    id: agySignedOutText
                                    anchors.centerIn: parent
                                    text: Translation.tr("Signed out")
                                    font.pixelSize: 10
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Model Pools (Gemini + Claude & GPT)
                        ColumnLayout {
                            visible: AgentUsageService.antigravitySignedIn
                            Layout.fillWidth: true
                            spacing: 6

                            DualTrackModelRow {
                                title: Translation.tr("Gemini")
                                fiveHourRemaining: AgentUsageService.antigravityGemini5hRemaining
                                fiveHourReset: AgentUsageService.antigravityGemini5hReset
                                weeklyRemaining: AgentUsageService.antigravityGeminiWeeklyRemaining
                                weeklyReset: AgentUsageService.antigravityGeminiWeeklyReset
                            }

                            DualTrackModelRow {
                                title: Translation.tr("Claude & GPT")
                                fiveHourRemaining: AgentUsageService.antigravity3p5hRemaining !== undefined ? AgentUsageService.antigravity3p5hRemaining : 1.0
                                fiveHourReset: AgentUsageService.antigravity3p5hReset !== undefined ? AgentUsageService.antigravity3p5hReset : ""
                                weeklyRemaining: AgentUsageService.antigravity3pWeeklyRemaining
                                weeklyReset: AgentUsageService.antigravity3pWeeklyReset !== undefined ? AgentUsageService.antigravity3pWeeklyReset : ""
                            }
                        }

                        // Signed out hint
                        StyledText {
                            visible: !AgentUsageService.antigravitySignedIn
                            text: Translation.tr("Run 'agy' in a terminal to authenticate.")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // =============================================================
                // HARNESS 3: OpenAI Codex
                // =============================================================
                Rectangle {
                    visible: AgentUsageService.codexAvailable
                    Layout.fillWidth: true
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colOutlineVariant
                    border.width: 1
                    implicitHeight: codexCol.implicitHeight + 20

                    ColumnLayout {
                        id: codexCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Inline Uniform Harness Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            CustomIcon {
                                width: 18
                                height: 18
                                source: "codex-symbolic.svg"
                                colorize: true
                                color: AgentUsageService.codexSignedIn ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "OpenAI Codex"
                                font.weight: 600
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurface
                            }

                            StyledText {
                                visible: AgentUsageService.codexUser.length > 0
                                text: AgentUsageService.codexUser
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Item {
                                visible: AgentUsageService.codexUser.length === 0
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: AgentUsageService.codexSignedIn
                                radius: 10
                                color: (AgentUsageService.codexPlanType && AgentUsageService.codexPlanType.toLowerCase() !== "free")
                                    ? Appearance.colors.colPrimaryContainer
                                    : Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: codexTierText.implicitWidth + 12
                                StyledText {
                                    id: codexTierText
                                    anchors.centerIn: parent
                                    text: {
                                        const raw = AgentUsageService.codexPlanType || "Free"
                                        return raw.charAt(0).toUpperCase() + raw.slice(1)
                                    }
                                    font.pixelSize: 10
                                    font.weight: 600
                                    color: (AgentUsageService.codexPlanType && AgentUsageService.codexPlanType.toLowerCase() !== "free")
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colSubtext
                                }
                            }

                            Rectangle {
                                visible: !AgentUsageService.codexSignedIn
                                radius: 10
                                color: Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: codexSignedOutText.implicitWidth + 12
                                StyledText {
                                    id: codexSignedOutText
                                    anchors.centerIn: parent
                                    text: Translation.tr("Signed out")
                                    font.pixelSize: 10
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Model Pool / Quota Box
                        DualTrackModelRow {
                            visible: AgentUsageService.codexSignedIn
                            title: Translation.tr("Codex Quota")
                            primaryLabel: AgentUsageService.codexPrimaryLabel
                            fiveHourRemaining: AgentUsageService.codexPrimaryRemaining
                            fiveHourReset: AgentUsageService.codexPrimaryReset
                            primaryWindowHours: AgentUsageService.codexPrimaryWindowHours
                            primarySegments: AgentUsageService.codexPrimaryWindowHours >= 720 ? 6 : (AgentUsageService.codexPrimaryWindowHours >= 168 ? 7 : 5)
                            hasSecondary: AgentUsageService.codexHasSecondary
                            secondaryLabel: AgentUsageService.codexSecondaryLabel
                            weeklyRemaining: AgentUsageService.codexSecondaryRemaining
                            weeklyReset: AgentUsageService.codexSecondaryReset
                            secondaryWindowHours: AgentUsageService.codexSecondaryWindowHours
                            secondarySegments: 7
                        }

                        // Signed out hint
                        StyledText {
                            visible: !AgentUsageService.codexSignedIn
                            text: Translation.tr("Run 'codex login' in a terminal to authenticate.")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
