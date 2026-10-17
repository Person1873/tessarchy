import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Slider {
    id: control
    property color accentColor: "#a9e8d5"
    implicitHeight: 56
    Layout.minimumHeight: 56
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : 0.35
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 4
        radius: 2
        color: "#34465e"
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: control.accentColor
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 24
        implicitHeight: 24
        radius: 12
        color: control.pressed ? "#ffffff" : control.accentColor
        border.width: 3
        border.color: "#172b3b"
    }
}
