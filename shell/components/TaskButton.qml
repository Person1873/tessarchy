import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Windows-XP-style task button: wide, horizontally laid out, with a bevelled
// edge. XP presses the button that owns the focused window; here the bevel and
// a translucent accent fill carry that state over the glass bar.
Button {
    id: control
    property color accentColor: "#a9e8d5"
    property bool selected: false
    property string iconSource: ""
    Layout.minimumHeight: 48
    Layout.minimumWidth: 150
    Layout.maximumWidth: 240
    Layout.preferredWidth: 210
    implicitHeight: 48
    padding: 10
    focusPolicy: Qt.NoFocus
    contentItem: RowLayout {
        spacing: 8
        Image {
            visible: control.iconSource !== ""
            source: control.iconSource
            sourceSize.width: 18
            sourceSize.height: 18
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            Layout.fillWidth: true
            text: control.text
            color: control.enabled ? "#e9f4f0" : "#8fa0a6"
            font.pixelSize: 13
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }
    background: Rectangle {
        radius: 8
        color: control.selected ? Qt.alpha(control.accentColor, 0.26)
                                : control.down ? Qt.alpha(control.accentColor, 0.20)
                                               : Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        border.color: control.selected ? Qt.alpha(control.accentColor, 0.85) : Qt.alpha("#ffffff", 0.16)
        // Inner bevel: light on top for a raised look, dark when the window has
        // focus so the button reads as pressed.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 7
            color: "transparent"
            border.width: 1
            border.color: control.selected ? Qt.alpha("#000000", 0.30) : Qt.alpha("#ffffff", 0.12)
        }
    }
    Accessible.name: text
}
