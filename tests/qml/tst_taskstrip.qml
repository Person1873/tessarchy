import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "DesktopTaskStrip"
    when: windowShown
    visible: true
    width: 800
    height: 100
    Component { id: stripFactory; TaskStrip { width: 400; height: 48 } }
    Component {
        id: windowFactory
        QtObject {
            property string title: "Window"
            property bool activated: false
            property QtObject wayland: QtObject {}
        }
    }
    SignalSpy { id: requests; signalName: "windowRequested" }
    function windows(count) {
        const result = [];
        for (let i = 0; i < count; i++) result.push(createTemporaryObject(windowFactory, this, {title: "Window " + i}));
        return result;
    }
    function test_many_windows_stay_inside_strip_and_follow_active_window() {
        const model = windows(8);
        model[7].activated = true;
        const strip = createTemporaryObject(stripFactory, this, {windows: model, activeWindow: model[model.length - 1]});
        const list = findChild(strip, "desktopTaskList");
        verify(strip.overflow);
        tryCompare(list, "count", 8);
        tryVerify(() => list.contentX > 0);
        verify(list.x >= 48);
        verify(list.x + list.width <= strip.width - 48);
        model[7].activated = false;
        model[0].activated = true;
        strip.activeWindow = model[0];
        tryCompare(list, "contentX", 0);
        requests.target = strip;
        requests.clear();
        mouseClick(list.itemAtIndex(0), 20, 20);
        compare(requests.count, 1);
        compare(requests.signalArguments[0][0], model[0]);
        requests.target = null;
    }
    function test_short_lists_use_available_space_and_closed_windows_disappear() {
        const model = windows(2);
        const strip = createTemporaryObject(stripFactory, this, {windows: model});
        const list = findChild(strip, "desktopTaskList");
        verify(!strip.overflow);
        tryCompare(list, "count", 2);
        compare(list.width, strip.width);
        strip.windows = [];
        tryCompare(list, "count", 0);
        verify(!strip.overflow);
    }
}
