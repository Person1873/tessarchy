pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "components"

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            property string page: ""
            property var closeTarget: null
            readonly property bool expanded: page !== ""
            anchors { bottom: true; left: true; right: true }
            implicitHeight: expanded ? Math.min(620, screen.height - 24) : 72
            exclusiveZone: 72
            color: "#14242b"
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
            function appEntries() {
                return DesktopEntries.applications.values
                    .filter(entry => !entry.noDisplay && entry.command.length > 0)
                    .sort((a, b) => a.name.localeCompare(b.name));
            }
            Connections {
                target: panel.closeTarget
                function onClosed() { panel.closeTarget = null; panel.page = "windows"; }
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
                        text: panel.page === "apps" ? "Tessera · Apps"
                            : panel.page === "windows" ? "Open windows"
                            : panel.page === "close" ? "Close this window?" : "End this session?"
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
                                Text {
                                    visible: panel.appEntries().length === 0
                                    text: "No applications found in the system menus."
                                    color: "#b7c7cc"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                Repeater {
                                    model: panel.appEntries()
                                    delegate: TouchButton {
                                        required property var modelData
                                        text: modelData.name
                                        Layout.fillWidth: true
                                        onClicked: {
                                            panel.page = "";
                                            modelData.execute();
                                        }
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
                                    text: "No windows yet. Open Apps to launch one."
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
                                            text: (windowRow.modelData.activated ? "● " : "")
                                                + (windowRow.modelData.title || "Untitled window")
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
                                    onClicked: { panel.closeTarget = null; panel.page = "windows"; }
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
                                        if (target) target.close();
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
                    TouchButton {
                        text: "Apps"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        onClicked: panel.showPage("apps")
                    }
                    TouchButton {
                        text: "Windows"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        onClicked: panel.showPage("windows")
                    }
                    TouchButton {
                        text: "Session"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        onClicked: panel.showPage("session")
                    }
                }
            }
        }
    }
}
