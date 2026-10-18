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

function dockLayout(mode, width, keyboard) {
    const count = (mode === "phone" ? 5 : 6) + (keyboard && mode !== "desktop" ? 1 : 0);
    const dockWidth = Math.min(Math.max(0, width - 32), mode === "phone" ? 376 : 448);
    const padding = mode === "phone" ? 24 : 32;
    const capacity = Math.max(1, Math.floor((dockWidth - padding + 4) / 52));
    const columns = capacity >= count ? count : Math.min(3, capacity);
    return {width: dockWidth, columns: columns, rows: Math.ceil(count / columns)};
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

function nodeLabel(description, nickname, name) {
    for (const value of [description, nickname, name]) {
        if (value !== undefined && value !== null && String(value).trim()) return String(value).trim();
    }
    return "Unknown device";
}

function streamLabel(app, media, name) {
    const label = nodeLabel(app, media, name);
    return label === "Unknown device" ? "Unknown app" : label;
}

function playbackStream(mediaClass) {
    return mediaClass === "Stream/Output/Audio";
}

function volumePercent(value) {
    return Math.round(Math.max(0, Math.min(1, Number(value) || 0)) * 100);
}

function duration(seconds) {
    const total = Math.floor(Number(seconds) || 0);
    if (!isFinite(total) || total <= 0) return "";
    if (total < 60) return "less than a minute";
    let minutes = Math.round(total / 60);
    const hours = Math.floor(minutes / 60);
    minutes = minutes % 60;
    if (hours > 0) return hours + "h " + String(minutes).padStart(2, "0") + "m";
    return minutes + "m";
}

// Notification pop-ups dock below the status bar. Phone cards span the panel;
// larger screens right-align a bounded column.
function notificationPlacement(mode, width) {
    if (mode === "phone") return { fullWidth: true, maxWidth: Math.max(280, width - 16), topOffset: 56 };
    if (mode === "tablet") return { fullWidth: false, maxWidth: Math.min(360, width - 32), topOffset: 60 };
    return { fullWidth: false, maxWidth: Math.min(420, width - 32), topOffset: 60 };
}

// Seconds a pop-up stays on screen. Low urgency leaves sooner, normal after a
// comfortable read, and critical notifications stay until dismissed.
function notificationTimeout(urgency) {
    if (urgency === 2) return 0;
    if (urgency === 0) return 4;
    return 8;
}

// The on-screen keyboard is armed for the touch layouts only. Desktop is driven
// by a physical keyboard, and a panel there would cover the window it serves.
function oskArmed(mode) {
    return mode !== "desktop";
}
