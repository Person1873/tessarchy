pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: control
    property var model: []
    property string textRole: ""
    property int currentIndex: -1
    property bool expanded: false
    readonly property string currentText: currentIndex >= 0 && currentIndex < model.length ? (textRole ? model[currentIndex][textRole] : String(model[currentIndex])) : "Choose…"
    property string displayText: currentText
    signal activated(int index)
    Layout.fillWidth: true
    Layout.minimumHeight: 52
    spacing: 6
    TouchButton {
        text: control.displayText + (control.expanded ? "  ⌃" : "  ⌄")
        Layout.fillWidth: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: control.Accessible.name || control.displayText
        onClicked: control.expanded = !control.expanded
    }
    ColumnLayout {
        visible: control.expanded
        Layout.fillWidth: true
        spacing: 4
        Repeater {
            model: control.model
            delegate: TouchButton {
                required property var modelData
                required property int index
                text: control.textRole ? modelData[control.textRole] : String(modelData)
                selected: control.currentIndex === index
                Layout.fillWidth: true
                focusPolicy: Qt.StrongFocus
                onClicked: {
                    control.currentIndex = index;
                    control.expanded = false;
                    control.activated(index);
                }
            }
        }
    }
}
