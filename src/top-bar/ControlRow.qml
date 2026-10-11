import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A whole-row action has one focus target and announces both its name and state.
Button {
    id: row
    property var navigation: null
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.forwardTo: navigation ? [navigation] : []
    required property var theme
    required property var settings
    property string title: ""
    property string detail: ""
    property string iconName: "controls"
    property bool selected: false
    implicitHeight: detail ? 54 : 42
    leftPadding: 10; rightPadding: 10
    Accessible.name: title + (detail ? ", " + detail : "")
    background: Rectangle {
        radius: 4
        color: Qt.tint(row.theme.background, Qt.rgba(row.theme.foreground.r, row.theme.foreground.g, row.theme.foreground.b, row.hovered ? 0.1 : 0.045))
        border { width: row.activeFocus ? 1 : 0; color: row.theme.accent }
        opacity: row.enabled ? 1 : 0.5
    }
    contentItem: RowLayout {
        spacing: 10
        Icon { name: row.iconName; tint: row.selected ? row.theme.accent : row.theme.muted; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text { Layout.fillWidth: true; text: row.title; elide: Text.ElideRight; color: row.theme.foreground; font { family: row.settings.fontFamily; pixelSize: 12 } }
            Text { Layout.fillWidth: true; visible: row.detail !== ""; text: row.detail; elide: Text.ElideRight; color: row.theme.muted; font { family: row.settings.fontFamily; pixelSize: 10 } }
        }
        Icon { name: row.selected ? "check" : "chevron"; tint: row.theme.muted; Layout.preferredWidth: 12; Layout.preferredHeight: 12 }
    }
}
