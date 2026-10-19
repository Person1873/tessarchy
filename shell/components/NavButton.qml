import QtQuick
import QtQuick.Layouts

TouchButton {
    id: control
    focusPolicy: Qt.TabFocus
    required property string symbol
    property bool showLabel: true
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.minimumHeight: 48
    implicitHeight: 48
    padding: 4
    background: Rectangle {
        radius: Theme.radius("button", 16, height)
        color: control.down ? Qt.alpha(control.accentColor, 0.3) : control.selected ? Qt.alpha(control.accentColor, 0.15) : "transparent"
    }
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: 2
            opacity: control.enabled ? 1 : 0.35
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                symbol: control.symbol
                size: 21
                color: control.selected ? control.accentColor : Theme.textSecondary
            }
            Text {
                visible: control.showLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: control.text
                color: control.selected ? control.accentColor : Theme.textSecondary
                font.pixelSize: 10
            }
        }
    }
}
