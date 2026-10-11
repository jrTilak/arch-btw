import QtQuick
import QtTest
import "../../src/top-bar" as Luna

// Exercise the actual UI with a fake backend: no test can change networking,
// brightness, audio, or session power state on the user's desktop.
TestCase {
    id: test
    name: "ControlCenterKeyboard"
    when: windowShown
    width: 340; height: 600
    visible: true
    QtObject {
        id: testTheme
        property color background: "#1a1b26"
        property color surface: "#32344a"
        property color foreground: "#a9b1d6"
        property color muted: "#787c99"
        property color accent: "#7aa2f7"
        property color border: "#444b6a"
        property color error: "#f7768e"
        property color workspaceActive: accent
    }
    QtObject { id: testSettings; property string fontFamily: "Noto Sans" }
    QtObject {
        id: testHardware
        property bool brightnessAvailable: true
        property real brightness: 0.5
        property string errorMessage: ""
        property bool powerBusy: false
        property bool canSuspend: true
        property bool canReboot: true
        property bool canPowerOff: true
        property int actions: 0
        signal locked()
        function setBrightness(value) { brightness = value; }
        function power(action, theme, family) { actions++; }
    }
    QtObject {
        id: testStatus
        property var hardware: testHardware
        property string errorMessage: ""
        property bool wifiScanning: false
        property bool hasBattery: true
        property int batteryPercent: 80
        property string batteryDetail: "2h remaining"
        property bool wifiAvailable: true
        property bool wifiHardwareEnabled: true
        property bool wifiEnabled: true
        property bool bluetoothAvailable: true
        property bool bluetoothEnabled: true
        property bool audioAvailable: true
        property bool microphoneAvailable: true
        property bool muted: false
        property bool microphoneMuted: false
        property real volume: 0.5
        property string audioIcon: "volume"
        property string networkName: "Test network"
        property var source: ({audio: {volume: 0.5}})
        property var wifiRows: [
            {key: "one", title: "First network", detail: "Connected", connected: true, busy: false, icon: "wifi"},
            {key: "two", title: "Private network", detail: "Available", connected: false, busy: false, icon: "wifi"}
        ]
        property var bluetoothRows: [{key: "bt", title: "Headphones", detail: "Disconnected", connected: false, busy: false, icon: "bluetooth"}]
        property var outputRows: [{key: "speaker", title: "Speakers", detail: "Selected", connected: true, busy: false, icon: "volume"}]
        property var inputRows: []
        property string lastDevice: ""
        property int mutations: 0
        function toggleWifi() { wifiEnabled = !wifiEnabled; mutations++; }
        function toggleBluetooth() { bluetoothEnabled = !bluetoothEnabled; mutations++; }
        function toggleMute() { muted = !muted; mutations++; }
        function toggleMicrophone() { microphoneMuted = !microphoneMuted; mutations++; }
        function setVolume(value) { volume = value; mutations++; }
        function setMicrophoneVolume(value) { mutations++; }
        function needsPassword(row) { return row.key === "two"; }
        function useWifi(key, password) { lastDevice = key; mutations++; }
        function useBluetooth(key) { lastDevice = key; mutations++; }
        function selectAudio(key, output) { lastDevice = key; mutations++; }
    }
    Luna.ControlContent {
        id: ui
        width: 308; height: implicitHeight
        theme: testTheme; settings: testSettings; status: testStatus
    }
    SignalSpy { id: closed; target: ui; signalName: "dismissed" }
    function target(name) { return findChild(ui, name); }
    function press(key, modifiers) { keyClick(key, modifiers || Qt.NoModifier); wait(5); }
    function init() {
        testStatus.wifiAvailable = true; testStatus.wifiEnabled = true;
        testStatus.mutations = 0; testHardware.actions = 0; testStatus.lastDevice = "";
        ui.showPage("main", "wifiTile"); wait(20); ui.focusNamed("wifiTile"); closed.clear();
    }
    function test_tab_cycle_and_reverse() {
        const targets = ui.focusTargets();
        verify(targets.length >= 10);
        ui.focusNamed(targets[0].objectName);
        for (let i = 1; i <= targets.length; i++) {
            press(Qt.Key_Tab);
            verify(targets[i % targets.length].activeFocus, "Tab stop " + i);
        }
        press(Qt.Key_Tab, Qt.ShiftModifier);
        verify(targets[targets.length - 1].activeFocus);
        compare(testStatus.mutations, 0);
    }
    function test_tiles_and_return_focus() {
        press(Qt.Key_Right); verify(target("bluetoothTile").activeFocus);
        press(Qt.Key_Down); verify(target("inputTile").activeFocus);
        press(Qt.Key_Return); compare(ui.page, "input");
        press(Qt.Key_Escape); compare(ui.page, "main"); verify(target("inputTile").activeFocus);
        press(Qt.Key_Escape); compare(closed.count, 1);
    }
    function test_slider_keyboard() {
        ui.focusNamed("outputVolume"); press(Qt.Key_Right);
        compare(testStatus.volume, 0.55);
        press(Qt.Key_End); compare(testStatus.volume, 1);
        press(Qt.Key_Home); compare(testStatus.volume, 0);
        ui.focusNamed("brightness"); press(Qt.Key_Left);
        verify(testHardware.brightness < 0.5);
    }
    function test_wifi_password_escape_and_scan_lifecycle() {
        press(Qt.Key_Return); compare(ui.page, "wifi"); verify(testStatus.wifiScanning);
        ui.focusNamed("deviceList"); press(Qt.Key_End); press(Qt.Key_Return);
        compare(ui.passwordKey, "two"); verify(target("wifiPassword").activeFocus);
        for (const letter of "secret") keyClick(letter); press(Qt.Key_Escape);
        compare(ui.passwordKey, ""); verify(target("wifiPassword") === null);
        compare(testStatus.mutations, 0);
        verify(target("deviceList").activeFocus);
        press(Qt.Key_Escape); verify(!testStatus.wifiScanning);
    }
    function test_device_selection_and_refresh() {
        ui.showPage("bluetooth"); wait(20); ui.focusNamed("deviceList");
        press(Qt.Key_Space); compare(testStatus.lastDevice, "bt");
        const list = target("deviceList");
        compare(list.selectedKey, "bt");
        testStatus.bluetoothRows = [{key: "new", title: "New", detail: "Off", connected: false, busy: false, icon: "bluetooth"}, {key: "bt", title: "Headphones", detail: "Connected", connected: true, busy: false, icon: "bluetooth"}];
        wait(20); compare(list.currentIndex, 1);
        press(Qt.Key_Home); press(Qt.Key_Return); compare(testStatus.lastDevice, "new");
    }
    function test_power_confirmation_defaults_to_cancel() {
        ui.showPage("power"); wait(20); ui.requestPower("reboot"); wait(20);
        verify(target("cancelPower").activeFocus);
        press(Qt.Key_Return); compare(ui.page, "power"); compare(testHardware.actions, 0);
        ui.requestPower("poweroff"); wait(20); press(Qt.Key_Escape);
        compare(ui.page, "power"); compare(testHardware.actions, 0);
    }
    function test_unavailable_service_skipped() {
        testStatus.wifiAvailable = false; wait(5);
        verify(!ui.focusTargets().some(item => item.objectName.indexOf("wifiTile") === 0));
    }
}
