import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Built-in system indicators, shared by the mobile status strip and the desktop
// taskbar tray. `compact` shrinks the touch targets for the tray, where they sit
// beside the clock like a Windows notification area.
RowLayout {
    id: control
    property color accentColor: Theme.accent
    property bool compact: false
    property int notificationCount: 0
    property int cellularStrength: -1
    property int wifiStrength: -1
    property bool airplaneOn: false
    property bool batteryPresent: false
    property real batteryPercent: 0
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

    readonly property int itemSize: compact ? 32 : 48
    readonly property int glyphSize: compact ? 17 : 21
    spacing: compact ? 2 : 8

    Button {
        id: bellButton
        Layout.minimumWidth: control.itemSize
        Layout.minimumHeight: control.itemSize
        Layout.preferredWidth: control.itemSize
        implicitWidth: control.itemSize
        implicitHeight: control.itemSize
        padding: 0
        focusPolicy: Qt.NoFocus
        background: Rectangle {
            radius: 12
            color: bellButton.down ? Qt.alpha(control.accentColor, 0.3)
                                   : control.notificationsSelected ? Qt.alpha(control.accentColor, 0.15) : "transparent"
        }
        contentItem: Item {
            Icon {
                anchors.centerIn: parent
                symbol: "bell"
                size: control.glyphSize
                color: Theme.text
            }
            Rectangle {
                visible: control.notificationCount > 0
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: control.compact ? 1 : 6
                anchors.topMargin: control.compact ? 1 : 8
                width: 14
                height: 14
                radius: 7
                color: Theme.danger
                Text {
                    anchors.centerIn: parent
                    text: control.notificationCount
                    color: Theme.darkerBackground
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }
        Accessible.name: control.notificationCount > 0 ? "Notifications, " + control.notificationCount + " unread" : "Notifications"
        onClicked: control.notificationsRequested()
    }
    Icon {
        visible: control.airplaneOn
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        symbol: "airplane"
        size: 18
        color: Theme.text
        Accessible.name: "Airplane mode on"
    }
    StatusIcon {
        symbol: "cellular"
        label: "Cellular"
        strength: control.cellularStrength
    }
    StatusIcon {
        symbol: "wifi"
        label: "Wi-Fi"
        strength: control.wifiStrength
    }
    RowLayout {
        spacing: 4
        Icon {
            symbol: "battery"
            size: control.compact ? 18 : 22
            color: Theme.text
            opacity: control.batteryPresent ? 1 : 0.35
        }
        Text {
            visible: control.showBatteryText
            text: control.batteryPresent ? Math.round(control.batteryPercent * 100) + "%" : "—"
            color: Theme.accent
            font.pixelSize: control.compact ? 10 : 11
            Accessible.name: control.batteryPresent ? "Battery " + text : "Battery status unavailable"
        }
    }
    Button {
        id: volumeButton
        visible: control.showVolume
        Layout.minimumWidth: control.itemSize
        Layout.minimumHeight: control.itemSize
        Layout.preferredWidth: control.itemSize
        implicitWidth: control.itemSize
        implicitHeight: control.itemSize
        padding: 0
        focusPolicy: Qt.NoFocus
        enabled: control.audioAvailable
        background: Rectangle {
            radius: 12
            color: volumeButton.down ? Qt.alpha(control.accentColor, 0.3) : "transparent"
        }
        contentItem: Icon {
            anchors.centerIn: parent
            opacity: control.audioAvailable ? 1 : 0.35
            symbol: control.audioMuted ? "volume-muted" : "volume"
            size: control.glyphSize
            color: Theme.text
        }
        Accessible.name: control.audioMuted ? "Unmute audio" : "Mute audio"
        onClicked: control.muteToggled()
    }
    Button {
        id: settingsButton
        visible: control.showSettings
        Layout.minimumWidth: control.itemSize
        Layout.minimumHeight: control.itemSize
        Layout.preferredWidth: control.itemSize
        implicitWidth: control.itemSize
        implicitHeight: control.itemSize
        padding: 0
        focusPolicy: Qt.NoFocus
        background: Rectangle {
            radius: 12
            color: settingsButton.down ? Qt.alpha(control.accentColor, 0.3)
                                       : control.settingsSelected ? Qt.alpha(control.accentColor, 0.15) : "transparent"
        }
        contentItem: Icon {
            anchors.centerIn: parent
            symbol: "settings"
            size: control.glyphSize
            color: Theme.text
        }
        Accessible.name: "Settings"
        onClicked: control.settingsRequested()
    }
}
