import QtQuick

// A single-line TextInput that never reads the clipboard itself. Qt's own paste
// reads the whole clipboard before any length limit applies, so Ctrl+V,
// Shift+Insert and middle-click are routed to the Service instead, which reads
// at most a fixed number of bytes and gives the text back under `key`.
TextInput {
    id: field

    property string key: ""            // identifies this field in Service.pasted
    property var service: null         // the Service that performs the capped read

    selectByMouse: true

    Keys.onPressed: function(event) {
        if (event.matches(StandardKey.Paste)) {
            event.accepted = true      // stop TextInput's own paste
            if (field.service) field.service.requestPaste(field.key)
        }
    }

    // Accepts only middle-button presses, so Qt never sees the release that
    // triggers primary-selection paste. Other buttons pass through.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onPressed: function(mouse) { mouse.accepted = true }
        onReleased: function(mouse) { mouse.accepted = true }
    }

    Connections {
        target: field.service
        ignoreUnknownSignals: true
        function onPasted(k, text) {
            if (k !== field.key) return
            var line = String(text === null || text === undefined ? "" : text).split(/\r?\n/)[0]
            field.insert(field.cursorPosition, line)   // maximumLength still applies
        }
    }
}
