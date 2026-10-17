pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import "components"

ShellRoot {
    id: root
    // Bind these when wireless/modem integrations land. Never invent a signal.
    property real wifiStrength: -1
    property real cellularStrength: -1
    readonly property var audioSink: audioLoader.item ? (audioLoader.item as AudioStatus).sink : null
    readonly property bool audioAvailable: !!(audioSink && audioSink.ready && audioSink.audio)
    readonly property int volumePercent: audioAvailable ? Math.round(audioSink.audio.volume * 100) : 0
    Loader {
        id: audioLoader
        active: Quickshell.env("TESSARCHY_AUDIO") === "1"
        source: "components/AudioStatus.qml"
    }
    Variants {
        model: Quickshell.screens
        Scope {
            id: surface
            required property var modelData
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
            PanelWindow {
                id: panel
                screen: surface.modelData
                property string page: ""
                property var closeTarget: null
                readonly property bool expanded: page !== ""
                anchors {
                    bottom: true
                    left: true
                    right: true
                }
                implicitHeight: expanded ? Math.min(620, surface.modelData.height - 64) : 72
                exclusiveZone: 72
                color: expanded ? "#ed101b30" : "#55101b30"
                WlrLayershell.namespace: "tessera"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                function showPage(name) {
                    closeTarget = null;
                    page = page === name ? "" : name;
                }
                function launch(command) {
                    Quickshell.execDetached(command);
                    page = "";
                }
                Connections {
                    target: panel.closeTarget
                    function onClosed() {
                        panel.closeTarget = null;
                        panel.page = "windows";
                    }
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    ColumnLayout {
                        visible: panel.expanded
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        Text {
                            text: panel.page === "apps" ? "Your apps" : panel.page === "windows" ? "Recent apps" : panel.page === "close" ? "Close this window?" : panel.page === "status" ? "Quick controls" : "End this session?"
                            color: "#b7eee0"
                            font.pixelSize: 22
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth
                            ColumnLayout {
                                width: parent.width
                                spacing: 8
                                ColumnLayout {
                                    visible: panel.page === "apps"
                                    Layout.fillWidth: true
                                    GridLayout {
                                        columns: 2
                                        columnSpacing: 12
                                        Layout.fillWidth: true
                                        AppTile {
                                            text: "Browser"
                                            symbol: "browser"
                                            onClicked: panel.launch(["firefox"])
                                        }
                                        AppTile {
                                            text: "Terminal"
                                            symbol: "terminal"
                                            onClicked: panel.launch(["foot"])
                                        }
                                    }
                                    Text {
                                        text: "Prototype · Physical keyboard needed for text input."
                                        color: "#b7c7cc"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "windows"
                                    Layout.fillWidth: true
                                    Text {
                                        visible: Hyprland.toplevels.values.length === 0
                                        text: "No recent apps. Tap Home to launch one."
                                        color: "#b7c7cc"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                    Repeater {
                                        model: Hyprland.toplevels
                                        delegate: ColumnLayout {
                                            id: windowRow
                                            required property var modelData
                                            readonly property var handle: modelData.wayland
                                            Layout.fillWidth: true
                                            spacing: 4
                                            TouchButton {
                                                text: (windowRow.modelData.activated ? "● " : "") + (windowRow.modelData.title || "Untitled window")
                                                Layout.fillWidth: true
                                                enabled: windowRow.handle !== null
                                                onClicked: {
                                                    windowRow.handle.activate();
                                                    panel.page = "";
                                                }
                                            }
                                            RowLayout {
                                                Layout.fillWidth: true
                                                TouchButton {
                                                    text: windowRow.handle && windowRow.handle.maximized ? "Restore" : "Maximize"
                                                    Layout.fillWidth: true
                                                    Layout.preferredWidth: 1
                                                    enabled: windowRow.handle !== null
                                                    onClicked: {
                                                        windowRow.handle.maximized = !windowRow.handle.maximized;
                                                    }
                                                }
                                                TouchButton {
                                                    text: "Close…"
                                                    Layout.fillWidth: true
                                                    Layout.preferredWidth: 1
                                                    enabled: windowRow.handle !== null
                                                    onClicked: {
                                                        panel.closeTarget = windowRow.handle;
                                                        panel.page = "close";
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "close"
                                    Layout.fillWidth: true
                                    Text {
                                        text: panel.closeTarget ? panel.closeTarget.title : "Window is no longer available."
                                        color: "#f0f5f5"
                                        wrapMode: Text.WrapAnywhere
                                        Layout.fillWidth: true
                                    }
                                    TouchButton {
                                        text: "Cancel"
                                        Layout.fillWidth: true
                                        onClicked: {
                                            panel.closeTarget = null;
                                            panel.page = "windows";
                                        }
                                    }
                                    TouchButton {
                                        text: "Close window"
                                        destructive: true
                                        enabled: panel.closeTarget !== null
                                        Layout.fillWidth: true
                                        onClicked: {
                                            const target = panel.closeTarget;
                                            panel.closeTarget = null;
                                            panel.page = "windows";
                                            if (target)
                                                target.close();
                                        }
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "status"
                                    Layout.fillWidth: true
                                    spacing: 16
                                    Text {
                                        text: "CONNECTIONS"
                                        color: "#8da7b9"
                                        font {
                                            pixelSize: 11
                                            letterSpacing: 2
                                        }
                                    }
                                    Text {
                                        text: root.wifiStrength < 0 ? "Wi-Fi · unavailable" : "Wi-Fi · connected"
                                        color: "#f0f5ff"
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: root.cellularStrength < 0 ? "Cellular · no modem connected" : "Cellular · connected"
                                        color: "#f0f5ff"
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "SOUND"
                                        color: "#8da7b9"
                                        font {
                                            pixelSize: 11
                                            letterSpacing: 2
                                        }
                                    }
                                    Text {
                                        text: root.audioAvailable ? (root.audioSink.audio.muted ? "Muted" : "Volume · " + root.volumePercent + "%") : "No audio output connected"
                                        color: "#f0f5ff"
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        TouchButton {
                                            text: "−"
                                            Accessible.name: "Decrease volume"
                                            enabled: root.audioAvailable
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            onClicked: root.audioSink.audio.volume = Math.max(0, root.audioSink.audio.volume - 0.05)
                                        }
                                        TouchButton {
                                            text: root.audioAvailable && root.audioSink.audio.muted ? "Unmute" : "Mute"
                                            enabled: root.audioAvailable
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            onClicked: root.audioSink.audio.muted = !root.audioSink.audio.muted
                                        }
                                        TouchButton {
                                            text: "+"
                                            Accessible.name: "Increase volume"
                                            enabled: root.audioAvailable
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            onClicked: root.audioSink.audio.volume = Math.min(1, root.audioSink.audio.volume + 0.05)
                                        }
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "session"
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Save your work before ending Tessarchy. This closes the desktop session."
                                        color: "#f0f5f5"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                    TouchButton {
                                        text: "Cancel"
                                        Layout.fillWidth: true
                                        onClicked: panel.page = ""
                                    }
                                    TouchButton {
                                        text: "End session"
                                        destructive: true
                                        Layout.fillWidth: true
                                        onClicked: Hyprland.dispatch("hl.dsp.exit()")
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        spacing: 8
                        NavButton {
                            text: "Back"
                            symbol: "back"
                            enabled: panel.expanded
                            onClicked: {
                                panel.closeTarget = null;
                                panel.page = "";
                            }
                        }
                        NavButton {
                            text: "Home"
                            symbol: "home"
                            selected: panel.page === "apps"
                            onClicked: panel.showPage("apps")
                        }
                        NavButton {
                            text: "Recents"
                            symbol: "recents"
                            selected: panel.page === "windows"
                            onClicked: panel.showPage("windows")
                        }
                    }
                }
            }
            PanelWindow {
                screen: surface.modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: 48
                exclusiveZone: 48
                color: "#80101b30"
                WlrLayershell.namespace: "tessera-status"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 8
                    spacing: 8
                    Text {
                        text: Qt.formatDateTime(clock.date, "hh:mm")
                        color: "#f0f5ff"
                        font {
                            pixelSize: 16
                            bold: true
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    // Only registered application icons appear; no simulated signals.
                    RowLayout {
                        Layout.maximumWidth: Math.max(0, surface.modelData.width - 330)
                        clip: true
                        spacing: 0
                        Repeater {
                            model: SystemTray.items
                            delegate: TouchButton {
                                id: trayButton
                                required property var modelData
                                text: modelData.title
                                implicitWidth: 48
                                implicitHeight: 48
                                Layout.minimumHeight: 48
                                Layout.preferredWidth: 48
                                contentItem: Image {
                                    source: trayButton.modelData.icon
                                    sourceSize.width: 20
                                    sourceSize.height: 20
                                    fillMode: Image.Pad
                                }
                                onClicked: {
                                    if (modelData.hasMenu)
                                        modelData.display(trayButton.QsWindow.window, 0, 48);
                                    else
                                        modelData.activate();
                                }
                            }
                        }
                    }
                    StatusIcon {
                        symbol: "cellular"
                        label: "Cellular"
                        strength: root.cellularStrength
                    }
                    StatusIcon {
                        symbol: "wifi"
                        label: "Wi-Fi"
                        strength: root.wifiStrength
                    }
                    NavButton {
                        text: root.audioAvailable ? "Volume " + root.volumePercent + "%" : "Quick controls · audio unavailable"
                        symbol: root.audioAvailable && root.audioSink.audio.muted ? "volume-muted" : "volume"
                        showLabel: false
                        implicitWidth: 48
                        implicitHeight: 48
                        Layout.minimumHeight: 48
                        Layout.fillWidth: false
                        Layout.preferredWidth: 48
                        selected: panel.page === "status"
                        onClicked: panel.showPage("status")
                    }
                    RowLayout {
                        spacing: 4
                        Image {
                            source: "icons/battery.svg"
                            sourceSize.width: 22
                            sourceSize.height: 22
                            opacity: UPower.displayDevice.isPresent ? 1 : 0.35
                        }
                        Text {
                            text: UPower.displayDevice.isPresent ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "—"
                            color: "#a9e8d5"
                            font.pixelSize: 11
                            Accessible.name: UPower.displayDevice.isPresent ? "Battery " + text : "Battery status unavailable"
                        }
                    }
                    NavButton {
                        text: "Session"
                        symbol: "power"
                        showLabel: false
                        implicitWidth: 48
                        implicitHeight: 48
                        Layout.minimumHeight: 48
                        Layout.fillWidth: false
                        Layout.preferredWidth: 48
                        selected: panel.page === "session"
                        onClicked: panel.showPage("session")
                    }
                }
            }
            PanelWindow {
                screen: surface.modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                color: "#101b30"
                WlrLayershell.namespace: "tessera-home"
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                Image {
                    anchors.fill: parent
                    source: "artwork/aurora-fold.png"
                    fillMode: Image.PreserveAspectCrop
                }
                Rectangle {
                    anchors.fill: parent
                    color: "#18040d19"
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(80, parent.height * 0.17)
                    spacing: 12
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "artwork/tessarchy-mark.svg"
                        sourceSize.width: 64
                        sourceSize.height: 64
                        width: 64
                        height: 64
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "hh:mm")
                        color: "#f0f5ff"
                        font {
                            pixelSize: 64
                            weight: Font.Light
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                        color: "#a9e8d5"
                        font.pixelSize: 18
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "T E S S A R C H Y"
                        color: "#97abc6"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
