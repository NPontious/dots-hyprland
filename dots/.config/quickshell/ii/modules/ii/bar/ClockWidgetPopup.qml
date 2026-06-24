import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime


    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        StyledPopupHeaderRow {
            icon: "calendar_month"
            label: root.formattedDate
        }

        StyledPopupValueRow {
            icon: "timelapse"
            label: Translation.tr("System uptime:")
            value: root.formattedUptime
        }

        // Calendar
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 2
            
            DayOfWeekRow {
                Layout.fillWidth: true
                locale: Qt.locale()
                spacing: calendarView.buttonSpacing
                implicitHeight: 24
                delegate: Item {
                    id: dayOfWeekItem
                    required property var model
                    implicitHeight: 24
                    implicitWidth: calendarView.buttonSize
                    StyledText {
                        anchors.centerIn: parent
                        text: dayOfWeekItem.model.shortName.substring(0,2)
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
            CalendarView {
                id: calendarView
                locale: Qt.locale()
                verticalPadding: 2
                buttonSize: 30
                buttonSpacing: 4
                buttonVerticalSpacing: 2
                Layout.fillWidth: true
                delegate: RippleButton {
                    id: dayButton
                    required property var model
                    required property int index
                    toggled: model.today
                    enabled: hovered || toggled || model.month === calendarView.focusedMonth
                    implicitWidth: calendarView.buttonSize
                    implicitHeight: calendarView.buttonSize
                    buttonRadius: height / 2
                    
                    contentItem: Item {
                        StyledText {
                            anchors.centerIn: parent
                            text: dayButton.model.day
                            color: dayButton.toggled ? Appearance.colors.colOnPrimary : (dayButton.model.month === calendarView.focusedMonth ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant)
                        }
                    }
                }
            }
        }
    }
}
