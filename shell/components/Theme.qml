pragma Singleton
import QtQuick

// The active system theme. shell.qml feeds it the colors.toml that
// tessarchy-theme stages (Omarchy's format); defaults are the Tessera palette
// so components still render before, or without, a staged theme.
QtObject {
    property string mode: "dark"
    property color background: "#101b30"
    property color darkBackground: "#0b1424"
    property color darkerBackground: "#040d1a"
    property color surface: "#1c2c43"
    property color selection: "#34465e"
    property color text: "#f0f5ff"
    property color textSecondary: "#d0dced"
    property color textMuted: "#8da7b9"
    property color muted: "#7a8589"
    property color accent: "#a9e8d5"
    property color danger: "#ef8a9b"
    readonly property color dangerSurface: Qt.tint(surface, Qt.alpha(danger, 0.35))

    function load(raw) {
        const lines = String(raw || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^\s*([A-Za-z0-9_]+)\s*=\s*["']?(#[0-9A-Fa-f]{6}|light|dark)/);
            if (!match)
                continue;
            const value = match[2];
            switch (match[1]) {
            case "mode": mode = value; break;
            case "background": background = value; break;
            case "dark_background": darkBackground = value; break;
            case "darker_background": darkerBackground = value; break;
            case "lighter_background": surface = value; break;
            case "selection": selection = value; break;
            case "foreground": text = value; break;
            case "light_foreground": textSecondary = value; break;
            case "dark_foreground": textMuted = value; break;
            case "muted": muted = value; break;
            case "accent": accent = value; break;
            case "red": danger = value; break;
            }
        }
    }
}
