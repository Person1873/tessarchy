import QtQuick
import Quickshell
import "../../shell/components"

ShellRoot {
    PowerPanel { id: panel; width: 368 }
    Timer {
        interval: 1800; running: true
        onTriggered: {
            panel.backend.select("balanced");
            if (panel.backend.state.available || panel.backend.action !== "status") console.log("POWER_TEST_FAIL");
            else console.log("POWER_TEST_PASS");
            Qt.quit();
        }
    }
}
