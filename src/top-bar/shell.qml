import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Three independent groups: workspace icons, an exactly centered clock, and a
// single status button. One resident process owns the bars on all displays.
ShellRoot {
    id: shell
    property var controlScreen: null
    property bool controlOpen: false
    readonly property int barHeight: 32
    Theme { id: lunaTheme }
    Settings { id: barSettings }
    SystemStatus { id: systemStatus }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    function closeControls() { controlOpen = false; }
    function toggleControls(screen) {
        if (controlOpen && controlScreen === screen) closeControls();
        else { controlScreen = screen; controlOpen = true; }
    }

    IpcHandler {
        target: "bar"
        function toggleControls(): void {
            const focused = Hyprland.focusedMonitor;
            const screen = Quickshell.screens.find(item => focused && item.name === focused.name) || Quickshell.screens[0];
            if (screen) shell.toggleControls(screen);
        }
        function closeControls(): void { shell.closeControls(); }
        function isOpen(): bool { return shell.controlOpen; }
        function state(): string {
            return JSON.stringify({ controlOpen: shell.controlOpen, network: systemStatus.networkName,
                volume: systemStatus.audioAvailable ? systemStatus.volume : null, battery: systemStatus.hasBattery ? systemStatus.batteryPercent : null,
                background: String(lunaTheme.background), accent: String(lunaTheme.accent) });
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: shell.barHeight
            exclusiveZone: shell.barHeight
            color: lunaTheme.background
            WlrLayershell.namespace: "luna-top-bar"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            WorkspaceRow {
                id: workspaces
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                theme: lunaTheme
                settings: barSettings
                screen: bar.screen
            }

            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, barSettings.clockFormat)
                color: lunaTheme.foreground
                font { family: barSettings.fontFamily; pixelSize: 12; weight: Font.Medium }
                // On unusually narrow screens preserve controls over clock text.
                visible: parent.width > workspaces.width + statusButton.width + implicitWidth + 64
            }

            Button {
                id: statusButton
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                implicitHeight: 24
                implicitWidth: statusIcons.implicitWidth + 20
                Accessible.name: "Open quick settings"
                onClicked: shell.toggleControls(bar.screen)
                background: Rectangle {
                    radius: 3
                    color: shell.controlOpen && shell.controlScreen === bar.screen || statusButton.hovered
                        ? Qt.rgba(lunaTheme.surface.r, lunaTheme.surface.g, lunaTheme.surface.b, 0.45) : "transparent"
                    border { width: statusButton.visualFocus ? 1 : 0; color: lunaTheme.muted }
                    Behavior on color { ColorAnimation { duration: 140 } }
                }
                contentItem: RowLayout {
                    id: statusIcons
                    spacing: 9
                    Icon { name: systemStatus.networkIcon; tint: lunaTheme.foreground; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                    Icon { name: systemStatus.audioIcon; tint: lunaTheme.foreground; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                    Icon { visible: systemStatus.bluetoothEnabled; name: "bluetooth"; tint: lunaTheme.foreground; Layout.preferredWidth: 13; Layout.preferredHeight: 13 }
                    Icon {
                        name: systemStatus.hasBattery ? (systemStatus.charging ? "plug" : "battery") : "controls"
                        tint: systemStatus.hasBattery && systemStatus.batteryPercent < 15 ? lunaTheme.warning : lunaTheme.foreground
                        Layout.preferredWidth: 14; Layout.preferredHeight: 14
                    }
                    Icon { name: "chevron"; tint: lunaTheme.muted; Layout.preferredWidth: 9; Layout.preferredHeight: 9 }
                }
            }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: lunaTheme.border; opacity: 0.3 }
        }
    }

    // The popup is instantiated only while open. Removing its screen closes it
    // as well, avoiding a panel accidentally migrating to another monitor.
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (shell.controlOpen && !Quickshell.screens.includes(shell.controlScreen)) shell.closeControls();
        }
    }
    LazyLoader {
        active: shell.controlOpen
        component: ControlCenter {
            screen: shell.controlScreen
            theme: lunaTheme
            settings: barSettings
            status: systemStatus
            barHeight: shell.barHeight
            onDismissed: shell.closeControls()
        }
    }
}
