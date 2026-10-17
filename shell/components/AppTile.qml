import QtQuick
import QtQuick.Layouts

TouchButton {
    id: control
    required property string symbol
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 132
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: 12
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56
                height: 56
                radius: 18
                color: control.symbol === "browser" ? "#4b668b" : "#2d6a64"
                Image {
                    anchors.centerIn: parent
                    source: "../icons/" + control.symbol + ".svg"
                    sourceSize.width: 28
                    sourceSize.height: 28
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: control.text
                color: "#f0f5ff"
                font.pixelSize: 16
            }
        }
    }
}
