import QtQuick
import QtQuick.Layouts

RowLayout {
    id: control
    property color accentColor: Theme.accent
    property bool compact: false
    property int notificationCount: 0
    property real cellularStrength: -1
    property real wifiStrength: -1
    property bool airplaneOn: false
    property bool batteryPresent: false
    property real batteryPercent: 0
    property string batteryState: "unknown"
    property bool audioAvailable: false
    property bool audioMuted: false
    property bool notificationsSelected: false
    property bool settingsSelected: false
    property bool showBatteryText: true
    property bool showVolume: true
    property bool showSettings: true
    signal notificationsRequested
    signal settingsRequested
    signal muteToggled
    /// Tapping a bare status glyph opens the quick-controls sheet.
    signal panelRequested
    readonly property int glyphSize: compact ? 18 : 21
    spacing: compact ? 2 : 8

    TrayButton {
        id: bellButton
        slotWidth: control.compact ? 28 : 48
        icon.source: "../icons/bell.svg"
        icon.width: control.glyphSize
        icon.height: control.glyphSize
        accentColor: control.accentColor
        selected: control.notificationsSelected
        Rectangle {
            visible: control.notificationCount > 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: control.compact ? 1 : 6
            anchors.topMargin: control.compact ? 1 : 8
            width: 14
            height: 14
            radius: Theme.radius("tile", 7, height)
            color: Theme.danger
            Text {
                anchors.centerIn: parent
                text: control.notificationCount
                color: Theme.darkerBackground
                font.pixelSize: 9
                font.bold: true
            }
        }
        Accessible.name: control.notificationCount > 0 ? "Notifications, " + control.notificationCount + " unread" : "Notifications"
        onClicked: control.notificationsRequested()
    }
    Item {
        visible: control.airplaneOn
        Layout.preferredWidth: control.compact ? 28 : 18
        Layout.preferredHeight: 48
        Image {
            anchors.centerIn: parent
            source: "../icons/airplane.svg"
            sourceSize.width: 18
            sourceSize.height: 18
        }
        Accessible.name: "Airplane mode on"
    }
    StatusIcon {
        symbol: "cellular"
        label: "Cellular"
        strength: control.cellularStrength
        uniform: control.compact
        Layout.preferredWidth: control.compact ? 28 : 18
        onClicked: control.panelRequested()
    }
    StatusIcon {
        symbol: "wifi"
        label: "Wi-Fi"
        strength: control.wifiStrength
        uniform: control.compact
        Layout.preferredWidth: control.compact ? 28 : 18
        onClicked: control.panelRequested()
    }
    Item {
        Layout.preferredWidth: control.compact ? 28 : batteryRow.implicitWidth
        Layout.preferredHeight: 48
        RowLayout {
            id: batteryRow
            anchors.centerIn: parent
            spacing: 4
            BatteryIndicator {
                id: batteryIcon
                objectName: "batteryIndicator"
                present: control.batteryPresent
                percentage: control.batteryPercent
                powerState: control.batteryState
                implicitWidth: control.compact ? 18 : 22
                implicitHeight: implicitWidth
            }
            Text {
                visible: control.showBatteryText
                text: batteryIcon.reported ? Math.round(control.batteryPercent * 100) + "%" : "—"
                color: control.compact ? Theme.textSecondary : Theme.accent
                font.pixelSize: control.compact ? 10 : 11
                Accessible.name: batteryIcon.description
            }
        }
    }
    TrayButton {
        visible: control.showVolume
        slotWidth: control.compact ? 28 : 48
        enabled: control.audioAvailable
        icon.source: "../icons/" + (control.audioMuted ? "volume-muted" : "volume") + ".svg"
        icon.width: control.glyphSize
        icon.height: control.glyphSize
        accentColor: control.accentColor
        Accessible.name: control.audioMuted ? "Unmute audio" : "Mute audio"
        onClicked: control.muteToggled()
    }
    TrayButton {
        visible: control.showSettings
        slotWidth: control.compact ? 28 : 48
        icon.source: "../icons/settings.svg"
        icon.width: control.glyphSize
        icon.height: control.glyphSize
        accentColor: control.accentColor
        selected: control.settingsSelected
        Accessible.name: "Settings"
        onClicked: control.settingsRequested()
    }
}
