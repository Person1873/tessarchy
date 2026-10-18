import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Built-in system indicators, shared by the mobile status strip and the desktop
// taskbar tray. Compact mode reduces glyphs and spacing while keeping 48px targets.
RowLayout {
    id: control
    property color accentColor: "#a9e8d5"
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

    readonly property int itemSize: 48
    readonly property int glyphSize: compact ? 18 : 21
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
            Image {
                anchors.centerIn: parent
                source: "../icons/bell.svg"
                sourceSize.width: control.glyphSize
                sourceSize.height: control.glyphSize
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
                color: "#e2796d"
                Text {
                    anchors.centerIn: parent
                    text: control.notificationCount
                    color: "#21151a"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }
        Accessible.name: control.notificationCount > 0 ? "Notifications, " + control.notificationCount + " unread" : "Notifications"
        onClicked: control.notificationsRequested()
    }
    Image {
        visible: control.airplaneOn
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        source: "../icons/airplane.svg"
        sourceSize.width: 18
        sourceSize.height: 18
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
        Image {
            source: "../icons/battery.svg"
            sourceSize.width: control.compact ? 18 : 22
            sourceSize.height: control.compact ? 18 : 22
            opacity: control.batteryPresent ? 1 : 0.35
        }
        Text {
            visible: control.showBatteryText
            text: control.batteryPresent ? Math.round(control.batteryPercent * 100) + "%" : "—"
            color: "#a9e8d5"
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
        contentItem: Item {
            Image {
                anchors.centerIn: parent
                opacity: control.audioAvailable ? 1 : 0.35
                source: "../icons/" + (control.audioMuted ? "volume-muted" : "volume") + ".svg"
                sourceSize.width: control.glyphSize
                sourceSize.height: control.glyphSize
            }
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
        contentItem: Item {
            Image {
                anchors.centerIn: parent
                source: "../icons/settings.svg"
                sourceSize.width: control.glyphSize
                sourceSize.height: control.glyphSize
            }
        }
        Accessible.name: "Settings"
        onClicked: control.settingsRequested()
    }
}
