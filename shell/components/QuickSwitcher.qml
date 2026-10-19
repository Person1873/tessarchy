pragma ComponentBehavior: Bound
import QtQuick
import "../SwitcherPolicy.js" as SwitcherPolicy

FocusScope {
    id: control
    property var windows: []
    property var selection: null
    property var iconForWindow: window => ""
    readonly property int currentIndex: windows.indexOf(selection)
    implicitWidth: windows.length * 80
    implicitHeight: 96
    signal windowRequested(var window)
    signal dismissed

    function selectActive() {
        selection = windows[SwitcherPolicy.activeIndex(windows)] || null;
    }
    function step(direction) {
        selection = windows[SwitcherPolicy.advance(currentIndex, direction, windows.length)] || null;
    }
    function activateCurrent() {
        if (selection && windows.indexOf(selection) >= 0 && selection.wayland)
            windowRequested(selection);
        else dismissed();
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
            width: 80
            height: icons.height
            Image {
                anchors.centerIn: parent
                width: app.selected ? 64 : 48
                height: width
                source: control.iconForWindow(app.modelData) || "../artwork/tessarchy-mark.svg"
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
                opacity: app.selected ? 1 : 0.65
            }
            MouseArea {
                anchors.fill: parent
                Accessible.role: Accessible.Button
                Accessible.name: "Switch to " + (app.modelData.title || "Application")
                onClicked: {
                    control.selection = app.modelData;
                    control.activateCurrent();
                }
            }
        }
    }
}
