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
        color: control.down ? Qt.rgba(0.24, 0.38, 0.78, 0.55)
                            : control.selected ? Qt.rgba(0.20, 0.33, 0.68, 0.55)
                                               : Qt.rgba(0.13, 0.22, 0.46, 0.42)
        border.width: 1
        border.color: Qt.rgba(0.56, 0.71, 1.0, 0.26)
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
            color: Qt.rgba(0.24, 0.40, 0.82, 0.55)
            border.width: 1
            border.color: Qt.rgba(0.62, 0.76, 1.0, 0.35)
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
            color: "#e8f0ff"
            font.pixelSize: 12
        }
    }
}
