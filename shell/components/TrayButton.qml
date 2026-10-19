import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    property color accentColor: "#a9e8d5"
    property bool selected: false
    Layout.minimumWidth: 48
    Layout.minimumHeight: 48
    Layout.preferredWidth: 48
    implicitWidth: 48
    implicitHeight: 48
    padding: 0
    focusPolicy: Qt.NoFocus
    display: AbstractButton.IconOnly
    icon.width: 18
    icon.height: 18
    icon.color: "#d0f3e9"
    background: Rectangle {
        radius: 10
        color: control.down ? Qt.alpha(control.accentColor, 0.3)
                           : control.selected ? Qt.alpha(control.accentColor, 0.15) : "transparent"
    }
}
