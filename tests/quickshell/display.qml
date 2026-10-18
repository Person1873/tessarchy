import QtQuick
import Quickshell
import "../../shell/components"

ShellRoot {
    BrightnessControl { id: brightness; width: 368 }
    NightLightToggle { id: night; width: 368; nightLight: true }
    property int phase: 0
    Timer {
        interval: 700; running: true; repeat: true
        onTriggered: {
            if (phase === 0) {
                if (!brightness.available || brightness.level !== 0.42 || !night.available || !night.active) {
                    console.log("DISPLAY_TEST_FAIL startup", brightness.available, brightness.level, night.available, night.active);
                    Qt.quit(); return;
                }
                brightness.setLevel(0.9);
                brightness.setLevel(0.6);
                night.nightLight = false;
                phase++;
            } else {
                if (brightness.level === 0.42 && brightness.error && !night.active)
                    console.log("DISPLAY_TEST_PASS");
                else console.log("DISPLAY_TEST_FAIL readback", brightness.level, brightness.error, night.active);
                Qt.quit();
            }
        }
    }
}
