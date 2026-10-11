import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// Workspace lookup and persistent/dynamic ordering adapted from Omarchy's
// Workspaces.qml at be7c7bf3785f11c9f2dc210824cdf912ec4af043.
// Copyright (c) David Heinemeier Hansson. See OMARCHY-LICENSE.
RowLayout {
    id: row
    required property var theme
    required property var settings
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var ids: {
        const result = settings.persistentWorkspaces.slice();
        const values = Hyprland.workspaces.values;
        for (let i = 0; i < values.length; i++) {
            const id = values[i].id;
            if (id > 0 && !result.includes(id)) result.push(id);
        }
        return [...new Set(result)].sort((left, right) => left - right);
    }
    spacing: 2

    function workspaceById(id) {
        const values = Hyprland.workspaces.values;
        for (let i = 0; i < values.length; i++) if (values[i].id === id) return values[i];
        return null;
    }

    function focusWorkspace(id) {
        // Quickshell reports which Hyprland dispatcher syntax is available.
        Hyprland.dispatch(Hyprland.usingLua
            ? 'hl.dsp.focus({ workspace = "' + id + '" })'
            : "workspace " + id);
    }

    Repeater {
        model: row.ids
        delegate: ActionButton {
            id: workspaceButton
            required property int modelData
            readonly property var workspace: row.workspaceById(modelData)
            readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
            theme: row.theme
            selected: row.monitor && row.monitor.activeWorkspace && row.monitor.activeWorkspace.id === modelData
            iconName: row.settings.workspaceIcons[String(modelData)] || ""
            accessibleLabel: "Workspace " + modelData
            opacity: selected ? 1 : (occupied ? 0.85 : 0.5)
            onClicked: row.focusWorkspace(modelData)
            contentItem: Item {
                implicitWidth: 16
                implicitHeight: 16
                Icon {
                    anchors.centerIn: parent
                    width: 14; height: 14
                    visible: workspaceButton.iconName.length > 0
                    name: workspaceButton.iconName
                    tint: workspaceButton.selected ? row.theme.workspaceActive : row.theme.workspaceInactive
                }
                Text {
                    anchors.centerIn: parent
                    visible: workspaceButton.iconName.length === 0
                    text: workspaceButton.modelData
                    color: workspaceButton.selected ? row.theme.workspaceActive : row.theme.foreground
                    font { family: row.settings.fontFamily; pixelSize: 11; weight: Font.Medium }
                }
                Rectangle {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: -4 }
                    visible: workspaceButton.selected
                    width: 12; height: 2; radius: 1
                    color: row.theme.workspaceActive
                }
            }
        }
    }
}
