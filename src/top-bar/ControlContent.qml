import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Each page shares the header and a bounded Tab cycle. Returning from a detail
// page restores the tile that opened it, rather than losing keyboard position.
FocusScope {
    id: controls
    required property var theme
    required property var settings
    required property var status
    property string page: "main"
    property string returnName: "wifiTile"
    property string passwordKey: ""
    property string passwordName: ""
    property string pendingPower: ""
    readonly property string pageTitle: ({main: "Quick settings", wifi: "Wi-Fi", bluetooth: "Bluetooth", output: "Sound", input: "Microphone", power: "Power", confirm: "Confirm"})[page] || "Quick settings"
    implicitHeight: content.implicitHeight
    signal dismissed()
    signal focusMoved(var item)

    function focusTargets() {
        const targets = [];
        function visit(item) {
            if (!item.visible || !item.enabled) return;
            if (item.activeFocusOnTab) targets.push(item);
            for (const child of item.children || []) visit(child);
        }
        for (const child of content.children) visit(child);
        return targets;
    }
    function focusNamed(name) {
        const targets = focusTargets();
        const item = targets.find(target => target.objectName === name) || targets[0];
        if (item) { item.forceActiveFocus(Qt.TabFocusReason); focusMoved(item); }
    }
    function cycleFocus(delta) {
        const targets = focusTargets();
        if (!targets.length) return;
        const current = targets.findIndex(item => item.activeFocus);
        const item = targets[(current + delta + targets.length) % targets.length];
        item.forceActiveFocus(Qt.TabFocusReason); focusMoved(item);
    }
    function showPage(name, origin) {
        if (page === "main") returnName = origin || returnName;
        passwordKey = "";
        status.errorMessage = ""; status.hardware.errorMessage = "";
        page = name;
        status.wifiScanning = name === "wifi";
        Qt.callLater(() => focusNamed(name === "confirm" ? "cancelPower" : name === "main" ? returnName : "pageAction"));
    }
    function back() {
        if (passwordKey) { passwordKey = ""; Qt.callLater(() => focusNamed("deviceList")); }
        else if (page === "confirm") showPage("power");
        else if (page !== "main") showPage("main");
        else dismissed();
    }
    function chooseWifi(row) {
        if (status.needsPassword(row)) {
            passwordKey = row.key; passwordName = row.title;
            Qt.callLater(() => focusNamed("wifiPassword"));
        } else status.useWifi(row.key);
    }
    function requestPower(action) {
        if (action === "lock") status.hardware.power(action, theme, settings.fontFamily);
        else { pendingPower = action; showPage("confirm"); }
    }
    // Escape is handled before text inputs so it always clears a password prompt.
    Keys.onEscapePressed: back()
    Keys.onTabPressed: event => cycleFocus((event.modifiers & Qt.ShiftModifier) ? -1 : 1)
    Keys.onBacktabPressed: cycleFocus(-1)
    Keys.onPressed: event => {
        if (page !== "main" || ![Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) return;
        const names = ["wifiTile", "bluetoothTile", "outputTile", "inputTile"];
        const focused = focusTargets().find(item => item.activeFocus);
        const index = focused ? names.indexOf(focused.objectName) : -1;
        if (index < 0) return;
        const delta = event.key === Qt.Key_Left ? -1 : event.key === Qt.Key_Right ? 1 : event.key === Qt.Key_Up ? -2 : 2;
        focusNamed(names[(index + delta + names.length) % names.length]);
        event.accepted = true;
    }
    Component.onCompleted: Qt.callLater(() => focusNamed("wifiTile"))
    Component.onDestruction: status.wifiScanning = false
    Connections { target: controls.status.hardware; function onLocked() { controls.dismissed(); } }

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            ActionButton {
                visible: controls.page !== "main"
                navigation: controls; theme: controls.theme; iconName: "back"; accessibleLabel: "Back"
                onClicked: controls.back()
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: controls.pageTitle; color: controls.theme.foreground; font { family: controls.settings.fontFamily; pixelSize: 16; weight: Font.Medium } }
                Text {
                    Layout.fillWidth: true
                    visible: controls.page === "main"
                    text: controls.status.hasBattery ? controls.status.batteryPercent + "% · " + controls.status.batteryDetail : "Your desktop, at a glance"
                    elide: Text.ElideRight
                    color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 11 }
                }
            }
            ActionButton { navigation: controls; theme: controls.theme; iconName: "close"; accessibleLabel: "Close quick settings"; onClicked: controls.dismissed() }
        }
        Loader {
            id: pageLoader
            Layout.fillWidth: true
            sourceComponent: controls.page === "main" ? mainPage : controls.page === "wifi" ? wifiPage
                : controls.page === "bluetooth" ? bluetoothPage : ["output", "input"].includes(controls.page) ? audioPage
                : controls.page === "confirm" ? confirmPage : powerPage
        }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: controls.status.errorMessage || controls.status.hardware.errorMessage
            wrapMode: Text.WordWrap; color: controls.theme.error
            font { family: controls.settings.fontFamily; pixelSize: 11 }
            Accessible.role: Accessible.AlertMessage
        }
    }

    Component {
        id: mainPage
        ColumnLayout {
            spacing: 14
            GridLayout {
                Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 8
                ControlTile {
                    objectName: "wifiTile"; Layout.fillWidth: true
                    navigation: controls; theme: controls.theme; settings: controls.settings; title: "Wi-Fi"; iconName: controls.status.wifiEnabled ? "wifi" : "wifi-off"
                    subtitle: !controls.status.wifiAvailable ? "Unavailable" : !controls.status.wifiHardwareEnabled ? "Hardware blocked" : controls.status.wifiEnabled ? controls.status.networkName : "Off"
                    activated: controls.status.wifiEnabled; enabled: controls.status.wifiAvailable
                    toggleEnabled: controls.status.wifiHardwareEnabled
                    onClicked: controls.showPage("wifi", objectName)
                    onToggleRequested: controls.status.toggleWifi()
                }
                ControlTile {
                    objectName: "bluetoothTile"; Layout.fillWidth: true
                    navigation: controls; theme: controls.theme; settings: controls.settings; title: "Bluetooth"; iconName: "bluetooth"
                    subtitle: !controls.status.bluetoothAvailable ? "Unavailable" : controls.status.bluetoothEnabled ? "On" : "Off"
                    activated: controls.status.bluetoothEnabled; enabled: controls.status.bluetoothAvailable
                    onClicked: controls.showPage("bluetooth", objectName)
                    onToggleRequested: controls.status.toggleBluetooth()
                }
                ControlTile {
                    objectName: "outputTile"; Layout.fillWidth: true
                    navigation: controls; theme: controls.theme; settings: controls.settings; title: "Sound"; iconName: controls.status.audioIcon
                    subtitle: !controls.status.audioAvailable ? "No output device" : controls.status.muted ? "Muted" : "On"
                    activated: !controls.status.muted; enabled: controls.status.audioAvailable
                    onClicked: controls.showPage("output", objectName)
                    onToggleRequested: controls.status.toggleMute()
                }
                ControlTile {
                    objectName: "inputTile"; Layout.fillWidth: true
                    navigation: controls; theme: controls.theme; settings: controls.settings; title: "Microphone"; iconName: "microphone"
                    subtitle: !controls.status.microphoneAvailable ? "No input device" : controls.status.microphoneMuted ? "Muted" : "On"
                    activated: !controls.status.microphoneMuted; enabled: controls.status.microphoneAvailable
                    onClicked: controls.showPage("input", objectName)
                    onToggleRequested: controls.status.toggleMicrophone()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                ActionButton { navigation: controls; theme: controls.theme; enabled: controls.status.audioAvailable; iconName: controls.status.audioIcon; accessibleLabel: controls.status.muted ? "Unmute output" : "Mute output"; onClicked: controls.status.toggleMute() }
                ControlSlider { objectName: "outputVolume"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; enabled: controls.status.audioAvailable; value: controls.status.volume; Accessible.name: "Output volume"; onMoved: controls.status.setVolume(value) }
                Text { text: Math.round(controls.status.volume * 100) + "%"; color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 10 } }
            }
            RowLayout {
                Layout.fillWidth: true
                Icon { name: "brightness"; tint: controls.theme.muted; Layout.preferredWidth: 28; Layout.preferredHeight: 16 }
                ControlSlider { objectName: "brightness"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; enabled: controls.status.hardware.brightnessAvailable; from: 0.01; value: controls.status.hardware.brightness; Accessible.name: "Screen brightness"; onMoved: controls.status.hardware.setBrightness(value) }
                Text { text: controls.status.hardware.brightnessAvailable ? Math.round(controls.status.hardware.brightness * 100) + "%" : "N/A"; color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 10 } }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: controls.theme.border; opacity: 0.4 }
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: controls.status.networkName; elide: Text.ElideRight; color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 11 } }
                ActionButton { objectName: "lockButton"; navigation: controls; theme: controls.theme; iconName: "lock"; accessibleLabel: "Lock screen"; enabled: !controls.status.hardware.powerBusy; onClicked: controls.requestPower("lock") }
                ActionButton { objectName: "powerButton"; navigation: controls; theme: controls.theme; iconName: "power"; accessibleLabel: "Power options"; onClicked: controls.showPage("power", objectName) }
            }
        }
    }

    Component {
        id: wifiPage
        ColumnLayout {
            spacing: 10
            ControlRow {
                objectName: "pageAction"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings
                title: "Wi-Fi"; detail: controls.status.wifiHardwareEnabled ? controls.status.wifiEnabled ? "On" : "Off" : "Hardware blocked"
                iconName: "wifi"; selected: controls.status.wifiEnabled
                enabled: controls.status.wifiAvailable && controls.status.wifiHardwareEnabled
                onClicked: controls.status.toggleWifi()
            }
            DeviceList {
                objectName: "deviceList"; Layout.fillWidth: true
                visible: controls.status.wifiEnabled && !controls.passwordKey
                navigation: controls; theme: controls.theme; settings: controls.settings; items: controls.status.wifiRows
                onActivated: row => controls.chooseWifi(row)
            }
            Text {
                Layout.fillWidth: true
                visible: !controls.passwordKey && (!controls.status.wifiEnabled || controls.status.wifiRows.length === 0)
                text: controls.status.wifiEnabled ? "Scanning for nearby networks…" : "Turn on Wi-Fi to see nearby networks."
                wrapMode: Text.WordWrap; color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 11 }
            }
            // The prompt is destroyed on exit. Passphrases go straight to the
            // native API, never to a command line, log, or Luna settings file.
            Loader {
                Layout.fillWidth: true
                active: controls.passwordKey !== ""
                sourceComponent: ColumnLayout {
                    spacing: 10
                    Text { Layout.fillWidth: true; text: controls.passwordName; wrapMode: Text.WordWrap; color: controls.theme.foreground; font { family: controls.settings.fontFamily; pixelSize: 12 } }
                    TextField {
                        id: passphrase
                        Keys.forwardTo: [controls]
                        objectName: "wifiPassword"; Layout.fillWidth: true
                        echoMode: TextInput.Password; placeholderText: "Password"
                        color: controls.theme.foreground; placeholderTextColor: controls.theme.muted
                        font { family: controls.settings.fontFamily; pixelSize: 12 }
                        Accessible.name: "Wi-Fi password"
                        background: Rectangle { color: controls.theme.surface; radius: 4; border { width: passphrase.activeFocus ? 1 : 0; color: controls.theme.accent } }
                        function submit() {
                            if (!text.length) return;
                            controls.status.useWifi(controls.passwordKey, text);
                            clear(); controls.passwordKey = "";
                            Qt.callLater(() => controls.focusNamed("deviceList"));
                        }
                        onAccepted: submit()
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ControlRow { Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Cancel"; iconName: "back"; onClicked: controls.back() }
                        ControlRow { Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Connect"; iconName: "wifi"; enabled: passphrase.text.length > 0; onClicked: passphrase.submit() }
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothPage
        ColumnLayout {
            spacing: 10
            ControlRow { objectName: "pageAction"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Bluetooth"; detail: controls.status.bluetoothEnabled ? "On" : "Off"; iconName: "bluetooth"; selected: controls.status.bluetoothEnabled; enabled: controls.status.bluetoothAvailable; onClicked: controls.status.toggleBluetooth() }
            DeviceList { objectName: "deviceList"; Layout.fillWidth: true; visible: controls.status.bluetoothEnabled; navigation: controls; theme: controls.theme; settings: controls.settings; items: controls.status.bluetoothRows; onActivated: row => controls.status.useBluetooth(row.key) }
            Text { Layout.fillWidth: true; visible: !controls.status.bluetoothEnabled || controls.status.bluetoothRows.length === 0; text: controls.status.bluetoothEnabled ? "No paired devices." : "Turn on Bluetooth to see paired devices."; color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 11 } }
        }
    }
    Component {
        id: audioPage
        ColumnLayout {
            readonly property bool output: controls.page === "output"
            spacing: 10
            ControlRow { objectName: "pageAction"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: parent.output ? "Output sound" : "Microphone"; detail: (parent.output ? controls.status.muted : controls.status.microphoneMuted) ? "Muted" : "On"; selected: !(parent.output ? controls.status.muted : controls.status.microphoneMuted); iconName: parent.output ? controls.status.audioIcon : "microphone"; onClicked: { if (parent.output) controls.status.toggleMute(); else controls.status.toggleMicrophone(); } }
            ControlSlider {
                Layout.fillWidth: true; navigation: controls; theme: controls.theme
                value: parent.output ? controls.status.volume : controls.status.microphoneAvailable ? controls.status.source.audio.volume : 0
                enabled: parent.output ? controls.status.audioAvailable : controls.status.microphoneAvailable
                Accessible.name: parent.output ? "Output volume" : "Microphone volume"
                onMoved: { if (parent.output) controls.status.setVolume(value); else controls.status.setMicrophoneVolume(value); }
            }
            DeviceList { objectName: "deviceList"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; items: parent.output ? controls.status.outputRows : controls.status.inputRows; onActivated: row => controls.status.selectAudio(row.key, parent.output) }
            Text { visible: (parent.output ? controls.status.outputRows : controls.status.inputRows).length === 0; text: "No audio devices available."; color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 11 } }
        }
    }
    Component {
        id: powerPage
        ColumnLayout {
            spacing: 8
            Text { Layout.fillWidth: true; visible: controls.status.hasBattery; text: controls.status.batteryPercent + "% battery · " + controls.status.batteryDetail; wrapMode: Text.WordWrap; color: controls.theme.muted; font { family: controls.settings.fontFamily; pixelSize: 11 } }
            ControlRow { objectName: "pageAction"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Lock screen"; iconName: "lock"; enabled: !controls.status.hardware.powerBusy; onClicked: controls.requestPower("lock") }
            ControlRow { Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Suspend"; iconName: "suspend"; enabled: controls.status.hardware.canSuspend && !controls.status.hardware.powerBusy; onClicked: controls.requestPower("suspend") }
            ControlRow { Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Restart"; iconName: "restart"; enabled: controls.status.hardware.canReboot && !controls.status.hardware.powerBusy; onClicked: controls.requestPower("reboot") }
            ControlRow { Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Shut down"; iconName: "power"; enabled: controls.status.hardware.canPowerOff && !controls.status.hardware.powerBusy; onClicked: controls.requestPower("poweroff") }
        }
    }
    Component {
        id: confirmPage
        ColumnLayout {
            spacing: 12
            Text { Layout.fillWidth: true; text: controls.pendingPower === "suspend" ? "Suspend this computer?" : controls.pendingPower === "reboot" ? "Restart this computer?" : "Shut down this computer?"; wrapMode: Text.WordWrap; color: controls.theme.foreground; font { family: controls.settings.fontFamily; pixelSize: 12 } }
            RowLayout {
                Layout.fillWidth: true
                ControlRow { objectName: "cancelPower"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Cancel"; iconName: "back"; onClicked: controls.back() }
                ControlRow { objectName: "confirmPower"; Layout.fillWidth: true; navigation: controls; theme: controls.theme; settings: controls.settings; title: "Confirm"; iconName: "power"; enabled: !controls.status.hardware.powerBusy; onClicked: controls.status.hardware.power(controls.pendingPower, controls.theme, controls.settings.fontFamily) }
            }
        }
    }
}
