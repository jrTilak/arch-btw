import QtQuick
import QtQuick.Controls

// The list is one Tab stop. Arrow keys select a row; activation resolves the
// live device through its key. Keeping keys preserves selection across refreshes.
ListView {
    id: list
    property var navigation: null
    Keys.forwardTo: navigation ? [navigation] : []
    required property var theme
    required property var settings
    property var items: []
    property string selectedKey: ""
    signal activated(var row)
    implicitHeight: Math.min(280, Math.max(54, contentHeight))
    clip: true
    spacing: 5
    model: items
    activeFocusOnTab: true
    boundsBehavior: Flickable.StopAtBounds
    Accessible.role: Accessible.List
    Accessible.name: "Devices"
    Accessible.description: currentIndex >= 0 && currentIndex < items.length ? items[currentIndex].title + ", " + items[currentIndex].detail : "No devices"
    function choose(index) {
        currentIndex = Math.max(0, Math.min(count - 1, index));
        if (currentIndex >= 0 && currentIndex < items.length) selectedKey = items[currentIndex].key;
        positionViewAtIndex(currentIndex, ListView.Contain);
    }
    function activateCurrent() {
        const row = items[currentIndex];
        if (row && !row.busy) activated(row);
    }
    onModelChanged: {
        const previous = items.findIndex(row => row.key === selectedKey);
        choose(previous >= 0 ? previous : Math.min(currentIndex, items.length - 1));
    }
    Keys.onUpPressed: choose(currentIndex - 1)
    Keys.onDownPressed: choose(currentIndex + 1)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) choose(0);
        else if (event.key === Qt.Key_End) choose(count - 1);
        else if (event.key === Qt.Key_PageUp) choose(currentIndex - 5);
        else if (event.key === Qt.Key_PageDown) choose(currentIndex + 5);
        else return;
        event.accepted = true;
    }
    Keys.onReturnPressed: activateCurrent()
    Keys.onEnterPressed: activateCurrent()
    Keys.onSpacePressed: activateCurrent()
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; focusPolicy: Qt.NoFocus }
    delegate: ControlRow {
        required property var modelData
        required property int index
        width: ListView.view.width
        theme: list.theme; settings: list.settings
        title: modelData.title; detail: modelData.detail; iconName: modelData.icon
        selected: modelData.connected
        enabled: !modelData.busy
        focusPolicy: Qt.NoFocus
        background: Rectangle {
            radius: 4
            color: Qt.tint(list.theme.background, Qt.rgba(list.theme.foreground.r, list.theme.foreground.g, list.theme.foreground.b, parent.hovered ? 0.1 : 0.045))
            border { width: list.activeFocus && list.currentIndex === index ? 1 : 0; color: list.theme.accent }
            opacity: parent.enabled ? 1 : 0.5
        }
        onClicked: { list.choose(index); list.forceActiveFocus(Qt.MouseFocusReason); list.activateCurrent(); }
    }
}
