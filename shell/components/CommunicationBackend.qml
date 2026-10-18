import QtQuick
import Quickshell.Io

QtObject {
    id: backend
    property var state: ({contacts: [], messages: [], history: [], sounds: {}, tones: [], cellular: {available: false, label: "Checking cellular service", calls: [], sims: [], modems: []}})
    property var esim: ({available: false, label: "Refresh to detect eSIM profiles", profiles: []})
    property var picker: ({entries: [], title: "Files", folder: "", parent: ""})
    property string selectedModem: ""
    property var payload: ({})
    property string action: "status"
    property var queued: null
    property string previewPath: ""
    property int previewDuration: 20
    property bool initialized: false
    property var seenMessages: []
    readonly property bool busy: (worker.running && action !== "status") || queued !== null
    readonly property var incomingCall: (state.cellular.calls || []).find(c => c.state === 3) || null
    signal completed(string action, bool success)
    signal incoming
    function request(name, values) {
        if (worker.running) {
            if (name === "status" || queued) return false;
            queued = {name: name, values: Object.assign({modem: selectedModem}, values || {})};
            return true;
        }
        action = name;
        payload = Object.assign({action: name, modem: selectedModem}, values || {});
        worker.running = true;
        return true;
    }
    function contactName(number) {
        const contact = state.contacts.find(c => canonicalNumber(c.number) === canonicalNumber(number));
        return contact ? contact.name : number || "Unknown caller";
    }
    function canonicalNumber(number) { return String(number || "").replace(/[\s()+.\-]/g, ""); }
    function tonePath(kind) {
        const id = state.sounds[kind] || (kind === "ringtone" ? "Starcast" : kind === "message" ? "Stage" : "MoonLight");
        const tone = state.tones.find(t => t.id === id);
        return tone ? tone.path : "";
    }
    function preview(path, duration) {
        previewPlayer.running = false;
        previewPath = path;
        previewDuration = duration || 20;
        if (path && state.playerAvailable) previewPlayer.running = true;
    }
    property Process worker: Process {
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../helpers/communications.py").toString().replace("file://", ""))]
        stdinEnabled: true
        onStarted: { write(JSON.stringify(backend.payload) + "\n"); backend.payload = {}; }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (result.esim) backend.esim = result.esim;
                    if (result.picker) backend.picker = result.picker;
                    if (result.contacts) {
                        const newMessage = backend.initialized && result.messages.some(m => m.incoming && backend.seenMessages.indexOf(m.id) < 0);
                        backend.seenMessages = result.messages.map(m => m.id);
                        if (JSON.stringify(backend.state) !== JSON.stringify(result)) backend.state = result;
                        if (result.cellular.available) backend.selectedModem = result.cellular.id;
                        backend.initialized = true;
                        if (newMessage) backend.preview(backend.tonePath("message"), 3);
                    } else if (result.error) backend.state = Object.assign({}, backend.state, {error: result.error});
                    backend.completed(backend.action, !result.error);
                } catch (error) {
                    backend.state = Object.assign({}, backend.state, {error: "Communications service returned an invalid response"});
                    backend.completed(backend.action, false);
                }
            }
        }
        stderr: StdioCollector {}
        onExited: Qt.callLater(() => {
            if (backend.queued) {
                const next = backend.queued;
                backend.queued = null;
                backend.request(next.name, next.values);
            }
        })
    }
    property Process previewPlayer: Process {
        command: ["ffplay", "-nodisp", "-autoexit", "-loglevel", "error", "-protocol_whitelist", "file,pipe", "-t", String(backend.previewDuration), backend.previewPath]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }
    property Process ringPlayer: Process {
        command: ["ffplay", "-nodisp", "-autoexit", "-loglevel", "error", "-protocol_whitelist", "file,pipe", "-loop", "0", backend.tonePath("ringtone")]
        running: !!backend.incomingCall && backend.state.playerAvailable && backend.tonePath("ringtone") !== ""
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }
    onIncomingCallChanged: { if (incomingCall) incoming(); }
    property Timer poller: Timer {
        interval: backend.incomingCall || (backend.state.cellular.calls || []).some(c => c.state !== 7) ? 1500 : backend.state.cellular.available ? 5000 : 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.request("status")
    }
}
