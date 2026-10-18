import QtQuick
import Quickshell.Io

QtObject {
    id: backend
    property bool active: true
    property var state: ({available: false, profiles: [], active: "", degraded: "", error: ""})
    property string action: "status"
    readonly property bool busy: worker.running
    function refresh() { if (!busy) { action = "status"; worker.running = true; } }
    function select(profile) {
        if (busy || !state.available || state.profiles.indexOf(profile) < 0) return;
        action = profile;
        worker.running = true;
    }
    property Process worker: Process {
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../helpers/power_profiles.py").toString().replace("file://", "")), backend.action]
        stdout: StdioCollector {
            onStreamFinished: {
                try { backend.state = JSON.parse(text); }
                catch (error) { backend.state = {available: false, profiles: [], active: "", error: "Power status unavailable"}; }
            }
        }
        stderr: StdioCollector {}
    }
    property Timer poller: Timer {
        interval: 10000
        running: backend.active
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.refresh()
    }
}
