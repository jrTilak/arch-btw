import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FloatingWindow {
    id: window
    title: "Settings"
    visible: true
    implicitWidth: 960
    implicitHeight: 640
    color: "#101719"

    property int page: 0
    property color accent: "#62dfc4"
    readonly property var pages: ["Appearance", "Display", "Sound"]

    component Toggle: Switch {
        id: toggle
        indicator: Rectangle {
            implicitWidth: 38
            implicitHeight: 20
            x: toggle.leftPadding
            y: (toggle.height - height) / 2
            color: toggle.checked ? window.accent : "#354144"
            Rectangle {
                x: toggle.checked ? parent.width - width - 3 : 3
                y: 3
                width: 14
                height: 14
                color: toggle.checked ? "#102321" : "#a2b0b3"
                Behavior on x { NumberAnimation { duration: 120 } }
            }
        }
    }

    component SettingRow: Rectangle {
        property string heading
        property string description
        property alias checked: control.checked
        implicitHeight: 80
        Layout.fillWidth: true
        color: "#192225"
        border.color: "#2a3639"
        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true
                Text { text: heading; color: "#e4ecec"; font.pixelSize: 15 }
                Text { text: description; color: "#899a9e"; font.pixelSize: 12 }
            }
            Toggle { id: control }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            color: "#151e20"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
                Text {
                    text: "Settings"
                    color: "#edf4f4"
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
                    Layout.topMargin: 12
                }
                Text {
                    text: "Make it yours."
                    color: "#879a9e"
                    font.pixelSize: 13
                    Layout.bottomMargin: 30
                }
                Repeater {
                    model: window.pages
                    delegate: Rectangle {
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: 46
                        color: window.page === index ? "#253936" : navMouse.containsMouse ? "#202b2e" : "transparent"
                        Rectangle {
                            width: 3; height: parent.height
                            visible: window.page === index
                            color: window.accent
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            text: modelData
                            font.pixelSize: 14
                            color: window.page === index ? window.accent : "#aab8bb"
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.page = index
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a3639" }
                Text { text: "ARCH BTW"; color: "#718589"; font.pixelSize: 11; font.letterSpacing: 2; Layout.topMargin: 12 }
                Text { text: "Interface preview"; color: "#718589"; font.pixelSize: 12 }
            }
        }
        Rectangle { Layout.fillHeight: true; width: 1; color: "#2a3639" }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 36
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: window.pages[window.page]; color: "#edf4f4"; font.pixelSize: 29; font.weight: Font.DemiBold }
                    Text {
                        text: ["A comfortable space for your everyday work.", "Find the right balance for your screen.", "Keep your audio just how you like it."][window.page]
                        color: "#899a9e"
                        font.pixelSize: 13
                    }
                }
                Rectangle {
                    width: 72; height: 26
                    color: "#253936"
                    Text { anchors.centerIn: parent; text: "PREVIEW"; color: window.accent; font.pixelSize: 10; font.letterSpacing: 1 }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.page

                ColumnLayout {
                    spacing: 12
                    Text { text: "COLOR & STYLE"; color: "#748a8f"; font.pixelSize: 11; font.letterSpacing: 1.5; Layout.topMargin: 12 }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 116
                        color: "#192225"
                        border.color: "#2a3639"
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 20; spacing: 14
                            Text { text: "Accent color"; color: "#e4ecec"; font.pixelSize: 15 }
                            Row {
                                spacing: 12
                                Repeater {
                                    model: ["#62dfc4", "#8bbcff", "#c9a2ee", "#f3b979", "#ee929c"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: 30; height: 30
                                        color: modelData
                                        border.width: window.accent === modelData ? 3 : 0
                                        border.color: "#ffffff"
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: window.accent = modelData }
                                    }
                                }
                            }
                        }
                    }
                    SettingRow { heading: "Dark appearance"; description: "A quieter palette for your desktop."; checked: true }
                    SettingRow { heading: "Background blur"; description: "Soften the wallpaper behind windows."; checked: true }
                    SettingRow { heading: "Animations"; description: "Subtle motion when navigating your desktop."; checked: true }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    spacing: 12
                    Text { text: "SCREEN"; color: "#748a8f"; font.pixelSize: 11; font.letterSpacing: 1.5; Layout.topMargin: 12 }
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 145
                        color: "#192225"; border.color: "#2a3639"
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 20
                            Text { text: "Brightness"; color: "#e4ecec"; font.pixelSize: 15 }
                            Slider { Layout.fillWidth: true; from: 0; to: 100; value: 70 }
                            Text { text: "Built-in display  ·  1920 × 1080  ·  100% scale"; color: "#899a9e"; font.pixelSize: 12 }
                        }
                    }
                    SettingRow { heading: "Night light"; description: "Use warmer colors in the evening." }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    spacing: 12
                    Text { text: "OUTPUT"; color: "#748a8f"; font.pixelSize: 11; font.letterSpacing: 1.5; Layout.topMargin: 12 }
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 145
                        color: "#192225"; border.color: "#2a3639"
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 20
                            Text { text: "Volume"; color: "#e4ecec"; font.pixelSize: 15 }
                            Slider { Layout.fillWidth: true; from: 0; to: 100; value: 45 }
                            Text { text: "Built-in speakers"; color: "#899a9e"; font.pixelSize: 12 }
                        }
                    }
                    SettingRow { heading: "Mute microphone"; description: "Pause microphone input." }
                    Item { Layout.fillHeight: true }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#2a3639" }
            Text { text: "Mockup only · Changes stay inside this preview."; color: "#718589"; font.pixelSize: 12 }
        }
    }
}
