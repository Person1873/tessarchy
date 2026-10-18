import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "QuickSwitcher"
    when: windowShown
    visible: true
    width: 400
    height: 120
    Component { id: factory; QuickSwitcher { width: 240; height: 96 } }
    Component {
        id: windowFactory
        QtObject {
            property string title: "Application"
            property bool activated: false
            property QtObject wayland: QtObject {}
        }
    }
    SignalSpy { id: requests; signalName: "windowRequested" }
    SignalSpy { id: dismissals; signalName: "dismissed" }

    function model() {
        return [createTemporaryObject(windowFactory, this, {title: "Terminal", activated: true}),
                createTemporaryObject(windowFactory, this, {title: "Files"}),
                createTemporaryObject(windowFactory, this, {title: "Browser"})];
    }
    function test_cycle_forward_backward_and_alt_release() {
        const windows = model();
        const switcher = createTemporaryObject(factory, this, {windows: windows});
        requests.target = switcher;
        requests.clear();
        switcher.selectActive();
        switcher.forceActiveFocus();
        keyClick(Qt.Key_Tab, Qt.AltModifier);
        compare(switcher.currentIndex, 1);
        keyClick(Qt.Key_Backtab, Qt.AltModifier | Qt.ShiftModifier);
        compare(switcher.currentIndex, 0);
        switcher.step(-1);
        compare(switcher.currentIndex, 2);
        requests.clear();
        keyRelease(Qt.Key_Alt);
        compare(requests.count, 1);
        compare(requests.signalArguments[0][0], windows[2]);
        requests.target = null;
    }
    function test_escape_and_selection_survives_model_changes() {
        const windows = model();
        const switcher = createTemporaryObject(factory, this, {windows: windows});
        dismissals.target = switcher;
        dismissals.clear();
        switcher.selectActive();
        switcher.step(1);
        switcher.windows = [windows[1], windows[2]];
        compare(switcher.selection, windows[1]);
        switcher.windows = [windows[2]];
        compare(switcher.selection, windows[2]);
        switcher.forceActiveFocus();
        keyClick(Qt.Key_Escape);
        compare(dismissals.count, 1);
        switcher.windows = [];
        compare(switcher.selection, null);
        switcher.activateCurrent();
        verify(dismissals.count >= 2);
        dismissals.target = null;
    }
}
