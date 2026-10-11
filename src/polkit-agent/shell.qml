import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland

// A session authentication agent, inspired by Omarchy's PolkitAgent.qml.
// Polkit and PAM own authorization; this UI only displays and answers the flow.
// Reference: https://github.com/omacom/omarchy/blob/quattro/shell/plugins/polkit/PolkitAgent.qml
ShellRoot {
    id: root

    readonly property var flow: agent.flow
    property bool submitted: false
    property bool rejected: false
    readonly property bool accepting: agent.isActive && flow !== null
        && flow.isResponseRequired && !submitted && !flow.isCompleted

    // Never retain an answer between prompts, identities, or authentication
    // requests. The field is cleared immediately after handing it to Polkit.
    function clearAnswer() {
        answer.text = ""
        submitted = false
    }

    function focusPrompt() {
        if (!agent.isActive) return;
        if (accepting) answer.forceActiveFocus();
        else card.forceActiveFocus();
    }

    // The default identity is chosen by Polkit, which need not be the first
    // entry. Keep the selector consistent when the native choice changes.
    function syncIdentity() {
        if (!flow) return;
        for (let i = 0; i < flow.identities.length; i++) {
            if (flow.identities[i] === flow.selectedIdentity) {
                identities.currentIndex = i;
                break;
            }
        }
    }

    function submit() {
        if (!accepting) return;
        submitted = true;
        rejected = false;
        flow.submit(answer.text);
        answer.text = "";
        card.forceActiveFocus();
    }

    function cancel() {
        clearAnswer();
        if (flow) flow.cancelAuthenticationRequest();
    }

    // Registration covers the current login session. Another agent may prevent
    // registration; report that failure rather than killing the competing agent.
    PolkitAgent {
        id: agent
        path: "/org/desktop/PolkitAgent"
        onAuthenticationRequestStarted: {
            root.clearAnswer();
            root.rejected = false;
            Qt.callLater(root.syncIdentity);
            Qt.callLater(root.focusPrompt);
        }
        onIsRegisteredChanged: {
            if (isRegistered) console.log("Polkit agent registered");
            else console.warn("Polkit agent is not registered; check for another session agent");
        }
        onIsActiveChanged: {
            root.clearAnswer();
            root.rejected = false;
            Qt.callLater(root.focusPrompt);
        }
        onFlowChanged: {
            root.clearAnswer();
            Qt.callLater(root.syncIdentity);
        }
    }

    // Prompts can change during one request (retry, multiple PAM questions, or
    // fingerprint/password fallback). Reflect the native flow rather than
    // implementing authentication or assuming every prompt asks for a password.
    Connections {
        target: root.flow
        function onIsResponseRequiredChanged() {
            root.clearAnswer();
            Qt.callLater(root.focusPrompt);
        }
        function onInputPromptChanged() {
            root.clearAnswer();
            Qt.callLater(root.focusPrompt);
        }
        function onSelectedIdentityChanged() {
            root.clearAnswer();
            root.rejected = false;
            Qt.callLater(root.syncIdentity);
            Qt.callLater(root.focusPrompt);
        }
        function onAuthenticationFailed() {
            root.clearAnswer();
            root.rejected = true;
            Qt.callLater(root.focusPrompt);
        }
        function onAuthenticationSucceeded() { root.clearAnswer(); }
        function onAuthenticationRequestCancelled() { root.clearAnswer(); }
        function onIsCompletedChanged() { if (root.flow.isCompleted) root.clearAnswer(); }
    }

    // A layer-shell overlay receives keyboard input above regular windows.
    // It exists only while a real request is active; Escape cancels the request.
    PanelWindow {
        visible: agent.isActive
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "desktop-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle { anchors.fill: parent; color: "#99000000" }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(460, parent.width - 40)
            height: content.implicitHeight + 40
            color: "#171717"
            border.color: root.rejected ? "#e08080" : "#777777"
            border.width: 1
            radius: 0
            focus: true

            Keys.onEscapePressed: root.cancel()

            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                spacing: 14

                Label { text: "Authentication required"; color: "#ffffff"; font.pixelSize: 19 }
                Label {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.message : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: "#cccccc"
                }

                // If policy offers several administrator identities, let the
                // user select one. Changing it restarts the native conversation.
                ComboBox {
                    id: identities
                    Layout.fillWidth: true
                    visible: count > 1
                    enabled: !root.submitted
                    model: root.flow ? root.flow.identities : []
                    textRole: "displayName"
                    onActivated: {
                        root.clearAnswer();
                        root.flow.selectedIdentity = root.flow.identities[currentIndex];
                    }
                }

                Label {
                    visible: text.length > 0
                    Layout.fillWidth: true
                    text: root.flow && root.flow.selectedIdentity
                        ? "Authenticate as " + root.flow.selectedIdentity.displayName : ""
                    textFormat: Text.PlainText
                    color: "#cccccc"
                }
                Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.flow ? root.flow.inputPrompt : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: "#ffffff"
                }

                // Respect PAM's echo flag: passwords are masked, while prompts
                // explicitly requesting a visible response remain readable.
                TextField {
                    id: answer
                    Layout.fillWidth: true
                    visible: root.flow !== null && root.flow.isResponseRequired
                    enabled: root.accepting
                    echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData
                    color: "#ffffff"
                    background: Rectangle { color: "#252525"; border.color: "#777777"; radius: 0 }
                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.cancel()
                }

                // Passive PAM messages also cover fingerprint/touch prompts;
                // the agent does not parse or modify the system's PAM config.
                Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.rejected ? "Authentication failed. Try again."
                        : root.flow && root.flow.supplementaryMessage.length > 0
                          ? root.flow.supplementaryMessage
                          : root.submitted ? "Checking…"
                          : !root.accepting ? "Waiting for authentication…" : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: root.rejected || (root.flow && root.flow.supplementaryIsError) ? "#e08080" : "#cccccc"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button { text: "Cancel"; onClicked: root.cancel(); Keys.onEscapePressed: root.cancel() }
                    Item { Layout.fillWidth: true }
                    Button { text: "Authenticate"; enabled: root.accepting; onClicked: root.submit(); Keys.onEscapePressed: root.cancel() }
                }
            }
        }
    }
}
