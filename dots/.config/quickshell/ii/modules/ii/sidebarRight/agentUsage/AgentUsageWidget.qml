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
                text: "smart_toy"
                color: (AgentUsageService.claudeSignedIn || AgentUsageService.antigravitySignedIn)
                    ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    font.weight: 600
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurface
                    text: Translation.tr("Usage Limits")
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: {
                        const sub = AgentUsageService.summarySubtitle;
                        return AgentUsageService.lastUpdated
                            ? `${sub} • ${Translation.tr("Updated %1").arg(AgentUsageService.lastUpdated)}`
                            : sub;
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
                onClicked: AgentUsageService.refresh()
                StyledToolTip {
                    text: Translation.tr("Refresh")
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.5
        }

        // Scrollable content area
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
                spacing: 12

                // --- Claude Code Card ---
                Rectangle {
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

                        // Agent Card Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialSymbol {
                                iconSize: 20
                                text: "terminal"
                                color: AgentUsageService.claudeSignedIn ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "Claude Code"
                                font.weight: 600
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurface
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                visible: AgentUsageService.claudeSignedIn && AgentUsageService.claudeTier.length > 0
                                radius: 4
                                color: Appearance.colors.colPrimaryContainer
                                implicitHeight: 18
                                implicitWidth: tierText.implicitWidth + 8
                                StyledText {
                                    id: tierText
                                    anchors.centerIn: parent
                                    text: AgentUsageService.claudeTier
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: 600
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }

                            Rectangle {
                                visible: !AgentUsageService.claudeSignedIn
                                radius: 4
                                color: Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: notSignedText.implicitWidth + 8
                                StyledText {
                                    id: notSignedText
                                    anchors.centerIn: parent
                                    text: Translation.tr("Signed out")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        StyledText {
                            visible: AgentUsageService.claudeUser.length > 0
                            text: AgentUsageService.claudeUser
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Claude Quotas (if signed in)
                        ColumnLayout {
                            visible: AgentUsageService.claudeSignedIn
                            Layout.fillWidth: true
                            spacing: 6

                            // Current Session
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: Translation.tr("Current session")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnSurface
                                    }
                                    Item { Layout.fillWidth: true }
                                    StyledText {
                                        text: `${AgentUsageService.claudeSessionPercent}% used`
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: 600
                                        color: AgentUsageService.claudeSessionPercent > 80 ? Appearance.colors.colError : Appearance.colors.colOnSurface
                                    }
                                }

                                StyledProgressBar {
                                    Layout.fillWidth: true
                                    value: AgentUsageService.claudeSessionPercent / 100
                                    highlightColor: AgentUsageService.claudeSessionPercent > 80 ? Appearance.colors.colError : (AgentUsageService.claudeSessionPercent > 50 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)
                                    trackColor: Appearance.colors.colLayer1
                                    valueBarHeight: 6
                                }
                            }

                            // Current Week
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: Translation.tr("Current week (all models)")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnSurface
                                    }
                                    Item { Layout.fillWidth: true }
                                    StyledText {
                                        text: `${AgentUsageService.claudeWeeklyPercent}% used`
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: 600
                                        color: AgentUsageService.claudeWeeklyPercent > 80 ? Appearance.colors.colError : Appearance.colors.colOnSurface
                                    }
                                }

                                StyledProgressBar {
                                    Layout.fillWidth: true
                                    value: AgentUsageService.claudeWeeklyPercent / 100
                                    highlightColor: AgentUsageService.claudeWeeklyPercent > 80 ? Appearance.colors.colError : (AgentUsageService.claudeWeeklyPercent > 50 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)
                                    trackColor: Appearance.colors.colLayer1
                                    valueBarHeight: 6
                                }

                                StyledText {
                                    visible: AgentUsageService.claudeWeeklyReset.length > 0
                                    text: Translation.tr("Resets: %1").arg(AgentUsageService.claudeWeeklyReset)
                                    font.pixelSize: 10
                                    color: Appearance.colors.colSubtext
                                }
                            }
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

                // --- Google Antigravity Card ---
                Rectangle {
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

                        // Agent Card Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialSymbol {
                                iconSize: 20
                                text: "neurology"
                                color: AgentUsageService.antigravitySignedIn ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "Google Antigravity"
                                font.weight: 600
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurface
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                visible: AgentUsageService.antigravitySignedIn
                                radius: 4
                                color: Appearance.colors.colPrimaryContainer
                                implicitHeight: 18
                                implicitWidth: agyActiveText.implicitWidth + 8
                                StyledText {
                                    id: agyActiveText
                                    anchors.centerIn: parent
                                    text: Translation.tr("Active")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: 600
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }

                            Rectangle {
                                visible: !AgentUsageService.antigravitySignedIn
                                radius: 4
                                color: Appearance.colors.colLayer2Hover
                                implicitHeight: 18
                                implicitWidth: agySignedOutText.implicitWidth + 8
                                StyledText {
                                    id: agySignedOutText
                                    anchors.centerIn: parent
                                    text: Translation.tr("Signed out")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        StyledText {
                            visible: AgentUsageService.antigravityUser.length > 0
                            text: AgentUsageService.antigravityUser
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Antigravity Quotas (if signed in)
                        ColumnLayout {
                            visible: AgentUsageService.antigravitySignedIn
                            Layout.fillWidth: true
                            spacing: 8

                            // Section: Gemini Models
                            StyledText {
                                text: Translation.tr("Gemini Models (Flash, Pro)")
                                font.weight: 600
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colPrimary
                            }

                            // Gemini 5h limit
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: Translation.tr("5-Hour Limit")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnSurface
                                    }
                                    Item { Layout.fillWidth: true }
                                    StyledText {
                                        text: `${Math.round(AgentUsageService.antigravityGemini5hRemaining * 100)}% left`
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: 600
                                        color: AgentUsageService.antigravityGemini5hRemaining < 0.2 ? Appearance.colors.colError : Appearance.colors.colOnSurface
                                    }
                                }

                                StyledProgressBar {
                                    Layout.fillWidth: true
                                    value: AgentUsageService.antigravityGemini5hRemaining
                                    highlightColor: AgentUsageService.antigravityGemini5hRemaining < 0.2 ? Appearance.colors.colError : (AgentUsageService.antigravityGemini5hRemaining < 0.5 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)
                                    trackColor: Appearance.colors.colLayer1
                                    valueBarHeight: 6
                                }

                                StyledText {
                                    visible: AgentUsageService.antigravityGemini5hReset.length > 0
                                    text: Translation.tr("Refreshes: %1").arg(AgentUsageService.formatResetTime(AgentUsageService.antigravityGemini5hReset))
                                    font.pixelSize: 10
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            // Gemini Weekly limit
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: Translation.tr("Weekly Limit")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnSurface
                                    }
                                    Item { Layout.fillWidth: true }
                                    StyledText {
                                        text: `${Math.round(AgentUsageService.antigravityGeminiWeeklyRemaining * 100)}% left`
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: 600
                                        color: AgentUsageService.antigravityGeminiWeeklyRemaining < 0.2 ? Appearance.colors.colError : Appearance.colors.colOnSurface
                                    }
                                }

                                StyledProgressBar {
                                    Layout.fillWidth: true
                                    value: AgentUsageService.antigravityGeminiWeeklyRemaining
                                    highlightColor: AgentUsageService.antigravityGeminiWeeklyRemaining < 0.2 ? Appearance.colors.colError : (AgentUsageService.antigravityGeminiWeeklyRemaining < 0.5 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)
                                    trackColor: Appearance.colors.colLayer1
                                    valueBarHeight: 6
                                }

                                StyledText {
                                    visible: AgentUsageService.antigravityGeminiWeeklyReset.length > 0
                                    text: Translation.tr("Refreshes: %1").arg(AgentUsageService.formatResetTime(AgentUsageService.antigravityGeminiWeeklyReset))
                                    font.pixelSize: 10
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            // Section: Claude and GPT models in Antigravity
                            StyledText {
                                Layout.topMargin: 4
                                text: Translation.tr("Claude & GPT Models (Opus, Sonnet)")
                                font.weight: 600
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colPrimary
                            }

                            // 3P Weekly limit
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: Translation.tr("Weekly Limit")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnSurface
                                    }
                                    Item { Layout.fillWidth: true }
                                    StyledText {
                                        text: `${Math.round(AgentUsageService.antigravity3pWeeklyRemaining * 100)}% left`
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: 600
                                        color: Appearance.colors.colOnSurface
                                    }
                                }

                                StyledProgressBar {
                                    Layout.fillWidth: true
                                    value: AgentUsageService.antigravity3pWeeklyRemaining
                                    highlightColor: AgentUsageService.antigravity3pWeeklyRemaining < 0.2 ? Appearance.colors.colError : Appearance.colors.colPrimary
                                    trackColor: Appearance.colors.colLayer1
                                    valueBarHeight: 6
                                }
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
            }
        }
    }
}
