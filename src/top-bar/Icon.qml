import QtQuick
import QtQuick.Effects
import Quickshell

// Bundled SVG icons avoid font glyph dependencies. Desktop icon theme names
// also work, so workspace icons can match the apps a user keeps there.
Item {
    id: icon
    property string name: "controls"
    property color tint: "white"
    readonly property var builtins: ["browser", "code", "terminal", "chat", "folder", "wifi", "wifi-off", "bluetooth", "volume", "muted", "battery", "plug", "chevron", "controls", "close", "microphone", "brightness", "power", "lock", "back", "check", "suspend", "restart"]
    implicitWidth: 20
    implicitHeight: 20
    Image {
        anchors.fill: parent
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        source: icon.builtins.includes(icon.name) ? Qt.resolvedUrl("icons/" + icon.name + ".svg") : Quickshell.iconPath(icon.name, true)
        // Qt's standard effects tint the bundled single-color vector assets.
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: icon.tint
        }
    }
}
