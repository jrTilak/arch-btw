import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Labeled controls expose current service state rather than decorative
// switches. Missing services disable the action and explain their state.
Button {
    id: tile
    property var navigation: null
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.forwardTo: navigation ? [navigation] : []
    required property var theme
    required property var settings
    property string title: ""
    property string subtitle: ""
    property string iconName: "controls"
    property bool activated: false
    property bool toggleEnabled: true
    signal toggleRequested()
    implicitHeight: 66
    Accessible.name: title + ", " + subtitle

    background: Rectangle {
        radius: 4
        // Keep the accent on the icon; active tiles retain a quiet dark surface.
        color: Qt.tint(tile.theme.background, Qt.rgba(tile.theme.foreground.r,
            tile.theme.foreground.g, tile.theme.foreground.b, tile.hovered ? 0.12 : 0.06))
        border.width: tile.activeFocus ? 1 : 0
        border.color: tile.theme.accent
        opacity: tile.enabled ? 1 : 0.5
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    contentItem: ColumnLayout {
        spacing: 5
        RowLayout {
            spacing: 8
            Icon {
                name: tile.iconName
                tint: tile.activated ? tile.theme.accent : tile.theme.muted
                Layout.preferredWidth: 16; Layout.preferredHeight: 16
            }
            Text {
                Layout.fillWidth: true
                Layout.rightMargin: 26
                text: tile.title
                color: tile.theme.foreground
                font { family: tile.settings.fontFamily; pixelSize: 12; weight: Font.Medium }
            }
        }
        Text {
            Layout.fillWidth: true
            text: tile.subtitle
            elide: Text.ElideRight
            color: tile.theme.muted
            font { family: tile.settings.fontFamily; pixelSize: 10 }
        }
    }
    ActionButton {
        anchors { right: parent.right; top: parent.top; rightMargin: 7; topMargin: 7 }
        objectName: tile.objectName + "Toggle"
        width: 24; height: 22
        navigation: tile.navigation
        theme: tile.theme
        iconName: tile.activated ? "check" : "power"
        selected: tile.activated
        enabled: tile.toggleEnabled
        accessibleLabel: (tile.activated ? "Turn off " : "Turn on ") + tile.title
        onClicked: tile.toggleRequested()
    }
    leftPadding: 12; rightPadding: 12; topPadding: 10; bottomPadding: 10
}
