import QtQuick
import Quickshell
import Quickshell.Wayland

// The layer surface owns keyboard focus; all page navigation lives in a normal
// FocusScope so the controls can also be tested without a compositor.
PanelWindow {
    id: panel
    required property var theme
    required property var settings
    required property var status
    property int barHeight: 32
    signal dismissed()
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "luna-control-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    MouseArea { anchors.fill: parent; onClicked: panel.dismissed() }
    Rectangle {
        anchors { right: parent.right; top: parent.top; rightMargin: 8; topMargin: panel.barHeight + 6 }
        width: Math.min(340, parent.width - 16)
        height: Math.min(controls.implicitHeight + 32, parent.height - panel.barHeight - 16)
        color: panel.theme.background
        border { color: Qt.rgba(panel.theme.border.r, panel.theme.border.g, panel.theme.border.b, 0.5); width: 1 }
        radius: 6
        MouseArea { anchors.fill: parent }
        Flickable {
            id: scroll
            anchors.fill: parent; anchors.margins: 16
            contentHeight: controls.implicitHeight; clip: true
            boundsBehavior: Flickable.StopAtBounds
            ControlContent {
                id: controls
                width: parent.width; height: implicitHeight
                theme: panel.theme; settings: panel.settings; status: panel.status
                onDismissed: panel.dismissed()
                onFocusMoved: item => {
                    // Keep the keyboard target in view on short displays.
                    const y = item.mapToItem(controls, 0, 0).y;
                    if (y < scroll.contentY) scroll.contentY = y;
                    else if (y + item.height > scroll.contentY + scroll.height)
                        scroll.contentY = Math.min(scroll.contentHeight - scroll.height, y + item.height - scroll.height);
                }
            }
        }
    }
}
