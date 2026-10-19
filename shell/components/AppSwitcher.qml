pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../SwitcherPolicy.js" as SwitcherPolicy
import Quickshell
import Quickshell.Wayland

// Phone app switcher: a horizontal stack of full-height app previews.
// Cards are bare screenshots on rounded glass — no borders, no title rows and
// no action buttons. Tap a card to bring that app forward, swipe up to close it
// (the card flies off the top), swipe sideways to move through the stack.
// Keyboard stepping stays available for hardware keyboards.
FocusScope {
    id: control
    property var windows: []
    property color accentColor: "#a9e8d5"
    property bool reducedMotion: false
    property bool fillApp: false
    property string emptyHint: "No open apps"
    property var pendingTarget: null
    property var selection: null
    property var activateTarget: target => target.activate()
    readonly property int currentIndex: cards.currentIndex
    /// Screen the apps are running on; keeps card previews at the real aspect
    /// so nothing is letterboxed inside a taller card.
    property var screenSize: Qt.size(400, 800)
    readonly property real aspect: screenSize.height > 0 ? screenSize.width / screenSize.height : 0.5
    /// Every card keeps the same footprint so the stack looks even.
    readonly property real cardWidth: Math.min(Math.max(180, width - 72), 320)
    readonly property real cardHeight: Math.min(height, cardWidth / Math.max(0.2, aspect))
    signal activated
    signal dismissed
    signal closeRequested(var target)

    function selectActive() {
        cards.currentIndex = Math.max(0, SwitcherPolicy.activeIndex(windows));
        selection = windows[cards.currentIndex] || null;
    }
    function step(direction) {
        cards.currentIndex = SwitcherPolicy.advance(windows.indexOf(selection), direction, windows.length);
        selection = windows[cards.currentIndex] || null;
    }
    function activateCurrent() {
        const window = selection && windows.indexOf(selection) >= 0 ? selection : windows[cards.currentIndex];
        if (window && window.wayland) {
            pendingTarget = window.wayland;
            activated();
            // Let the compositor release the switcher's keyboard grab first.
            activateTimer.restart();
        }
        else if (!cards.count) dismissed();
    }
    Timer {
        id: activateTimer
        interval: 100
        onTriggered: {
            const target = control.pendingTarget;
            control.pendingTarget = null;
            if (target) {
                control.activateTarget(target);
                if (control.fillApp) target.maximized = true;
            }
        }
    }
    Connections {
        target: control.pendingTarget
        function onClosed() { control.pendingTarget = null; }
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
            activateCurrent();
            event.accepted = true;
        }
    }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    Keys.onReturnPressed: activateCurrent()
    Keys.onEnterPressed: activateCurrent()
    Keys.onEscapePressed: dismissed()

    ListView {
        id: cards
        anchors.fill: parent
        // Keep the requested app stable while the sheet resizes underneath it.
        onWidthChanged: Qt.callLater(() => { if (control.selection && !moving) currentIndex = control.windows.indexOf(control.selection); })
        onMovementEnded: control.selection = control.windows[currentIndex] || null
        orientation: ListView.Horizontal
        model: control.windows
        spacing: 10
        clip: true
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - control.cardWidth) / 2
        preferredHighlightEnd: preferredHighlightBegin
        highlightMoveDuration: control.reducedMotion ? 0 : 180
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property var handle: modelData.wayland
            // Dismissal state lives on the delegate so the fly-off animation
            // outlives the model entry it belongs to.
            property bool closing: false
            readonly property real sourceAspect: (preview.sourceSize.height > 0)
                ? preview.sourceSize.width / preview.sourceSize.height : control.aspect
            readonly property real cardHeight: Math.min(cards.height,
                control.cardWidth / Math.max(0.2, sourceAspect))
            width: control.cardWidth
            height: cards.height
            scale: ListView.isCurrentItem ? 1 : 0.93
            opacity: closing ? 0 : ListView.isCurrentItem ? 1 : 0.7
            transformOrigin: Item.Center
            Behavior on scale { NumberAnimation { duration: control.reducedMotion ? 0 : 160 } }
            Behavior on opacity { NumberAnimation { duration: control.reducedMotion ? 0 : 160 } }
            Behavior on y {
                enabled: !dismissDrag.active
                NumberAnimation { duration: control.reducedMotion ? 0 : 220; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: screen
                width: control.cardWidth
                height: card.cardHeight
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 24
                clip: true
                color: "#0d1622"
                ScreencopyView {
                    id: preview
                    anchors.fill: parent
                    captureSource: control.visible && !card.closing ? card.handle : null
                    live: control.visible
                    paintCursor: false
                }
                // Unavailable previews fall back to the window title on the same
                // card, with no extra frame around it.
                Column {
                    visible: !preview.hasContent
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 12
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "../artwork/tessarchy-mark.svg"
                        width: 44
                        height: 44
                    }
                    Text {
                        width: parent.width
                        text: card.modelData.title || "Untitled window"
                        color: "#f2f8ff"
                        wrapMode: Text.WrapAnywhere
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 13
                    }
                }
            }

            // Mouse exits: a small close target in the card's top-right corner.
            // Swipe-up still works for touch.
            Rectangle {
                id: closeButton
                width: 26
                height: 26
                radius: 13
                z: 2
                anchors.top: screen.top
                anchors.right: screen.right
                anchors.topMargin: 8
                anchors.rightMargin: 8
                color: closeArea.pressed ? "#e6dfe9f6" : closeArea.containsMouse ? "#c2162334" : "#8c0d1622"
                border.width: 1
                border.color: closeArea.containsMouse ? "#9fd8ff" : "#4d6b86"
                Text {
                    anchors.centerIn: parent
                    text: "\u00d7"
                    color: closeArea.containsMouse ? "#0d1622" : "#eaf4ff"
                    font.pixelSize: 16
                    font.bold: true
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.name: "Close " + (card.modelData.title || "window")
                    Accessible.role: Accessible.Button
                    onClicked: {
                        if (card.closing) return;
                        card.closing = true;
                        card.y = -card.height;
                        control.closeRequested(card.handle);
                    }
                }
            }

            MouseArea {
                anchors.fill: screen
                // Taps pick the app; the vertical DragHandler below steals the
                // gesture when the finger travels up.
                onClicked: {
                    cards.currentIndex = card.index;
                    control.selection = card.modelData;
                    control.activateCurrent();
                }
                Accessible.name: "Switch to " + (card.modelData.title || "Untitled window")
                Accessible.role: Accessible.Button
            }

            DragHandler {
                id: dismissDrag
                target: null
                xAxis.enabled: false
                yAxis.minimum: 0
                dragThreshold: 8
                grabPermissions: PointerHandler.CanTakeOverFromAnything
                // Distance travelled upward; read on release to decide.
                property real travel: 0
                onActiveChanged: {
                    if (active) {
                        travel = 0;
                        return;
                    }
                    if (card.closing) return;
                    if (travel > 72) {
                        card.closing = true;
                        card.y = -card.height;
                        control.closeRequested(card.handle);
                    } else {
                        card.y = 0;
                    }
                }
                onActiveTranslationChanged: {
                    if (!active || card.closing) return;
                    travel = activeTranslation.y;
                    card.y = Math.max(0, travel);
                }
            }
        }
        Text {
            visible: cards.count === 0
            anchors.centerIn: parent
            width: parent.width - 48
            text: control.emptyHint
            color: "#dfeaf4"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
