import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "NotificationLiteralText"
    when: windowShown
    visible: true
    width: 400
    height: 300
    Component { id: factory; NotificationCard { width: 360 } }

    function matchingText(item, value) {
        let result = item.text === value ? [item] : [];
        const children = item.children || [];
        for (let i = 0; i < children.length; i++)
            result = result.concat(matchingText(children[i], value));
        return result;
    }
    function test_external_labels_do_not_render_hyperlinks() {
        const markup = '<a href="https://example.invalid/">Notification</a>';
        const card = createTemporaryObject(factory, this, {
            notification: {appName: markup, summary: markup, body: markup, urgency: 1}
        });
        verify(card !== null);
        wait(50);
        const labels = matchingText(card, markup);
        compare(labels.length, 3);
        for (const label of labels) {
            for (let x = 0; x < Math.min(label.width, 160); x += 4)
                for (let y = 0; y < Math.min(label.height, 32); y += 4)
                    compare(label.linkAt(x, y), "");
        }
    }
}
