import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Compact mark with a shallow background and a full-size touch target.
Button {
    id: control
    property color accentColor: "#a9e8d5"
    // True while the Start menu is open.
    property bool selected: false
    Layout.minimumHeight: 48
    Layout.minimumWidth: 48
    implicitHeight: 48
    implicitWidth: 48
    padding: 0
    focusPolicy: Qt.NoFocus
    contentItem: Item {
        Image {
            anchors.centerIn: parent
            source: "../artwork/tessarchy-mark.svg"
            sourceSize.width: 20
            sourceSize.height: 20
        }
    }
    background: Item {
        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: 32
            radius: 8
            color: Qt.alpha(control.accentColor, control.down ? 0.3 : control.selected ? 0.22 : 0.10)
            border.color: Qt.alpha(control.accentColor, control.selected ? 0.7 : 0.3)
        }
    }
    Accessible.name: "Start"
}
