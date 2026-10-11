import QtQuick
import Quickshell
import Quickshell.Io

// Read Luna's active palette and optional bar overrides. Keep the last valid
// palette while files are missing or being edited; never write theme files.
QtObject {
    id: theme
    property var base: ({
        background: "#1a1b26", surface: "#32344a", foreground: "#a9b1d6",
        muted: "#787c99", accent: "#7aa2f7", onAccent: "#1a1b26",
        border: "#444b6a", success: "#9ece6a", warning: "#e0af68", error: "#f7768e"
    })
    property var overrides: ({})
    readonly property color background: overrides.background || base.background
    readonly property color surface: overrides.surface || base.surface
    readonly property color foreground: overrides.foreground || base.foreground
    readonly property color muted: overrides.muted || base.muted
    readonly property color accent: overrides.accent || base.accent
    readonly property color onAccent: overrides.onAccent || base.onAccent
    readonly property color border: overrides.border || base.border
    readonly property color error: overrides.error || base.error
    readonly property color warning: overrides.warning || base.warning
    readonly property color workspaceActive: overrides.workspaceActive || accent
    readonly property color workspaceInactive: overrides.workspaceInactive || foreground

    function palette(text) {
        const value = JSON.parse(text);
        if (!value || Array.isArray(value) || typeof value !== "object") throw new Error("Expected colors");
        for (const key of Object.keys(value)) {
            if (typeof value[key] !== "string" || !/^#[0-9a-fA-F]{6}$/.test(value[key])) throw new Error("Invalid color");
        }
        return value;
    }

    property FileView baseFile: FileView {
        path: Quickshell.env("HOME") + "/.config/luna/theme/base.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const next = theme.palette(text());
                for (const key of Object.keys(theme.base)) if (!next[key]) throw new Error("Missing " + key);
                theme.base = next;
            } catch (error) { console.warn("Luna bar: keeping previous base palette:", error.message); }
        }
    }

    property FileView overrideFile: FileView {
        path: Quickshell.env("HOME") + "/.config/luna/theme/apps/top-bar.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { theme.overrides = theme.palette(text()); }
            catch (error) { console.warn("Luna bar: keeping previous overrides:", error.message); }
        }
        onLoadFailed: theme.overrides = ({})
    }

    // A theme activation replaces a directory symlink. Polling also catches that
    // swap when a file watcher remains attached to the preceding snapshot.
    property Timer refresh: Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: { baseFile.reload(); overrideFile.reload(); }
    }
}
