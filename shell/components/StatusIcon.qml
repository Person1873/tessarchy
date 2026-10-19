import QtQuick
import QtQuick.Layouts

Item {
    id: indicator
    required property string symbol
    required property string label
    // Negative means no backend/device; bind a real signal value here later.
    property real strength: -1
    property bool uniform: false
    Layout.preferredWidth: 18
    Layout.preferredHeight: 20
    Accessible.name: label + (strength < 0 ? " unavailable" : " connected")
    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: "../icons/" + indicator.symbol + ".svg"
        sourceSize.width: 18
        sourceSize.height: 18
        opacity: indicator.uniform || indicator.strength >= 0 ? 1 : 0.35
    }
    Rectangle {
        visible: indicator.strength < 0
        anchors.centerIn: parent
        width: 22
        height: 1.5
        radius: 1
        rotation: -45
        color: indicator.uniform ? "#d0f3e9" : "#879caa"
    }
}
