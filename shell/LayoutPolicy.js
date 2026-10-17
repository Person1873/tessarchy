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
