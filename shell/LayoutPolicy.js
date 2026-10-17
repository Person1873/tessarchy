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

// What tapping a Bluetooth device row does: connected devices disconnect,
// already-paired devices connect, everything else needs pairing first.
function btAction(connected, paired) {
    if (connected) return "disconnect";
    if (paired) return "connect";
    return "none";
}

// Quickshell reports Bluetooth battery as 0.0..1.0, only when available.
function btBatteryLabel(available, level) {
    if (!available) return "";
    const value = Number(level);
    const percent = Math.round(Math.max(0, Math.min(1, isFinite(value) ? value : 0)) * 100);
    return " · " + percent + "%";
}
