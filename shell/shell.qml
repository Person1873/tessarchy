pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import "components"
import "LayoutPolicy.js" as Policy
import "AppPolicy.js" as Apps

ShellRoot {
    id: root
    signal controlsRequested
    IpcHandler {
        target: "controls"
        function toggle(): void { root.controlsRequested(); }
    }
    signal openAppRequested(string page)
    IpcHandler {
        target: "apps"
        function phone(): void { root.openAppRequested("phone"); }
        function messages(): void { root.openAppRequested("messages"); }
        function cellular(): void { root.openAppRequested("cellular"); }
        function sounds(): void { root.openAppRequested("sounds"); }
    }
    signal replayBrand
    readonly property var activeWindow: Hyprland.activeToplevel || Hyprland.toplevels.values.find(window => window.wayland && window.wayland.activated) || null
    signal actionRequested(string action)
    IpcHandler {
        target: "actions"
        function closeWindow(): void { root.actionRequested("close"); }
        function endSession(): void { root.actionRequested("exit"); }
    }
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
        property bool doNotDisturb: false
    }
    RadioBackend { id: radioBackend }
    CommunicationBackend { id: communications }
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    // Signal strength remains unavailable until a real connection backend is added.
    property real wifiStrength: -1
    readonly property real cellularStrength: communications.state.cellular.signal === undefined ? -1 : communications.state.cellular.signal / 100
    // squeekboard via tessarchy-osk; it also appears by itself for text fields.
    readonly property bool oskAvailable: Quickshell.env("TESSARCHY_OSK") === "1"
    // Desktop mode must never raise the on-screen keyboard; touch modes may.
    function applyOskMode(mode) {
        if (!oskAvailable) return;
        Quickshell.execDetached(["tessarchy-osk", Policy.oskArmed(mode) ? "enable" : "disable"]);
    }
    readonly property var audioSink: audioLoader.item ? (audioLoader.item as AudioStatus).sink : null
    readonly property bool audioAvailable: !!(audioSink && audioSink.ready && audioSink.audio)
    readonly property int volumePercent: audioAvailable ? Math.round(audioSink.audio.volume * 100) : 0
    Loader {
        id: audioLoader
        active: Quickshell.env("TESSARCHY_AUDIO") === "1"
        source: "components/AudioStatus.qml"
    }
    readonly property var activePlayer: {
        const players = Mpris.players.values;
        const index = Policy.preferredPlayerIndex(players.map(player => player.isPlaying));
        return index < 0 ? null : players[index];
    }
    // Notifications: the server tracks every delivered alert (history truth),
    // while pop-ups are ephemeral views over at most the three newest items.
    // Capability flags match what the card actually renders: plain body text.
    readonly property int notificationCount: notificationServer.trackedNotifications.values.length
    property var popupNotifications: []
    function queuePopup(notification) {
        const next = root.popupNotifications.slice();
        next.unshift(notification);
        root.popupNotifications = next.slice(0, 3);
    }
    function hidePopup(notification) {
        root.popupNotifications = root.popupNotifications.filter(n => n !== notification);
    }
    function closeNotification(notification) {
        root.hidePopup(notification);
        notification.dismiss();
    }
    function dismissAllNotifications() {
        const items = notificationServer.trackedNotifications.values.slice();
        for (let i = 0; i < items.length; i++) items[i].dismiss();
    }
    NotificationServer {
        id: notificationServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: false
        actionIconsSupported: false
        imageSupported: false
        inlineReplySupported: false
        persistenceSupported: false
        onNotification: notification => {
            notification.tracked = true;
            if (shellPreferences.doNotDisturb)
                return;
            root.queuePopup(notification);
        }
    }
    Variants {
        model: Quickshell.screens
        Scope {
            id: surface
            required property var modelData
            readonly property string mode: Policy.effectiveMode(shellPreferences.layoutMode, modelData.width, modelData.height)
            readonly property bool isPhone: mode === "phone"
            readonly property var dock: Policy.dockLayout(mode, modelData.width, root.oskAvailable)
            readonly property int navHeight: dock.rows > 1 ? dock.rows * 56 + 20 : isPhone ? 76 : 84
            readonly property int launcherRows: Math.ceil((panel.appEntries.length + 4) / Policy.columns(mode, Policy.panelWidth(mode, modelData.width) - 32))
            readonly property bool showWorkspaces: Policy.showWorkspaces(mode, modelData.width)
            readonly property var workspaceIds: {
                const ids = [];
                const workspaces = Hyprland.workspaces.values;
                for (let i = 0; i < workspaces.length; i++) ids.push(workspaces[i].id);
                return ids;
            }
            readonly property int workspaceCount: Policy.workspaceSlots(workspaceIds)

            // Hyprland.workspaces only holds existing workspaces; numbered slots
            // may refer to one that has not been created yet.
            function workspaceFor(id) {
                const workspaces = Hyprland.workspaces.values;
                for (let i = 0; i < workspaces.length; i++) {
                    if (workspaces[i].id === id) return workspaces[i];
                }
                return null;
            }
            function switchWorkspace(id) {
                const workspace = workspaceFor(id);
                if (workspace) {
                    // activate() handles both classic and Lua dispatch modes.
                    workspace.activate();
                    return;
                }
                if (Hyprland.usingLua) Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
                else Hyprland.dispatch("workspace " + id);
            }
            readonly property string modeLabel: (shellPreferences.layoutMode === "auto" ? "Auto · " : "") + Policy.title(mode)
            // Pop-ups render once, on the first screen, not on every output.
            readonly property bool isPrimaryScreen: Quickshell.screens.length > 0 && Quickshell.screens[0] === modelData
            // Arm or disarm the keyboard whenever the layout for this output changes.
            onModeChanged: if (isPrimaryScreen) root.applyOskMode(mode)
            Component.onCompleted: if (isPrimaryScreen) root.applyOskMode(mode)
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
            PanelWindow {
                id: panel
                screen: surface.modelData
                readonly property var appEntries: Apps.majorApplications(DesktopEntries.applications.values)
                property string page: ""
                property var closeTarget: null
                property bool keyboardSwitch: false
                property string messageRecipient: ""
                readonly property bool expanded: page !== ""
                // The keyboard is a separate top-layer surface that would cover
                // the drawer, so shell pages dismiss it like an IME on Recents.
                onExpandedChanged: {
                    if (expanded && root.oskAvailable)
                        Quickshell.execDetached(["tessarchy-osk", "hide"]);
                }
                anchors {
                    bottom: true
                    left: false
                    right: false
                }
                implicitWidth: expanded ? Policy.panelWidth(surface.mode, surface.modelData.width) : surface.dock.width
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
                WlrLayershell.keyboardFocus: panel.keyboardSwitch && panel.page === "windows" ? WlrKeyboardFocus.Exclusive : ["phone", "messages", "cellular", "settings", "sounds"].indexOf(panel.page) >= 0 ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
                onPageChanged: {
                    if (page !== "windows") keyboardSwitch = false;
                    if (["phone", "messages", "cellular", "sounds"].indexOf(page) >= 0) communications.request("status");
                }
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
                    target: root
                    function onActionRequested(action) {
                        if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name !== surface.modelData.name) return;
                        panel.keyboardSwitch = false;
                        panel.closeTarget = action === "close" ? root.activeWindow : null;
                        panel.page = action === "exit" ? "session" : panel.closeTarget ? "close" : "";
                    }
                }
                Connections {
                    target: root
                    function onOpenAppRequested(name) {
                        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === surface.modelData.name) panel.page = name;
                    }
                }
                Connections {
                    target: communications
                    function onIncoming() {
                        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === surface.modelData.name) {
                            panel.page = "phone";
                            statusBar.drawerOpen = false;
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
                    anchors.bottomMargin: panel.expanded ? 12 : 16
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
                            text: panel.page === "apps" ? "Your space" : panel.page === "close" ? "Close this window?" : panel.page === "settings" ? "Settings" : panel.page === "phone" ? "Phone" : panel.page === "messages" ? "Messages" : panel.page === "cellular" ? "SIM & cellular" : panel.page === "sounds" ? "Sounds & ringtones" : panel.page === "notifications" ? "Alerts" : "End this session?"
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
                                        Repeater {
                                            model: panel.appEntries
                                            delegate: AppTile {
                                                required property var modelData
                                                text: modelData.name
                                                symbol: "browser"
                                                iconSource: Quickshell.iconPath(modelData.icon, true)
                                                accentColor: root.accentColor
                                                onClicked: {
                                                    panel.page = "";
                                                    modelData.execute();
                                                }
                                            }
                                        }
                                        AppTile { text: "Phone"; symbol: "call"; accentColor: root.accentColor; onClicked: panel.showPage("phone") }
                                        AppTile { text: "Messages"; symbol: "messages"; accentColor: root.accentColor; onClicked: panel.showPage("messages") }
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
                                        AppTile {
                                            text: "Alerts"
                                            symbol: "bell"
                                            accentColor: root.accentColor
                                            onClicked: panel.showPage("notifications")
                                        }
                                    }
                                    Text {
                                        text: root.oskAvailable ? "Prototype · The keyboard opens for text fields; Keyboard shows or hides it." : "Prototype · Physical keyboard needed for text input."
                                        color: "#b7c7cc"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                                Loader {
                                    visible: active
                                    active: panel.page === "phone"
                                    Layout.fillWidth: true
                                    sourceComponent: PhoneApp {
                                        backend: communications
                                        accentColor: root.accentColor
                                        onSimRequested: panel.page = "cellular"
                                        onMessageRequested: number => { panel.messageRecipient = number; panel.page = "messages"; }
                                    }
                                }
                                Loader {
                                    visible: active
                                    active: panel.page === "messages"
                                    Layout.fillWidth: true
                                    sourceComponent: MessagesApp {
                                        backend: communications
                                        accentColor: root.accentColor
                                        recipient: panel.messageRecipient
                                    }
                                }
                                Loader {
                                    visible: active
                                    active: panel.page === "sounds"
                                    Layout.fillWidth: true
                                    sourceComponent: SoundSettings { backend: communications; accentColor: root.accentColor }
                                }
                                Loader {
                                    visible: active
                                    active: panel.page === "cellular"
                                    Layout.fillWidth: true
                                    sourceComponent: CellularSettings { backend: communications; accentColor: root.accentColor }
                                }
                                Loader {
                                    visible: active
                                    active: panel.page === "settings"
                                    Layout.fillWidth: true
                                    sourceComponent: SettingsPage {
                                        backend: communications
                                        onCellularRequested: panel.page = "cellular"
                                        onSoundsRequested: panel.page = "sounds"
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
                                Loader {
                                    visible: active
                                    active: panel.page === "notifications"
                                    Layout.fillWidth: true
                                    sourceComponent: NotificationCenter {
                                        server: notificationServer
                                        preferences: shellPreferences
                                        accentColor: root.accentColor
                                        onClearAllRequested: root.dismissAllNotifications()
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
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 + (surface.dock.rows - 1) * 56
                        columns: surface.dock.columns
                        columnSpacing: 4
                        rowSpacing: 8
                        NavButton {
                            text: "Phone"; symbol: "call"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "phone"
                            onClicked: panel.showPage("phone")
                        }
                        NavButton {
                            text: "Messages"; symbol: "messages"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "messages"
                            onClicked: panel.showPage("messages")
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
                        NavButton {
                            // Panel never takes keyboard focus, so the app keeps its text field.
                            visible: root.oskAvailable && surface.mode !== "desktop"
                            text: "Keyboard"
                            symbol: "keyboard"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            onClicked: Quickshell.execDetached(["tessarchy-osk", "toggle"])
                        }
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
                    }
                }
            }
            PanelWindow {
                id: statusBar
                Timer {
                    id: screenshotTimer
                    interval: shellPreferences.reducedMotion ? 100 : 300
                    onTriggered: Quickshell.execDetached(["tessera-screenshot"])
                }
                property bool drawerOpen: false
                function toggleDrawer() {
                    drawerOpen = !drawerOpen;
                    if (drawerOpen) {
                        panel.closeTarget = null;
                        panel.page = "";
                        radioBackend.refresh();
                        if (root.oskAvailable) Quickshell.execDetached(["tessarchy-osk", "hide"]);
                    }
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
                    RowLayout {
                        visible: surface.showWorkspaces
                        spacing: 4
                        Repeater {
                            model: surface.workspaceCount
                            delegate: TouchButton {
                                id: workspaceButton
                                required property int index
                                readonly property int workspaceId: index + 1
                                readonly property var workspace: surface.workspaceFor(workspaceId)
                                text: String(workspaceId)
                                selected: workspace ? (workspace.focused || workspace.active) : false
                                implicitWidth: 48
                                implicitHeight: 48
                                Layout.minimumWidth: 48
                                Layout.minimumHeight: 48
                                Layout.preferredWidth: 48
                                padding: 0
                                accentColor: root.accentColor
                                Accessible.name: "Workspace " + workspaceId + (selected ? " active" : " inactive")
                                Accessible.role: Accessible.Button
                                onClicked: surface.switchWorkspace(workspaceId)
                            }
                        }
                    }
                    TouchButton {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 64
                        Layout.minimumHeight: 48
                        implicitHeight: 48
                        text: "Quick controls"
                        Accessible.name: statusBar.drawerOpen ? "Collapse quick controls" : "Open quick controls, or swipe down"
                        padding: 0
                        background: Item {}
                        contentItem: Column {
                            spacing: 4
                            topPadding: 15
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 28; height: 3; radius: 2; color: root.accentColor }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: statusBar.drawerOpen ? "⌃" : "⌄"; color: root.accentColor; font.pixelSize: 14 }
                        }
                        onClicked: statusBar.toggleDrawer()
                    }
                    // Focused window title; only meaningful in the desktop layout.
                    Text {
                        visible: surface.showWorkspaces && surface.mode === "desktop" && text.length > 0
                        text: root.activeWindow ? (root.activeWindow.title || "") : ""
                        color: "#d0dced"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 360
                        Layout.leftMargin: 8
                        Accessible.name: text.length > 0 ? "Focused window " + text : ""
                    }
                    NavButton {
                        text: root.notificationCount > 0 ? String(root.notificationCount) : ""
                        symbol: "bell"
                        showLabel: root.notificationCount > 0
                        implicitWidth: 48
                        implicitHeight: 48
                        Layout.minimumHeight: 48
                        Layout.fillWidth: false
                        Layout.preferredWidth: 48
                        accentColor: root.accentColor
                        selected: panel.page === "notifications"
                        Accessible.name: root.notificationCount > 0 ? "Notifications, " + root.notificationCount + " unread" : "Notifications"
                        onClicked: panel.showPage("notifications")
                    }
                    // Desktop app indicators do not belong in the compact mobile status strip.
                    RowLayout {
                        visible: surface.mode === "desktop"
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
                        visible: surface.modelData.width >= 700
                        text: root.audioAvailable && root.audioSink.audio.muted ? "Unmute audio" : "Mute audio"
                        symbol: root.audioAvailable && root.audioSink.audio.muted ? "volume-muted" : "volume"
                        showLabel: false
                        implicitWidth: 48; implicitHeight: 48
                        Layout.minimumHeight: 48; Layout.fillWidth: false; Layout.preferredWidth: 48
                        enabled: root.audioAvailable
                        onClicked: root.audioSink.audio.muted = !root.audioSink.audio.muted
                    }
                    NavButton {
                        visible: surface.modelData.width >= 560
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
                    x: (parent.width - width) / 2; y: 60
                    width: Math.min(parent.width - 32, 720)
                    height: Math.max(0, parent.height - y - 56)
                    visible: statusBar.drawerOpen
                    clip: true
                    contentWidth: availableWidth
                    QuickSettings {
                        bluetoothAdapter: root.bluetoothAdapter
                        id: quickSheet
                        width: parent.width
                        radios: radioBackend
                        preferences: shellPreferences
                        activeMode: Policy.title(surface.mode)
                        date: clock.date
                        use24Hour: shellPreferences.use24Hour
                        accentColor: root.accentColor
                        audioSink: root.audioSink
                        audioBackendAvailable: audioLoader.active
                        onScreenshotRequested: {
                            statusBar.drawerOpen = false;
                            screenshotTimer.restart();
                        }
                        mediaPlayer: root.activePlayer
                        onCellularRequested: { statusBar.drawerOpen = false; panel.page = "cellular"; }
                        onDismissed: statusBar.drawerOpen = false
                        onSettingsRequested: { statusBar.drawerOpen = false; panel.showPage("settings"); }
                    }
                }
                TouchButton {
                    visible: statusBar.drawerOpen
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 32, 720)
                    height: 48
                    text: "Collapse quick controls"
                    background: Item {}
                    contentItem: Item { Rectangle { anchors.centerIn: parent; width: 40; height: 4; radius: 2; color: root.accentColor } }
                    onClicked: statusBar.drawerOpen = false
                    DragHandler {
                        target: null
                        xAxis.enabled: false
                        onActiveTranslationChanged: { if (activeTranslation.y < -20) statusBar.drawerOpen = false; }
                    }
                }
                Connections {
                    target: panel
                    function onPageChanged() { if (panel.page !== "") statusBar.drawerOpen = false; }
                }
            }
            // Pop-up host: an overlay window that never reserves space and
            // disappears entirely when no pop-ups are queued.
            PanelWindow {
                id: popupHost
                screen: surface.modelData
                visible: surface.isPrimaryScreen && root.popupNotifications.length > 0 && panel.page === ""
                readonly property var placement: Policy.notificationPlacement(surface.mode, surface.modelData.width)
                anchors {
                    top: true
                    right: true
                    left: placement.fullWidth
                }
                margins.top: placement.topOffset
                implicitWidth: placement.maxWidth
                implicitHeight: popupColumn.implicitHeight
                exclusiveZone: 0
                color: "transparent"
                WlrLayershell.namespace: "tessera-notifications"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                ColumnLayout {
                    id: popupColumn
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: root.popupNotifications
                        delegate: ColumnLayout {
                            id: popupItem
                            required property var modelData
                            Layout.fillWidth: true
                            NotificationCard {
                                Layout.fillWidth: true
                                notification: popupItem.modelData
                                accentColor: root.accentColor
                                onOpened: root.hidePopup(popupItem.modelData)
                                onClosed: root.closeNotification(popupItem.modelData)
                            }
                            Timer {
                                interval: Policy.notificationTimeout(popupItem.modelData.urgency) * 1000
                                running: interval > 0
                                onTriggered: root.hidePopup(popupItem.modelData)
                            }
                        }
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
