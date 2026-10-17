import Quickshell
import Quickshell.Services.Pipewire

Scope {
    id: audio
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: audio.sink ? [audio.sink] : []
    }
}
