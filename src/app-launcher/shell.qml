import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A small resident app launcher. Quickshell discovers desktop entries through
// XDG directories; we never parse Exec strings or interpolate them into a shell.
ShellRoot {
    id: root
    property bool opened: false
    readonly property var applications: DesktopEntries.applications.values
    readonly property var results: {
        const query = search.text.trim().toLowerCase();
        return applications.filter(app => !app.noDisplay && app.name
            && (app.name + " " + app.genericName).toLowerCase().includes(query))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    function close() { opened = false; }
    function toggle() {
        opened = !opened;
        if (opened) {
            search.text = "";
            list.currentIndex = results.length > 0 ? 0 : -1;
            Qt.callLater(() => search.forceActiveFocus());
        }
    }

    // Clamp selection when filtering reduces the list. Empty searches/results
    // must never leave an index that launches an unrelated or undefined entry.
    onResultsChanged: list.currentIndex = results.length > 0 ? 0 : -1
    function moveSelection(delta) {
        if (results.length === 0) return;
        list.currentIndex = (list.currentIndex + delta + results.length) % results.length;
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    function launch(index) {
        if (index < 0 || index >= results.length) return;
        const app = results[index];
        close();

        // Native desktop-entry execution preserves the entry's working directory.
        // Terminal applications explicitly use our chosen terminal, Kitty.
        if (app.runInTerminal) {
            const args = ["kitty"];
            if (app.workingDirectory) args.push("--directory", app.workingDirectory);
            args.push("--");
            Quickshell.execDetached(args.concat(app.command));
        } else {
            app.execute();
        }
    }

    // The shortcut toggles this existing process over IPC instead of creating
    // another launcher on each press. Login starts it hidden for fast access.
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.opened; }
    }

    PanelWindow {
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "desktop-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Clicking outside closes the launcher; clicks inside belong to its UI.
        MouseArea { anchors.fill: parent; onClicked: root.close() }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(520, parent.width - 40)
            height: Math.min(content.implicitHeight + 32, parent.height - 40)
            color: "#171717"
            border.color: "#666666"
            border.width: 1
            radius: 0
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                TextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: "Search apps…"
                    color: "#ffffff"
                    background: Rectangle { color: "#252525"; border.color: "#666666"; radius: 0 }
                    onAccepted: root.launch(list.currentIndex)

                    // Keep focus in the query while navigating results.
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onEscapePressed: root.close()
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(root.results.length, 7) * 44
                    Layout.minimumHeight: 0
                    clip: true
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {}

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: list.width
                        height: 44
                        color: ListView.isCurrentItem ? "#343434" : "transparent"

                        Text {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                            text: modelData.name
                            textFormat: Text.PlainText
                            color: "#ffffff"
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = index
                            onClicked: root.launch(index)
                        }
                    }
                }

                Label { visible: root.results.length === 0; text: "No matching apps"; color: "#aaaaaa" }
                Label { text: "↑ ↓ select · Enter launch · Esc close"; color: "#aaaaaa"; font.pixelSize: 11 }
            }
        }
    }
}
