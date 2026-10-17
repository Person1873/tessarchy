pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import "components"
import "LayoutPolicy.js" as Policy

ShellRoot {
    id: root
    signal controlsRequested
    IpcHandler {
        target: "controls"
        function toggle(): void { root.controlsRequested(); }
    }
    signal replayBrand
    signal switcherCommand(string action)
    IpcHandler {
        target: "switcher"
        function next(): void { root.switcherCommand("next"); }
        function previous(): void { root.switcherCommand("previous"); }
        function accept(): void { root.switcherCommand("accept"); }
        function cancel(): void { root.switcherCommand("cancel"); }
    }
    readonly property color accentColor: shellPreferences.accent === "iris" ? "#c6b7ff" : shellPreferences.accent === "ice" ? "#99d7ff" : "#a9e8d5"
    Settings {
        id: shellPreferences
        location: "file://" + (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/tessarchy/shell.ini"
        category: "Shell"
        property string layoutMode: "auto"
        property string accent: "mint"
        property bool reducedMotion: false
        property bool showLabels: false
        property bool use24Hour: true
        property real barOpacity: 0.22
        property real wallpaperDim: 0.12
    }
    RadioBackend { id: radioBackend }
    // Signal strength remains unavailable until a real connection backend is added.
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
            readonly property string mode: Policy.effectiveMode(shellPreferences.layoutMode, modelData.width, modelData.height)
            readonly property bool isPhone: mode === "phone"
            readonly property int navHeight: isPhone ? 76 : 84
            readonly property int launcherRows: Math.ceil(4 / Policy.columns(mode, Policy.panelWidth(mode, modelData.width) - 32))
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
            PanelWindow {
                id: panel
                screen: surface.modelData
                property string page: ""
                property var closeTarget: null
                property bool keyboardSwitch: false
                readonly property bool expanded: page !== ""
                anchors {
                    bottom: true
                    left: false
                    right: false
                }
                implicitWidth: expanded ? Policy.panelWidth(surface.mode, surface.modelData.width) : Math.min(surface.modelData.width - 32, surface.isPhone ? 272 : 360)
                implicitHeight: expanded ? Math.min(page === "windows" ? surface.modelData.height - 60 : page === "apps" ? surface.launcherRows * 124 + 156 : surface.mode === "tablet" ? 740 : 640, surface.modelData.height - 64) : surface.navHeight
                exclusiveZone: surface.navHeight
                color: "transparent"
                Rectangle {
                    anchors.fill: parent
                    anchors.bottomMargin: panel.expanded ? 0 : 12
                    radius: 26
                    color: panel.expanded ? (panel.page === "windows" ? "#b3101b30" : "#c2101b30") : Qt.rgba(0.063, 0.106, 0.188, shellPreferences.barOpacity)
                    border.width: 1
                    border.color: Qt.alpha(root.accentColor, 0.15)
                }
                WlrLayershell.namespace: "tessera"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: panel.keyboardSwitch && panel.page === "windows" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                function showPage(name) {
                    if (name === "windows" && page !== "windows") switcher.selectActive();
                    keyboardSwitch = false;
                    closeTarget = null;
                    page = page === name ? "" : name;
                }
                function launch(command) {
                    Quickshell.execDetached(command);
                    page = "";
                }
                onPageChanged: { if (page !== "windows") keyboardSwitch = false; }
                Connections {
                    target: root
                    function onSwitcherCommand(action) {
                        if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name !== surface.modelData.name) return;
                        if (action === "accept") {
                            if (panel.keyboardSwitch && panel.page === "windows") switcher.activateCurrent();
                        } else if (action === "cancel") {
                            if (panel.keyboardSwitch) panel.page = "";
                        } else {
                            const opening = panel.page !== "windows";
                            if (opening) switcher.selectActive();
                            panel.keyboardSwitch = true;
                            panel.page = "windows";
                            switcher.step(action === "previous" ? -1 : 1);
                            switcher.forceActiveFocus();
                        }
                    }
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
                    anchors.margins: 12
                    anchors.bottomMargin: panel.expanded ? 12 : 18
                    anchors.leftMargin: surface.isPhone ? 12 : 16
                    anchors.rightMargin: surface.isPhone ? 12 : 16
                    spacing: 8
                    ColumnLayout {
                        visible: panel.expanded
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        Text {
                            visible: panel.page !== "windows"
                            text: panel.page === "apps" ? "Your space" : panel.page === "close" ? "Close this window?" : panel.page === "settings" ? "Settings" : "End this session?"
                            color: root.accentColor
                            font.pixelSize: 22
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        AppSwitcher {
                            id: switcher
                            visible: panel.page === "windows"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            windows: Hyprland.toplevels.values
                            fillApp: surface.mode !== "desktop"
                            accentColor: root.accentColor
                            reducedMotion: shellPreferences.reducedMotion
                            onActivated: panel.page = ""
                            onDismissed: panel.page = ""
                            onCloseRequested: target => {
                                panel.closeTarget = target;
                                panel.page = "close";
                            }
                        }
                        ScrollView {
                            visible: panel.page !== "windows"
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
                                        columns: Policy.columns(surface.mode, width)
                                        columnSpacing: 12
                                        Layout.fillWidth: true
                                        AppTile {
                                            text: "Browser"
                                            symbol: "browser"
                                            accentColor: root.accentColor
                                            onClicked: panel.launch(["firefox"])
                                        }
                                        AppTile {
                                            text: "Terminal"
                                            symbol: "terminal"
                                            accentColor: root.accentColor
                                            onClicked: panel.launch(["foot"])
                                        }
                                        AppTile {
                                            text: "Settings"
                                            symbol: "settings"
                                            accentColor: root.accentColor
                                            onClicked: panel.showPage("settings")
                                        }
                                        AppTile {
                                            text: "Controls"
                                            symbol: "controls"
                                            accentColor: root.accentColor
                                            onClicked: statusBar.toggleDrawer()
                                        }
                                    }
                                    Text {
                                        text: "Prototype · Physical keyboard needed for text input."
                                        color: "#b7c7cc"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                                Loader {
                                    visible: active
                                    active: panel.page === "settings"
                                    Layout.fillWidth: true
                                    sourceComponent: SettingsPage {
                                        preferences: shellPreferences
                                        activeMode: Policy.title(surface.mode)
                                        displayWidth: surface.modelData.width
                                        displayHeight: surface.modelData.height
                                        accentColor: root.accentColor
                                        onEndSessionRequested: panel.page = "session"
                                        onControlsRequested: statusBar.toggleDrawer()
                                        onReplayRequested: root.replayBrand()
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
                        Layout.preferredHeight: 48
                        spacing: 8
                        NavButton {
                            text: "Back"
                            symbol: "back"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            enabled: panel.expanded || statusBar.drawerOpen
                            onClicked: {
                                statusBar.drawerOpen = false;
                                panel.closeTarget = null;
                                panel.page = "";
                            }
                        }
                        NavButton {
                            text: surface.mode === "desktop" ? "Apps" : "Home"
                            symbol: "home"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "apps"
                            onClicked: panel.showPage("apps")
                        }
                        NavButton {
                            text: surface.mode === "desktop" ? "Windows" : "Recents"
                            symbol: "recents"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "windows"
                            onClicked: panel.showPage("windows")
                        }
                        NavButton {
                            visible: !surface.isPhone
                            text: "Settings"
                            symbol: "settings"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "settings"
                            onClicked: panel.showPage("settings")
                        }
                    }
                }
            }
            PanelWindow {
                id: statusBar
                property bool drawerOpen: false
                function toggleDrawer() {
                    drawerOpen = !drawerOpen;
                    if (drawerOpen) { panel.closeTarget = null; panel.page = ""; radioBackend.refresh(); }
                }
                Connections {
                    target: root
                    function onControlsRequested() {
                        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === surface.modelData.name) statusBar.toggleDrawer();
                    }
                }
                screen: surface.modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: drawerOpen ? Math.min(surface.modelData.height - surface.navHeight - 12, quickSheet.implicitHeight + 76) : 48
                exclusiveZone: 48
                color: "transparent"
                Rectangle {
                    anchors.fill: parent
                    radius: statusBar.drawerOpen ? 28 : 0
                    color: Qt.rgba(0.063, 0.106, 0.188, statusBar.drawerOpen ? 0.76 : shellPreferences.barOpacity)
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.alpha(root.accentColor, 0.1) }
                }
                WlrLayershell.namespace: "tessera-status"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                Item {
                    id: statusHeader
                    width: parent.width
                    height: 48
                    DragHandler {
                        target: null
                        xAxis.enabled: false
                        dragThreshold: 6
                        grabPermissions: PointerHandler.CanTakeOverFromAnything
                        property bool triggered: false
                        onActiveChanged: { if (active) triggered = false; }
                        onActiveTranslationChanged: {
                            // Expand before the pointer leaves the 48px input strip.
                            if (!triggered && activeTranslation.y > 10 && !statusBar.drawerOpen) {
                                triggered = true;
                                statusBar.toggleDrawer();
                            } else if (!triggered && activeTranslation.y < -10 && statusBar.drawerOpen) {
                                triggered = true;
                                statusBar.toggleDrawer();
                            }
                        }
                    }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 8
                    spacing: surface.modelData.width < 360 ? 4 : 8
                    TouchButton {
                        id: mobileClock
                        text: Qt.formatDateTime(clock.date, shellPreferences.use24Hour ? "h:mm" : "h:mm AP").replace(/ [AP]M$/, "")
                        Accessible.name: "Clock " + Qt.formatDateTime(clock.date, shellPreferences.use24Hour ? "h:mm" : "h:mm AP") + ", quick controls"
                        Layout.minimumHeight: 48
                        Layout.preferredWidth: 66
                        implicitHeight: 48
                        padding: 0
                        background: Item {}
                        contentItem: Text {
                            text: mobileClock.text
                            color: "#f0f5ff"
                            verticalAlignment: Text.AlignVCenter
                            font { pixelSize: 16; weight: Font.DemiBold; letterSpacing: 0.2 }
                        }
                        onClicked: statusBar.toggleDrawer()
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    // Only registered application icons appear; no simulated signals.
                    RowLayout {
                        Layout.maximumWidth: Math.max(0, surface.modelData.width - 370)
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
                    Image {
                        visible: !!(radioBackend.state.airplane && radioBackend.state.airplane.enabled)
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18
                        source: "icons/airplane.svg"
                        sourceSize.width: 18; sourceSize.height: 18
                        Accessible.name: "Airplane mode on"
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
                        selected: statusBar.drawerOpen
                        onClicked: statusBar.toggleDrawer()
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
                            visible: surface.modelData.width >= 380
                            text: UPower.displayDevice.isPresent ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "—"
                            color: "#a9e8d5"
                            font.pixelSize: 11
                            Accessible.name: UPower.displayDevice.isPresent ? "Battery " + text : "Battery status unavailable"
                        }
                    }
                    NavButton {
                        text: "Settings"
                        symbol: "settings"
                        showLabel: false
                        implicitWidth: 48
                        implicitHeight: 48
                        Layout.minimumHeight: 48
                        Layout.fillWidth: false
                        Layout.preferredWidth: 48
                        accentColor: root.accentColor
                        selected: panel.page === "settings"
                        onClicked: { statusBar.drawerOpen = false; panel.showPage("settings"); }
                    }
                }
                }
                ScrollView {
                    x: 16; y: 60
                    width: parent.width - 32
                    height: parent.height - y
                    visible: statusBar.drawerOpen
                    clip: true
                    contentWidth: availableWidth
                    QuickSettings {
                        id: quickSheet
                        width: parent.width
                        radios: radioBackend
                        preferences: shellPreferences
                        activeMode: Policy.title(surface.mode)
                        date: clock.date
                        use24Hour: shellPreferences.use24Hour
                        accentColor: root.accentColor
                        audioSink: root.audioSink
                        onDismissed: statusBar.drawerOpen = false
                        onSettingsRequested: { statusBar.drawerOpen = false; panel.showPage("settings"); }
                    }
                }
                Connections {
                    target: panel
                    function onPageChanged() { if (panel.page !== "") statusBar.drawerOpen = false; }
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
                    color: Qt.rgba(0.016, 0.05, 0.1, shellPreferences.wallpaperDim)
                }
                Column {
                    visible: !panel.expanded
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(64, parent.height * (surface.isPhone ? 0.14 : 0.18))
                    spacing: 12
                    BrandMark {
                        id: homeBrand
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 96
                        height: 96
                        reducedMotion: shellPreferences.reducedMotion
                    }
                    Connections {
                        target: root
                        function onReplayBrand() {
                            homeBrand.replay();
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, shellPreferences.use24Hour ? "hh:mm" : "h:mm AP")
                        color: "#f0f5ff"
                        font {
                            pixelSize: surface.isPhone ? 58 : 72
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
                        text: "TESSARCHY"
                        color: root.accentColor
                        font {
                            pixelSize: 12
                            bold: true
                            letterSpacing: 5
                        }
                    }
                }
            }
        }
    }
}
