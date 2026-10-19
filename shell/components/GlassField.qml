import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    id: field
    implicitHeight: 52
    Layout.minimumHeight: 52
    Layout.fillWidth: true
    color: Theme.inputText
    placeholderTextColor: Theme.inputPlaceholder
    selectionColor: Theme.inputSelection
    font.pixelSize: 16
    padding: 14
    selectByMouse: true
    background: Rectangle {
        radius: 16
        color: Theme.glass
        border.color: field.activeFocus ? Theme.accent : Theme.inputBorder
    }
    Accessible.name: placeholderText
}
