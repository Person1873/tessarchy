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
    property bool destructive: false
    contentItem: Text {
        text: control.text
        color: control.enabled ? "#f0f5f5" : "#7a8589"
        font.pixelSize: 16
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 12
        color: control.down ? "#35636c" : control.destructive ? "#713c49" : "#26383f"
        border.color: control.destructive ? "#bf7383" : "#43575f"
    }
    Accessible.name: text
}
