import QtQuick
import QtQml.Models
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Native services report actual state and own permission decisions. Nothing is
// toggled at startup; changes happen only through explicit control interactions.
QtObject {
    id: status
    property string errorMessage: ""
    property bool wifiScanning: false
    property string failedWifiKey: ""
    property string pendingBluetoothKey: ""
    property bool bluetoothTargetConnected: false
    property HardwareControls hardware: HardwareControls {}
    readonly property var wifiDevices: Networking.devices.values.filter(device => device.type === DeviceType.Wifi)
    readonly property var wifiObjects: collectWifiObjects()
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool audioAvailable: sink !== null && sink.ready && sink.audio !== null
    readonly property real volume: audioAvailable ? sink.audio.volume : 0
    readonly property bool muted: audioAvailable && sink.audio.muted
    readonly property bool microphoneAvailable: source !== null && source.ready && source.audio !== null
    readonly property bool microphoneMuted: microphoneAvailable && source.audio.muted
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: adapter !== null
    readonly property bool bluetoothEnabled: adapter !== null && adapter.enabled
    readonly property bool networkAvailable: Networking.backend === NetworkBackendType.NetworkManager
    readonly property bool wifiAvailable: networkAvailable && Networking.devices.values.some(device => device.type === DeviceType.Wifi)
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property var connectedDevice: Networking.devices.values.find(device => device.connected) || null
    readonly property var connectedNetwork: connectedDevice ? connectedDevice.networks.values.find(network => network.connected) || null : null
    readonly property string networkName: connectedNetwork ? connectedNetwork.name
        : (connectedDevice ? (connectedDevice.type === DeviceType.Wired ? "Ethernet" : connectedDevice.name) : "Not connected")
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isPresent && battery.isLaptopBattery
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: !UPower.onBattery
    readonly property string audioIcon: muted || volume === 0 ? "muted" : "volume"
    readonly property string networkIcon: connectedDevice ? "wifi" : "wifi-off"

    // A tracker binds node properties without holding onto stale PipeWire nodes.
    property PwObjectTracker tracker: PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => !node.isStream && (node.type & PwNodeType.Audio) !== 0)
    }

    // List delegates receive primitive snapshots. Resolve live objects at action
    // time because a scan or hotplug can destroy a previously displayed device.
    readonly property var wifiRows: wifiObjects.filter(net => net.name !== "").map(net => ({
        key: net.device.name + "\n" + net.name, title: net.name, connected: net.connected,
        busy: net.stateChanging, known: net.known, security: net.security,
        detail: net.stateChanging ? ConnectionState.toString(net.state) + "…"
            : net.connected ? "Connected · select to disconnect" : Math.round(net.signalStrength * 100) + "% signal",
        icon: "wifi"
    })).sort((a, b) => Number(b.connected) - Number(a.connected) || a.title.localeCompare(b.title))
    readonly property var bluetoothRows: Bluetooth.devices.values.filter(device => device.paired).map(device => ({
        key: device.address, title: device.name, connected: device.connected,
        busy: device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting,
        detail: BluetoothDeviceState.toString(device.state) + (device.connected ? " · select to disconnect" : ""), icon: "bluetooth"
    })).sort((a, b) => a.title.localeCompare(b.title))
    readonly property var outputRows: audioRows(true)
    readonly property var inputRows: audioRows(false)
    readonly property string batteryDetail: {
        if (!hasBattery) return "No battery";
        if (batteryPercent >= 100 && charging) return "Fully charged";
        const seconds = charging ? battery.timeToFull : battery.timeToEmpty;
        if (seconds <= 0) return charging ? "Charging · estimating time" : "Estimating remaining time";
        const minutes = Math.ceil(seconds / 60);
        return (minutes >= 60 ? Math.floor(minutes / 60) + "h " : "") + (minutes % 60) + "m " + (charging ? "until full" : "remaining");
    }

    function audioRows(output) {
        return Pipewire.nodes.values.filter(node => !node.isStream && node.ready && node.audio && node.isSink === output)
            .map(node => ({ key: String(node.id), title: node.description || node.nickname || node.name,
                connected: (output ? sink : source) === node, busy: false,
                detail: (output ? sink : source) === node ? "Selected" : "Select device", icon: output ? "volume" : "microphone" }));
    }
    function collectWifiObjects() {
        const result = [];
        for (const device of wifiDevices) for (const net of device.networks.values) result.push(net);
        return result;
    }
    function wifiFor(key) { return wifiObjects.find(net => net.device.name + "\n" + net.name === key) || null; }
    function needsPassword(row) {
        return !row.connected && (!row.known || row.key === failedWifiKey) && [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae, WifiSecurityType.StaticWep].includes(row.security);
    }
    function useWifi(key, password) {
        const net = wifiFor(key);
        if (!net || net.stateChanging || !wifiEnabled) return;
        errorMessage = ""; failedWifiKey = "";
        if (net.connected) net.disconnect();
        else if (password !== undefined) net.connectWithPsk(password);
        else if (net.known || [WifiSecurityType.Open, WifiSecurityType.Owe].includes(net.security)) net.connect();
        else errorMessage = "This network needs enterprise settings. Configure it in NetworkManager first.";
    }
    function useBluetooth(key) {
        const device = Bluetooth.devices.values.find(item => item.address === key);
        if (!device || !device.paired || !bluetoothEnabled) return;
        errorMessage = "";
        pendingBluetoothKey = key;
        bluetoothTargetConnected = !device.connected;
        bluetoothTimeout.restart();
        if (device.connected) device.disconnect(); else device.connect();
    }
    // BlueZ does not expose an action-failed signal here. Confirm the requested
    // state, and report a timeout if the paired device never reaches it.
    property Connections bluetoothCompletion: Connections {
        target: status.pendingBluetoothKey ? Bluetooth.devices.values.find(device => device.address === status.pendingBluetoothKey) || null : null
        function onConnectedChanged() {
            if (target.connected === status.bluetoothTargetConnected) {
                bluetoothTimeout.stop(); status.pendingBluetoothKey = "";
            }
        }
    }
    property Timer bluetoothTimeout: Timer {
        interval: 20000
        onTriggered: {
            status.errorMessage = "Bluetooth action did not complete. Check that the device is powered on and in range.";
            status.pendingBluetoothKey = "";
        }
    }
    function selectAudio(key, output) {
        const node = Pipewire.nodes.values.find(item => String(item.id) === key && !item.isStream && item.ready && item.audio && item.isSink === output);
        if (!node) return;
        if (output) Pipewire.preferredDefaultAudioSink = node;
        else Pipewire.preferredDefaultAudioSource = node;
    }
    function setMicrophoneVolume(value) {
        if (microphoneAvailable) source.audio.volume = Math.max(0, Math.min(1, value));
    }

    // Scan only while the Wi-Fi page is visible and release the scanner on close.
    property Instantiator scanners: Instantiator {
        model: status.wifiDevices
        delegate: Binding {
            required property var modelData
            target: modelData; property: "scannerEnabled"
            value: status.wifiScanning && status.wifiEnabled
            restoreMode: Binding.RestoreBindingOrValue
        }
    }
    property Instantiator failures: Instantiator {
        model: status.wifiObjects
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) {
                status.failedWifiKey = modelData.device.name + "\n" + modelData.name;
                status.errorMessage = "Could not connect to " + modelData.name + ". Check the password and try again.";
            }
        }
    }

    function setVolume(value) {
        if (!audioAvailable) return;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }
    function toggleMute() { if (audioAvailable) sink.audio.muted = !sink.audio.muted; }
    function toggleMicrophone() { if (microphoneAvailable) source.audio.muted = !source.audio.muted; }
    function toggleWifi() { if (wifiAvailable && wifiHardwareEnabled) Networking.wifiEnabled = !Networking.wifiEnabled; }
    function toggleBluetooth() { if (adapter) adapter.enabled = !adapter.enabled; }
}
