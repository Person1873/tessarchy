import QtQuick
import QtQuick.Layouts

TouchButton {
    id: control
    property string iconSource: ""
    required property string symbol
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 116
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 12
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56
                height: 56
                radius: Theme.radius("tile", 18, height)
                rotation: 0
                color: Qt.alpha(control.accentColor, control.selected ? 0.4 : 0.18)
                border.color: Qt.alpha(control.accentColor, 0.3)
                border.width: Theme.borderWidth(1)
                Icon {
                    anchors.centerIn: parent
                    rotation: 0
                    symbol: control.symbol
                    size: 28
                    color: Theme.text
                    // App icons keep their own colours; only glyphs are tinted.
                    source: control.iconSource || "../icons/" + control.symbol + ".svg"
                    layer.enabled: control.iconSource === ""
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: control.text
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Theme.text
                font.pixelSize: 16
            }
        }
    }
}
