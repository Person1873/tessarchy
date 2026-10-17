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

// Desktop keeps numbered workspaces one tap away; landscape tablets only once
// the status bar has room beside the clock, tray and battery indicators.
function showWorkspaces(mode, width) {
    return (mode === "desktop" || mode === "tablet") && width >= 900;
}

// Workspaces 1-5 always have a slot. Higher numbered workspaces extend the
// strip. Named workspaces have negative ids and are not numbered slots.
function workspaceSlots(ids) {
    let slots = 5;
    for (let i = 0; i < ids.length; i++) {
        if (Number.isInteger(ids[i]) && ids[i] > slots) slots = Math.min(8, ids[i]);
    }
    return slots;
}

// Connected devices can disconnect; only paired devices can connect.
function btAction(connected, paired) {
    if (connected) return "disconnect";
    return paired ? "connect" : "none";
}

// Invalid battery readings are unavailable rather than a fabricated zero.
function btBatteryLabel(available, level) {
    if (!available || typeof level !== "number" || !isFinite(level)) return "";
    return " · " + Math.round(Math.max(0, Math.min(1, level)) * 100) + "%";
}

// Prefer a playing media player, then the first registered player.
function preferredPlayerIndex(playing) {
    for (let i = 0; i < playing.length; i++) if (playing[i]) return i;
    return playing.length ? 0 : -1;
}

function mediaSummary(title, artist) {
    return (title || "Unknown track") + " — " + (artist || "Unknown artist");
}
