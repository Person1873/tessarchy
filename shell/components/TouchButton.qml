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
        radius: 12
        color: control.down ? Qt.alpha(control.accentColor, 0.28) : control.destructive ? Qt.alpha(Theme.dangerSurface, 0.53) : control.selected ? Qt.alpha(control.accentColor, 0.18) : Qt.alpha(Theme.surface, 0.31)
        border.color: control.destructive ? Theme.danger : control.selected ? control.accentColor : Qt.alpha(Theme.selection, 0.31)
    }
    Accessible.name: text
}
