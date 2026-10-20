import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    property color accentColor: Theme.accent
    property bool selected: false
    property int slotWidth: 48
    Layout.minimumWidth: slotWidth
    Layout.minimumHeight: 48
    Layout.preferredWidth: slotWidth
    implicitWidth: slotWidth
    implicitHeight: 48
    padding: 0
    focusPolicy: Qt.NoFocus
    display: AbstractButton.IconOnly
    icon.width: 18
    icon.height: 18
    icon.color: Theme.textSecondary
    background: Rectangle {
        radius: Theme.radius("card", 10, height)
        color: control.down ? Qt.alpha(control.accentColor, 0.3)
                           : control.selected ? Qt.alpha(control.accentColor, 0.15) : "transparent"
    }
}
