pragma ComponentBehavior: Bound
import QtQuick
import "../SwitcherPolicy.js" as SwitcherPolicy

// Window switcher, driven by Alt+Tab and by the desktop taskbar's Windows
// button. Bare application icons in a single centred row with no panel or
// card chrome behind them: the selected icon grows and brightens. Alt release
// or a click commits, Escape or a click outside cancels.
FocusScope {
    id: control
    property var windows: []
    property var selection: null
    property var iconForWindow: window => ""
    property var titleForWindow: window => (window && window.title) || "Untitled window"
    property color accentColor: "#a9e8d5"
    property bool reducedMotion: false
    // A commit only happens once per open session, so a duplicate accept from
    // the compositor key binding and the QML key release cannot switch twice.
    property bool committed: false
    readonly property int currentIndex: windows.indexOf(selection)
    readonly property int iconWidth: 80
    implicitWidth: Math.max(1, icons.count) * iconWidth
    implicitHeight: 96
    signal windowRequested(var window)
    signal dismissed

    // Any selection change means the user is still choosing, so the commit
    // latch clears here; it exists only to swallow the second accept that the
    // compositor key binding and the QML key release both raise.
    function reset() {
        committed = false;
    }
    function selectActive() {
        committed = false;
        selection = windows[SwitcherPolicy.activeIndex(windows)] || null;
    }
    function step(direction) {
        committed = false;
        selection = windows[SwitcherPolicy.advance(currentIndex, direction, windows.length)] || null;
    }
    function activateCurrent() {
        if (committed) return;
        if (selection && windows.indexOf(selection) >= 0 && selection.wayland) {
            committed = true;
            windowRequested(selection);
        } else dismissed();
    }
    onWindowsChanged: {
        if (windows.indexOf(selection) < 0) selectActive();
        if (!windows.length) dismissed();
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
            activateCurrent();
            event.accepted = true;
        }
    }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    Keys.onReturnPressed: activateCurrent()
    Keys.onEnterPressed: activateCurrent()
    Keys.onEscapePressed: dismissed()

    ListView {
        id: icons
        objectName: "quickSwitcherIcons"
        anchors.fill: parent
        orientation: ListView.Horizontal
        model: control.windows
        currentIndex: control.currentIndex
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        onCurrentIndexChanged: Qt.callLater(() => {
            if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain);
        })
        delegate: Item {
            id: app
            required property var modelData
            required property int index
            readonly property bool selected: index === control.currentIndex
            width: control.iconWidth
            height: icons.height
            Image {
                anchors.centerIn: parent
                width: app.selected ? 64 : 48
                height: width
                readonly property string fallbackSource: "../artwork/tessarchy-mark.svg"
                source: control.iconForWindow(app.modelData) || fallbackSource
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
                opacity: app.selected ? 1 : 0.65
                Behavior on width {
                    enabled: !control.reducedMotion
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }
            MouseArea {
                anchors.fill: parent
                Accessible.role: Accessible.Button
                Accessible.name: "Switch to " + control.titleForWindow(app.modelData)
                onClicked: {
                    control.selection = app.modelData;
                    control.activateCurrent();
                }
            }
        }
    }
}
