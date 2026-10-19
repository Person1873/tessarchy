import QtQuick
import QtQuick.Layouts

RowLayout {
    id: chip
    property var conditions: ({})
    property int glyphSize: 20
    spacing: 6
    Image {
        Layout.alignment: Qt.AlignVCenter
        source: "../icons/" + (chip.conditions.icon || "weather-cloud") + ".svg"
        sourceSize.width: chip.glyphSize
        sourceSize.height: chip.glyphSize
    }
    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Math.round(chip.conditions.temperature || 0) + (chip.conditions.unit || "")
        color: "#e2edf1"
        font.pixelSize: 12
        Accessible.name: (chip.conditions.description || "Weather") + ", " + text
            + (chip.conditions.stale ? ", last observation" : "")
    }
}
