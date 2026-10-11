import QtQuick
import QtQuick.Controls

// Standard slider semantics cover mouse, arrows and PageUp/PageDown. Home/End
// also reach the limits; the focused handle remains visible without tooltips.
Slider {
    id: slider
    property var navigation: null
    Keys.forwardTo: navigation ? [navigation] : []
    required property var theme
    from: 0; to: 1; stepSize: 0.05
    implicitHeight: 28
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
            value = event.key === Qt.Key_Home ? from : to; moved(); event.accepted = true;
        }
    }
    background: Rectangle {
        x: slider.leftPadding; y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: slider.availableWidth; height: 4; radius: 2; color: slider.theme.surface
        Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 2; color: slider.theme.accent }
    }
    handle: Rectangle {
        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: 12; height: 12; radius: 3; color: slider.theme.foreground
        border { color: slider.theme.accent; width: slider.activeFocus ? 2 : 0 }
    }
}
