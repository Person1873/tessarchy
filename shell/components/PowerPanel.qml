import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../LayoutPolicy.js" as Policy

ColumnLayout {
    id: panel
    property color accentColor: "#a9e8d5"

    property var backend: powerBackend
    PowerBackend { id: powerBackend; active: panel.visible }
    readonly property var device: UPower.displayDevice
    readonly property bool batteryPresent: !!(device && device.ready && device.isPresent)

    spacing: 6

    Text {
        Layout.fillWidth: true
        color: "#f0f5ff"
        wrapMode: Text.WrapAnywhere
        Accessible.name: text
        text: {
            if (!panel.device || !panel.device.ready)
                return "Battery status unavailable";
            if (!panel.batteryPresent)
                return UPower.onBattery ? "On battery power" : "No battery · on AC power";
            const percent = Policy.volumePercent(panel.device.percentage) + "%";
            switch (panel.device.state) {
            case UPowerDeviceState.Charging:
                return panel.device.timeToFull > 0 ? "Charging · " + percent + " · " + Policy.duration(panel.device.timeToFull) + " to full" : "Charging · " + percent;
            case UPowerDeviceState.PendingCharge:
                return "Plugged in · " + percent;
            case UPowerDeviceState.FullyCharged:
                return "Fully charged · " + percent;
            case UPowerDeviceState.Discharging:
                return panel.device.timeToEmpty > 0 ? "Battery · " + percent + " · " + Policy.duration(panel.device.timeToEmpty) + " left" : "Battery · " + percent;
            case UPowerDeviceState.Empty:
                return "Battery empty · " + percent;
            default:
                return "Battery · " + percent;
            }
        }
    }
    Text {
        visible: panel.batteryPresent && panel.device.healthSupported
        text: "Battery health · " + Policy.volumePercent(panel.device.healthPercentage) + "%"
        color: "#b7c7cc"
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
    }
    Text {
        text: "POWER MODE"
        color: "#8da7b9"
        font {
            pixelSize: 11
            letterSpacing: 2
        }
    }
    Text {
        visible: !panel.backend.state.available
        text: "Power profile service unavailable"
        color: "#9eb6c3"
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    RowLayout {
        Layout.fillWidth: true
        TouchButton {
            text: "Save"
            accentColor: panel.accentColor
            selected: panel.backend.state.available && panel.backend.state.active === "power-saver"
            enabled: panel.backend.state.available && !panel.backend.busy && panel.backend.state.profiles.indexOf("power-saver") >= 0
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Accessible.name: "Power saver mode"
            focusPolicy: Qt.StrongFocus
            onClicked: panel.backend.select("power-saver")
        }
        TouchButton {
            text: "Balanced"
            accentColor: panel.accentColor
            selected: panel.backend.state.available && panel.backend.state.active === "balanced"
            enabled: panel.backend.state.available && !panel.backend.busy && panel.backend.state.profiles.indexOf("balanced") >= 0
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Accessible.name: "Balanced power mode"
            focusPolicy: Qt.StrongFocus
            onClicked: panel.backend.select("balanced")
        }
        TouchButton {
            text: "Performance"
            accentColor: panel.accentColor
            enabled: panel.backend.state.available && !panel.backend.busy && panel.backend.state.profiles.indexOf("performance") >= 0
            selected: panel.backend.state.available && panel.backend.state.active === "performance"
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Accessible.name: enabled ? "Performance power mode" : "Performance power mode unavailable"
            focusPolicy: Qt.StrongFocus
            onClicked: panel.backend.select("performance")
        }
    }
    Text { visible: !!panel.backend.state.error; text: panel.backend.state.error || ""; color: "#efb6bd"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
    Text { visible: !!panel.backend.state.degraded; text: "Performance limited · " + panel.backend.state.degraded; color: "#9eb6c3"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
}
