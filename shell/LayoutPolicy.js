.pragma library

function automaticMode(width, height) {
    if (Math.min(width, height) < 600) return "phone";
    if (width >= 1100 && height >= 650) return "desktop";
    return "tablet";
}

function effectiveMode(choice, width, height) {
    if (["phone", "tablet", "desktop"].indexOf(choice) >= 0) return choice;
    return automaticMode(width, height);
}

function title(mode) {
    return mode.charAt(0).toUpperCase() + mode.slice(1);
}

function columns(mode, width) {
    const preferred = mode === "desktop" ? 4 : mode === "tablet" ? 3 : 2;
    return Math.max(1, Math.min(preferred, Math.floor(width / 140)));
}

function panelWidth(mode, width) {
    return mode === "phone" ? width : Math.min(Math.max(0, width - 24), mode === "desktop" ? 760 : 720);
}

// Media: prefer the player that is actually playing; otherwise the first
// connected player; -1 when no player is connected.
function preferredPlayerIndex(playing) {
    for (let i = 0; i < playing.length; i++) {
        if (playing[i]) return i;
    }
    return playing.length > 0 ? 0 : -1;
}

function mediaSummary(title, artist) {
    const track = title && title.length > 0 ? title : "Unknown track";
    const by = artist && artist.length > 0 ? artist : "Unknown artist";
    return track + " — " + by;
}
