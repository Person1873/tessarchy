import QtQuick
import Quickshell.Io

// Current conditions for the status strip. The helper resolves the location and
// caches the last observation, so this stays quiet (and stale-tolerant) offline.
QtObject {
    id: backend
    property var state: ({ok: false, error: ""})
    readonly property bool available: state.ok === true
    property Process worker: Process {
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../helpers/weather.py").toString().replace("file://", ""))]
        stdout: StdioCollector {
            id: output
            onStreamFinished: {
                try { backend.state = JSON.parse(text); }
                catch (error) { backend.state = ({ok: false, error: "Weather is unavailable"}); }
            }
        }
        stderr: StdioCollector {}
        onRunningChanged: {
            if (!running && output.text.length === 0) backend.state = {ok: false, error: "Weather is unavailable"};
        }
    }
    property Timer poller: Timer {
        // Refresh every 15 minutes; the helper serves cache on failure.
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.refresh()
    }
    function refresh() {
        if (!worker.running) worker.running = true;
    }
}
