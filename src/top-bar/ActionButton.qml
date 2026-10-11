import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A keyboard-accessible icon button used by the bar and control center.
Button {
    id: button
    property var navigation: null
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.forwardTo: navigation ? [navigation] : []
    required property var theme
    property string iconName: "controls"
    property string accessibleLabel: ""
    property bool selected: false
    implicitWidth: 28
    implicitHeight: 24
    Accessible.name: accessibleLabel

    background: Rectangle {
        radius: 3
        color: button.hovered ? Qt.rgba(button.theme.surface.r, button.theme.surface.g, button.theme.surface.b, 0.45) : "transparent"
        border.width: button.activeFocus ? 1 : 0
        border.color: button.theme.muted
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    contentItem: Icon {
        name: button.iconName
        tint: button.selected ? button.theme.workspaceActive : button.theme.foreground
        width: 14
        height: 14
    }
}
