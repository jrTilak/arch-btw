import QtQuick
import Quickshell
import Quickshell.Io

// Commands use argument arrays. Reads never alter state; writes occur only in
// response to a control. Coalesce brightness changes while a write is running.
QtObject {
    id: hardware
    property bool brightnessAvailable: false
    property real brightness: 0
    property string brightnessDevice: ""
    property int pendingBrightness: -1
    property string errorMessage: ""
    readonly property bool powerBusy: powerProcess.running || lockProcess.running || lockDirectory.running
    property bool canSuspend: false
    property bool canReboot: false
    property bool canPowerOff: false
    readonly property string configRoot: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property string cacheRoot: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/luna"
    property string lockText: ""
    signal locked()

    function refreshBrightness() {
        if (!brightnessRead.running && !brightnessWrite.running) brightnessRead.running = true;
    }
    function setBrightness(value) {
        if (!brightnessAvailable) return;
        pendingBrightness = Math.max(1, Math.min(100, Math.round(value * 100)));
        brightness = pendingBrightness / 100;
        brightnessDebounce.restart();
    }
    function writeBrightness() {
        if (pendingBrightness < 0 || brightnessWrite.running) return;
        brightnessWrite.command = ["brightnessctl", "--device", brightnessDevice, "set", pendingBrightness + "%"];
        pendingBrightness = -1;
        brightnessWrite.running = true;
    }
    function power(action, theme, fontFamily) {
        if (powerBusy) return;
        errorMessage = "";
        if (action === "lock") {
            // Existing Hyprlock configuration is used as-is. The fallback is
            // generated from Luna colors and contains no authentication secrets.
            if (existingLock.loaded) { lockProcess.command = ["hyprlock", "--grace", "0", "--config", existingLock.path]; lockProcess.running = true; return; }
            const rgb = color => "rgb(" + String(color).slice(1) + ")";
            lockText = "# Generated Luna fallback lock screen.\nbackground {\n monitor =\n color = " + rgb(theme.background) + "\n}\ninput-field {\n monitor =\n size = 280, 48\n rounding = 4\n outline_thickness = 1\n outer_color = " + rgb(theme.border) + "\n inner_color = " + rgb(theme.surface) + "\n font_color = " + rgb(theme.foreground) + "\n check_color = " + rgb(theme.accent) + "\n fail_color = " + rgb(theme.error) + "\n placeholder_text = Password\n position = 0, 0\n halign = center\n valign = center\n}\n";
            lockDirectory.running = true;
            return;
        }
        if (!({suspend: canSuspend, reboot: canReboot, poweroff: canPowerOff})[action]) return;
        powerProcess.command = ["systemctl", action];
        powerProcess.running = true;
    }

    property Process brightnessRead: Process {
        command: ["brightnessctl", "--class", "backlight", "--machine-readable"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\n")[0].split(",");
                const current = Number(parts[2]), maximum = Number(parts[4]);
                hardware.brightnessAvailable = parts[1] === "backlight" && maximum > 0 && Number.isFinite(current);
                if (hardware.brightnessAvailable && hardware.pendingBrightness < 0) {
                    hardware.brightnessDevice = parts[0]; hardware.brightness = current / maximum;
                }
            }
        }
        onExited: (code, exitStatus) => { if (code !== 0) hardware.brightnessAvailable = false; }
    }
    property Timer brightnessPoll: Timer { interval: 3000; repeat: true; running: true; onTriggered: hardware.refreshBrightness() }
    property Timer brightnessDebounce: Timer { interval: 80; onTriggered: hardware.writeBrightness() }
    property Process brightnessWrite: Process {
        onExited: (code, exitStatus) => {
            if (code !== 0) hardware.errorMessage = "Could not change brightness.";
            if (hardware.pendingBrightness >= 0) hardware.writeBrightness(); else hardware.refreshBrightness();
        }
    }

    // logind capability checks respect unsupported hardware and session policy.
    property Process suspendCheck: Process {
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanSuspend"]
        running: true
        stdout: StdioCollector { onStreamFinished: hardware.canSuspend = /"(yes|challenge)"/.test(text) }
    }
    property Process rebootCheck: Process {
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanReboot"]
        running: true
        stdout: StdioCollector { onStreamFinished: hardware.canReboot = /"(yes|challenge)"/.test(text) }
    }
    property Process powerOffCheck: Process {
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanPowerOff"]
        running: true
        stdout: StdioCollector { onStreamFinished: hardware.canPowerOff = /"(yes|challenge)"/.test(text) }
    }
    property Process powerProcess: Process {
        onExited: (code, exitStatus) => { if (code !== 0) hardware.errorMessage = "The power action could not be completed."; }
    }
    property FileView existingLock: FileView { path: hardware.configRoot + "/hypr/hyprlock.conf"; printErrors: false }
    property Process lockDirectory: Process {
        command: ["mkdir", "-p", "--", hardware.cacheRoot]
        onExited: (code, exitStatus) => {
            if (code !== 0) hardware.errorMessage = "Could not prepare the lock screen.";
            else generatedLock.setText(hardware.lockText);
        }
    }
    property FileView generatedLock: FileView {
        path: hardware.cacheRoot + "/hyprlock.conf"; printErrors: false
        onSaved: { lockProcess.command = ["hyprlock", "--grace", "0", "--config", path]; lockProcess.running = true; }
        onSaveFailed: hardware.errorMessage = "Could not prepare the lock screen."
    }
    property Process lockProcess: Process {
        onStarted: hardware.locked()
        onExited: (code, exitStatus) => { if (code !== 0) hardware.errorMessage = "Could not start the lock screen."; }
    }
}
