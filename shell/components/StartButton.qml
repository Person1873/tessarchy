import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Windows-XP-style Start button: a raised accent pill with the project mark and
// an italic label. Rendered as glass, so the fill is the session accent rather
// than XP's solid green.
Button {
    id: control
    property color accentColor: Theme.accent
    // True while the launcher page this button opens is on screen.
    property bool selected: false
    Layout.minimumHeight: 48
    Layout.minimumWidth: 132
    implicitHeight: 48
    implicitWidth: 132
    padding: 12
    focusPolicy: Qt.NoFocus
    contentItem: RowLayout {
        spacing: 8
        Image {
            source: "../artwork/tessarchy-mark.svg"
            sourceSize.width: 20
            sourceSize.height: 20
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: control.text
            color: Theme.startButtonText
            font.pixelSize: 17
            font.italic: true
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
    background: Rectangle {
        radius: 10
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(control.accentColor, 1.12) }
            GradientStop { position: 0.55; color: control.accentColor }
            GradientStop { position: 1.0; color: Qt.darker(control.accentColor, 1.12) }
        }
        border.width: 1
        border.color: control.selected ? Theme.startButtonSelectedBorder : Theme.startButtonBorder
        opacity: control.down ? 0.82 : 1.0
    }
    Accessible.name: "Start"
}
