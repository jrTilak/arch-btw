import QtQuick
import Quickshell
import Quickshell.Io

// User settings are independent of themes. Missing or invalid files keep the
// defaults; the bar never overwrites a user's workspace icon choices.
QtObject {
    id: settings
    property var workspaceIcons: ({ "1": "browser", "2": "code", "3": "terminal", "4": "chat", "5": "folder" })
    property var persistentWorkspaces: [1, 2, 3, 4, 5]
    property string fontFamily: "Noto Sans"
    property string clockFormat: "ddd, MMM d   ·   HH:mm"
    readonly property string configRoot: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"

    property FileView file: FileView {
        path: settings.configRoot + "/luna/top-bar.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const value = JSON.parse(text());
                if (!value || Array.isArray(value) || typeof value !== "object") throw new Error("Expected settings object");
                if (value.workspaceIcons !== undefined) {
                    if (!value.workspaceIcons || Array.isArray(value.workspaceIcons)
                        || typeof value.workspaceIcons !== "object") throw new Error("Invalid workspace icons");
                    for (const key of Object.keys(value.workspaceIcons)) {
                        if (!/^[1-9][0-9]*$/.test(key) || typeof value.workspaceIcons[key] !== "string") throw new Error("Invalid workspace icon");
                    }
                }
                if (value.persistentWorkspaces !== undefined && (!Array.isArray(value.persistentWorkspaces)
                    || !value.persistentWorkspaces.every(id => Number.isInteger(id) && id > 0))) throw new Error("Invalid workspace IDs");
                if (value.fontFamily !== undefined && typeof value.fontFamily !== "string") throw new Error("Invalid font");
                if (value.clockFormat !== undefined && typeof value.clockFormat !== "string") throw new Error("Invalid clock format");

                // Commit only after the complete settings object is valid.
                if (value.workspaceIcons !== undefined) settings.workspaceIcons = value.workspaceIcons;
                if (value.persistentWorkspaces !== undefined) settings.persistentWorkspaces = value.persistentWorkspaces;
                if (value.fontFamily !== undefined) settings.fontFamily = value.fontFamily;
                if (value.clockFormat !== undefined) settings.clockFormat = value.clockFormat;
            } catch (error) { console.warn("Luna bar: keeping previous settings:", error.message); }
        }
    }
}
