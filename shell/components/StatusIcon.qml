import QtQuick
import QtQuick.Layouts
import "../StatusPolicy.js" as StatusPolicy

Item {
    id: indicator
    required property string symbol
    required property string label
    // Strength is normalized; negative or invalid data is unavailable.
    property real strength: -1
    property bool uniform: false
    signal clicked
    readonly property int level: StatusPolicy.signalLevel(strength)
    readonly property bool reported: level >= 0
    Layout.preferredWidth: uniform ? 28 : 18
    Layout.preferredHeight: 48
    Accessible.name: label + (reported ? " signal " + Math.round(strength * 100) + "%" : " unavailable")
    Accessible.role: Accessible.Button
    Image {
        anchors.centerIn: parent
        width: indicator.uniform ? 20 : 18
        height: width
        source: "../icons/" + indicator.symbol + "-level-" + Math.max(0, indicator.level) + ".svg"
        sourceSize.width: indicator.uniform ? 20 : 18
        sourceSize.height: indicator.uniform ? 20 : 18
        opacity: indicator.reported ? 1 : 0.35
    }
    Rectangle {
        visible: !indicator.reported
        anchors.centerIn: parent
        width: 22
        height: 1.5
        radius: 1
        rotation: -45
        color: indicator.uniform ? Theme.textSecondary : Theme.muted
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: indicator.clicked()
    }
}
