import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    Layout.minimumWidth: 48
    Layout.minimumHeight: 56
    implicitWidth: 120
    implicitHeight: 56
    padding: 10
    focusPolicy: Qt.NoFocus
    property color accentColor: Theme.accent
    property bool destructive: false
    property bool selected: false
    contentItem: Text {
        textFormat: Text.PlainText
        text: control.text
        color: control.enabled ? Theme.text : Theme.muted
        font.pixelSize: 16
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: Theme.radius("button", 12, height)
        color: control.down ? Theme.pressed(control.accentColor) : control.destructive ? Theme.dangerSurface : control.selected ? Theme.selected(control.accentColor) : Theme.glass
        border.color: control.destructive ? Theme.danger : control.selected ? control.accentColor : Theme.glassBorder
        border.width: Theme.borderWidth(1)
    }
    Accessible.name: text
}
