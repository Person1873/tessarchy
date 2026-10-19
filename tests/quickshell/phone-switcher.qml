import QtQuick
import Quickshell
import "../../shell/components"

ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 400
        implicitHeight: 680
        color: "#354350"
        Item {
            id: scene
            anchors.fill: parent
            RecentsBackdrop { anchors.fill: parent }
            AppSwitcher {
                id: switcher
                anchors.fill: parent
                phoneMode: true
                reducedMotion: true
                windows: [{title: "Terminal", activated: false, wayland: null},
                          {title: "Files", activated: true, wayland: null},
                          {title: "Browser", activated: false, wayland: null}]
            }
        }
    }
    function check(condition, message) {
        if (!condition) throw new Error(message);
        console.log("PHONE_SWITCHER_CHECK", message);
    }
    Timer {
        interval: 700
        running: true
        onTriggered: {
            try {
                switcher.activeWindow = switcher.windows[2];
                switcher.selectActive();
                check(switcher.currentIndex === 2, "explicit active app selection");
                switcher.activeWindow = null;
                switcher.selectActive();
                check(switcher.currentIndex === 1, "active app selection");
                const cards = Array.from(switcher.children).find(child => child.objectName === "appSwitcherCards");
                check(cards.objectName === "appSwitcherCards", "card view");
                check(cards.itemAtIndex(0).width < switcher.cardWidth, "overlapping cards");
                check(cards.itemAtIndex(1).z > cards.itemAtIndex(0).z, "selected card in front");
                for (const size of [[320, 480], [400, 680], [430, 800]]) {
                    window.implicitWidth = size[0];
                    window.implicitHeight = size[1];
                    check(switcher.cardHeight + 56 <= switcher.height, "header fits");
                    check(switcher.cardWidth < switcher.width, "adjacent cards visible");
                }
                const windows = switcher.windows;
                switcher.step(1);
                check(switcher.selection === windows[2], "step forward");
                switcher.windows = [windows[0], windows[2]];
                check(switcher.selection === windows[2], "retain app after removal");
                switcher.windows = [windows[0]];
                check(switcher.selection === windows[0], "replace vanished selection");
                switcher.windows = [];
                check(switcher.selection === null, "empty state");
                switcher.windows = windows;
                window.implicitWidth = 400;
                window.implicitHeight = 680;
                settled.start();
            } catch (error) {
                console.error("PHONE_SWITCHER_TEST_FAIL", error);
                Qt.exit(1);
            }
        }
    }
    Timer {
        id: settled
        interval: 100
        onTriggered: {
            if (switcher.currentIndex !== switcher.windows.indexOf(switcher.selection)) {
                console.error("PHONE_SWITCHER_TEST_FAIL selection changed after model update");
                Qt.exit(1);
                return;
            }
            console.log("PHONE_SWITCHER_TEST_PASS");
            if (Quickshell.env("TESSARCHY_SWITCHER_CAPTURE")) capture.start();
            else Qt.quit();
        }
    }
    Timer {
        id: capture
        interval: 500
        onTriggered: {
            scene.grabToImage(result => {
                result.saveToFile(Quickshell.env("TESSARCHY_SWITCHER_CAPTURE"));
                Qt.quit();
            });
        }
    }
}
