import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "DesktopTaskButton"
    when: windowShown
    visible: true
    width: 760
    height: 340
    Component { id: buttonFactory; TaskButton { width: 210; height: 48 } }
    SignalSpy { id: clicks; signalName: "clicked" }

    function descendant(item, propertyName) {
        for (const child of item.children) {
            if (child[propertyName] !== undefined) return child;
            const found = descendant(child, propertyName);
            if (found) return found;
        }
        return null;
    }
    function test_centred_content_data() {
        const rows = [];
        for (const size of [150, 210, 240]) {
            for (const state of ["ordinary", "selected", "disabled"]) {
                for (const icon of [false, true]) {
                    rows.push({tag: size + "-" + state + "-" + icon, size: size, state: state, icon: icon});
                }
            }
        }
        return rows;
    }
    function test_centred_content(data) {
        const button = createTemporaryObject(buttonFactory, this, {
            width: data.size, text: "Files", selected: data.state === "selected",
            enabled: data.state !== "disabled",
            iconSource: data.icon ? Qt.resolvedUrl("../../shell/icons/terminal.svg") : ""
        });
        verify(button);
        verify(waitForRendering(button));
        const label = descendant(button.contentItem, "textFormat");
        const icon = descendant(button.contentItem, "sourceSize");
        verify(label);
        verify(icon);
        const labelPosition = label.mapToItem(button, 0, 0);
        const left = data.icon ? icon.mapToItem(button, 0, 0).x : labelPosition.x;
        const right = labelPosition.x + Math.min(label.width, label.implicitWidth);
        fuzzyCompare(left, button.width - right, 1, "Icon/title group must have equal side margins");
        fuzzyCompare(labelPosition.y + label.height / 2, button.height / 2, 0.5);
        if (data.icon) {
            const position = icon.mapToItem(button, 0, 0);
            fuzzyCompare(position.y + icon.height / 2, button.height / 2, 0.5);
            fuzzyCompare(labelPosition.x - position.x - icon.width, 8, 0.5);
        }
        compare(button.focusPolicy, Qt.NoFocus);
        compare(button.Accessible.name, "Files");
    }
    function test_long_title_data() {
        return [{tag: "with-icon", icon: true}, {tag: "without-icon", icon: false}];
    }
    function test_long_title(data) {
        const button = createTemporaryObject(buttonFactory, this, {
            width: 150, text: "A very long application title that cannot fit inside a task button",
            iconSource: data.icon ? Qt.resolvedUrl("../../shell/icons/terminal.svg") : ""
        });
        verify(waitForRendering(button));
        const label = descendant(button.contentItem, "textFormat");
        tryCompare(label, "truncated", true);
        const position = label.mapToItem(button, 0, 0);
        verify(position.x >= button.leftPadding);
        verify(position.x + label.width <= button.width - button.rightPadding + 0.5);
        compare(label.elide, Text.ElideRight);
        compare(label.textFormat, Text.PlainText);
    }
    function test_activation_keeps_application_focus() {
        const button = createTemporaryObject(buttonFactory, this, {text: "Files"});
        clicks.target = button;
        clicks.clear();
        mouseClick(button, button.width / 2, button.height / 2);
        compare(clicks.count, 1);
        verify(!button.activeFocus);
        clicks.target = null;
    }
}
