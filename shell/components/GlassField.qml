import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    id: field
    implicitHeight: 52
    Layout.minimumHeight: 52
    Layout.fillWidth: true
    color: "#edf6f6"
    placeholderTextColor: "#91aab7"
    selectionColor: "#467c7a"
    font.pixelSize: 16
    padding: 14
    selectByMouse: true
    background: Rectangle {
        radius: 16
        color: "#501c2c43"
        border.color: field.activeFocus ? "#a9e8d5" : "#50677f8d"
    }
    Accessible.name: placeholderText
}
