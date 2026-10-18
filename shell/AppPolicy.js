.pragma library

// Show one installed primary application per role; ignore helpers and control daemons.
const roles = [
    ["firefox", "org.mozilla.firefox", "chromium", "google-chrome", "org.gnome.epiphany"],
    ["org.gnome.nautilus", "thunar", "org.kde.dolphin", "pcmanfm-qt", "pcmanfm"],
    ["org.gnome.texteditor", "org.xfce.mousepad", "mousepad", "org.kde.kate", "org.gnome.gedit"],
    ["org.gnome.papers", "org.gnome.evince", "org.kde.okular"],
    ["org.gnome.loupe", "org.xfce.ristretto", "ristretto", "org.kde.gwenview"],
    ["mpv", "vlc", "org.gnome.showtime", "org.gnome.totem"],
    ["org.gnome.calculator", "galculator", "org.kde.kcalc"],
    ["libreoffice-writer"], ["libreoffice-calc"], ["libreoffice-impress"],
    ["nm-connection-editor"], ["blueman-manager"],
    ["foot", "org.gnome.console", "org.kde.konsole", "alacritty", "kitty"]
];

function majorApplications(entries) {
    const available = {};
    for (const entry of entries) {
        if (!entry || entry.noDisplay || !entry.command || entry.command.length === 0) continue;
        const id = String(entry.id || "").toLowerCase().replace(/\.desktop$/, "");
        available[id] = entry;
    }
    const result = [];
    for (const alternatives of roles) {
        for (const id of alternatives) {
            if (available[id]) { result.push(available[id]); break; }
        }
    }
    return result;
}
