import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "InlineGlassPicker"
    when: windowShown
    visible: true
    width: 400; height: 600
    GlassCombo {
        id: picker
        width: 320
        model: ["Tone A", "Tone B"]
        currentIndex: 0
    }
    SignalSpy { id: changed; target: picker; signalName: "activated" }
    function test_selection_uses_inline_touch_targets() {
        const header = picker.children[0];
        verify(header.height >= 48);
        mouseClick(header);
        verify(picker.expanded);
        wait(50);
        let option = null;
        const options = picker.children[1].children;
        for (let i = 0; i < options.length; i++) if (options[i].text === "Tone B") option = options[i];
        verify(!!option);
        verify(option.height >= 48);
        mouseClick(option);
        compare(picker.currentIndex, 1);
        compare(changed.count, 1);
        verify(!picker.expanded);
    }
}
