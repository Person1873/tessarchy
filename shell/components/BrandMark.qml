pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: mark
    property bool reducedMotion: false
    property bool playOnStart: true
    property real assembly: 1
    readonly property bool animating: intro.running
    implicitWidth: 104
    implicitHeight: 104
    Accessible.name: "Tessarchy tessellated T logo"

    function replay() {
        if (reducedMotion) {
            assembly = 1;
            return;
        }
        intro.restart();
    }
    onReducedMotionChanged: {
        if (reducedMotion) {
            intro.stop();
            assembly = 1;
        }
    }
    Component.onCompleted: {
        if (playOnStart)
            replay();
    }
    NumberAnimation {
        id: intro
        target: mark
        property: "assembly"
        from: 0
        to: 1
        duration: 1600
        easing.type: Easing.OutCubic
    }
    Item {
        anchors.fill: parent
        rotation: (1 - mark.assembly) * -70
        transform: Rotation {
            origin.x: mark.width / 2
            origin.y: mark.height / 2
            axis {
                x: 0
                y: 1
                z: 0
            }
            angle: (1 - mark.assembly) * 180
        }
        scale: 0.8 + 0.2 * mark.assembly
        Repeater {
            model: 6
            delegate: Image {
                id: face
                required property int index
                readonly property real phase: Math.max(0, Math.min(1, mark.assembly * 1.5 - index * 0.1))
                readonly property var offsets: [[-65, -45], [65, -45], [75, 35], [-75, 35], [-40, 70], [40, 70]]
                width: mark.width
                height: mark.height
                x: offsets[index][0] * (1 - phase)
                y: offsets[index][1] * (1 - phase)
                opacity: phase
                rotation: (1 - phase) * (index % 2 === 0 ? -120 : 120)
                scale: 0.6 + 0.4 * phase
                source: "../artwork/mark-face-" + index + ".svg"
                sourceSize.width: 160
                sourceSize.height: 160
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: mark.replay()
    }
}
