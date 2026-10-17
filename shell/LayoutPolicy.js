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

function nodeLabel(description, nickname, name) {
    for (const candidate of [description, nickname, name]) {
        if (candidate !== undefined && candidate !== null && String(candidate).trim() !== "") return String(candidate).trim();
    }
    return "Unknown device";
}

function streamLabel(appName, mediaName, nodeName) {
    for (const candidate of [appName, mediaName, nodeName]) {
        if (candidate !== undefined && candidate !== null && String(candidate).trim() !== "") return String(candidate).trim();
    }
    return "Unknown app";
}

function playbackStream(mediaClass) {
    if (mediaClass === undefined || mediaClass === null || String(mediaClass).trim() === "") return true;
    return String(mediaClass).indexOf("Output") >= 0;
}

function volumePercent(value) {
    return Math.round(Math.max(0, Math.min(1, Number(value) || 0)) * 100);
}
