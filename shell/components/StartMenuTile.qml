import QtQuick
import QtQuick.Layouts

// Compact Start-menu tile: a small blue-tinted glass chip with the app icon and
// its name. Deliberately smaller and quieter than the launcher's AppTile.
TouchButton {
    id: control
    property string iconSource: ""
    required property string symbol
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 84
    background: Rectangle {
        radius: 12
        color: control.down ? Theme.tilePressed : control.selected ? Theme.tileSelected : Theme.tileGlass
        border.width: 1
        border.color: Theme.tileBorder
    }
    contentItem: ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 7
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 40
            implicitHeight: 40
            radius: 11
            color: Theme.tileIconGlass
            border.width: 1
            border.color: Theme.tileIconBorder
            Image {
                anchors.centerIn: parent
                source: control.iconSource || "../icons/" + control.symbol + ".svg"
                sourceSize.width: 22
                sourceSize.height: 22
            }
        }
        Text {
            Layout.fillWidth: true
            text: control.text
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            color: Theme.tileText
            font.pixelSize: 12
        }
    }
}
