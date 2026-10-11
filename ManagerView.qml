import QtQuick
import QtQuick.Layouts
import "Model.js" as Model

// The whole manager UI. It lives either inside the bar panel (Panel.qml) or in
// a floating window (PopoutWindow.qml); both feed it the same UiState (`ui`).
//
// Layout, Omatravel-style: a thin accent frame, a compact header with spaced
// caps title and text tabs, filters on the left, and in "List + stage" mode a
// big stage on the right showing the selected plugin's preview and actions.
Item {
    id: view

    property var ui: null
    clip: true

    readonly property bool split: ui.viewMode === "split"

    // Esc steps back out of whatever is covering things. True when it did something.
    function stepBack() {
        if (ui.confirm) { ui.confirm = null; return true }
        if (ui.selected && !split) { ui.selected = null; return true }
        if (ui.showLog) { ui.showLog = false; return true }
        return false
    }

    function cycleLayout() {
        var order = ["split", "grid", "list", "compact"]
        ui.setView(order[(order.indexOf(ui.viewMode) + 1) % order.length])
    }

    // In a window nothing else listens for Esc; in the panel PanelKeyCatcher does.
    Keys.onEscapePressed: function(e) {
        if (ui.popped) { view.stepBack(); e.accepted = true }
        else e.accepted = false
    }

    Connections {
        target: view.ui
        ignoreUnknownSignals: true
        function onSearchCleared() { searchField.text = "" }
        function onFocusSearch() { searchField.forceActiveFocus() }
        // one header search box serves both: the catalog, and (on Settings) the settings
        function onTabNameChanged() { searchField.text = view.ui.tabName === "settings" ? view.ui.settingsFilter : view.ui.query }
    }

    // ---- chrome ----------------------------------------------------------------
    Rectangle {   // opaque base: the same surface in the panel and the pop-out window
        anchors.fill: parent
        radius: ui.r(3)
        color: ui.surface
    }
    Rectangle {   // accent wash
        anchors.fill: parent
        radius: ui.r(3)
        color: ui.accentTint(ui.tintPct / 100)
    }
    Rectangle {   // edge: a plain neutral line (like the Omaudix panel); accent only if "Window outline" is on
        anchors.fill: parent
        radius: ui.r(3)
        color: "transparent"
        border.width: 1
        border.color: ui.frameOn ? ui.accent : ui.tint(0.14)
        opacity: ui.frameOn ? 0.8 : 1
    }

    function setSearch(t) {
        if (ui.tabName === "settings") ui.settingsFilter = t
        else ui.query = t
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ui.px(14)
        spacing: ui.px(12)

        // ---- header card: title, search, actions ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerCol.implicitHeight + ui.px(24)
            radius: ui.r(2.5)
            color: ui.tint(0.05)
            border.width: 1
            border.color: ui.tint(0.08)

            ColumnLayout {
                id: headerCol
                anchors.fill: parent
                anchors.margins: ui.px(12)
                spacing: ui.px(10)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ui.px(12)

                    Rectangle {
                        Layout.preferredWidth: ui.px(46)
                        Layout.preferredHeight: ui.px(46)
                        Layout.alignment: Qt.AlignVCenter
                        radius: ui.r(2)
                        color: ui.accentTint(0.18)
                        border.width: 1
                        border.color: ui.tint(0.08)
                        Rectangle {
                            anchors.centerIn: parent
                            width: ui.px(14); height: width; radius: width / 2
                            color: ui.accent
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        Txt {
                            ui: view.ui
                            text: "OMANAGER"
                            font.pixelSize: ui.fs(14)
                            font.letterSpacing: 2
                            font.weight: Font.DemiBold
                        }
                        Txt {
                            ui: view.ui
                            font.pixelSize: ui.fs(10)
                            opacity: 0.6
                            text: ui.service && ui.service.catalog.length > 0
                                ? ui.service.catalog.length + " plugins  \u00B7  " + ui.service.installed.length + " installed"
                                : "Plugin manager"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: ui.px(110)
                        Layout.preferredWidth: ui.px(320)
                        Layout.maximumWidth: ui.px(380)
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: ui.px(30)
                        radius: ui.r(1.5)
                        color: ui.tint(0.06)
                        border.width: 1
                        border.color: searchField.activeFocus ? ui.tint(0.28) : ui.tint(0.10)
                        clip: true               // text longer than the box is cut at its edge, never drawn past it

                        Txt { ui: view.ui; anchors.left: parent.left; anchors.leftMargin: ui.px(10); anchors.verticalCenter: parent.verticalCenter; text: "\u2315"; opacity: 0.5; font.pixelSize: ui.fs(14) }
                        PasteInput {
                            id: searchField
                            key: "search"
                            service: ui.service
                            anchors.fill: parent
                            anchors.leftMargin: ui.px(30)
                            anchors.rightMargin: ui.px(30)
                            color: ui.fg
                            font.family: ui.fontName
                            font.pixelSize: ui.fs(12)
                            maximumLength: 50
                            text: ui.query
                            onTextEdited: view.setSearch(text)
                            Keys.onEscapePressed: function(e) {
                                if (text !== "") { text = ""; view.setSearch(""); e.accepted = true }
                                else e.accepted = false
                            }
                            Keys.onDownPressed: if (ui.tabName !== "settings") results.focusGrid()
                            Txt {
                                ui: view.ui
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                elide: Text.ElideRight
                                visible: searchField.text === "" && !searchField.activeFocus
                                text: ui.tabName === "settings" ? "Search settings\u2026" : "Search names, authors, tags\u2026"
                                opacity: 0.4
                            }
                        }
                        Txt {
                            ui: view.ui
                            anchors.right: parent.right
                            anchors.rightMargin: ui.px(10)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchField.text !== ""
                            text: "\u2715"
                            opacity: 0.6
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: { searchField.text = ""; view.setSearch("") } }
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.minimumWidth: 0 }

                    Btn {
                        ui: view.ui
                        Layout.alignment: Qt.AlignVCenter
                        visible: ui.tabName !== "settings"
                        text: ui.viewMode === "split" ? "\u25E7 Stage"
                            : (ui.viewMode === "grid" ? "\u25A6 Cards"
                            : (ui.viewMode === "list" ? "\u2630 List" : "\u2263 Compact"))
                        onClicked: view.cycleLayout()
                    }
                    Btn {
                        ui: view.ui
                        Layout.alignment: Qt.AlignVCenter
                        visible: ui.tabName === "updates" && ui.service && ui.service.updateCount > 0
                        kind: "primary"
                        text: "Update all (" + (ui.service ? ui.service.updateCount : 0) + ")"
                        onClicked: {
                            for (var i = 0; i < ui.items.length; i++)
                                ui.service.perform("update", ui.items[i].id, ui.items[i].name, ui.items[i].repo)
                        }
                    }
                    Btn {
                        ui: view.ui
                        Layout.alignment: Qt.AlignVCenter
                        visible: ui.tabName === "settings"
                        kind: settingsView.confirmReset ? "primary" : "normal"
                        text: settingsView.confirmReset ? "Really reset?" : "Reset all"
                        onClicked: settingsView.resetAll()
                    }
                    Btn {
                        ui: view.ui
                        Layout.alignment: Qt.AlignVCenter
                        text: ui.service && ui.service.catalogState === "loading" ? "Refreshing\u2026" : "\u21BB Refresh"
                        enabled: ui.service && ui.service.catalogState !== "loading"
                        onClicked: { ui.service.refresh(true); ui.service.refreshInstalled() }
                    }
                    Btn {
                        ui: view.ui
                        Layout.alignment: Qt.AlignVCenter
                        text: ui.popped ? "\u21F2 Dock" : "\u21F1 Pop out"
                        onClicked: ui.popped ? ui.dockRequested() : ui.popOutRequested()
                    }
                    Btn { ui: view.ui; Layout.alignment: Qt.AlignVCenter; text: "\u00D7"; implicitWidth: ui.px(30); onClicked: ui.closeRequested() }
                }
            }
        }

        // ---- tabs ------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            implicitHeight: ui.px(32)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: ui.tint(0.10)
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: [
                        { key: "browse", label: "Browse", n: -1 },
                        { key: "installed", label: "Installed", n: ui.service ? ui.service.installed.length : 0 },
                        { key: "updates", label: "Updates", n: ui.service ? ui.service.updateCount : 0 },
                        { key: "saved", label: "Saved", n: ui.service ? Object.keys(ui.service.bookmarks).length : 0 },
                        { key: "settings", label: "Settings", n: -1 }
                    ]
                    delegate: Item {
                        readonly property bool on: ui.tabName === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true

                        Row {
                            id: tabRow
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            spacing: ui.px(6)
                            Txt {
                                ui: view.ui
                                text: modelData.label
                                font.pixelSize: ui.fs(12)
                                font.weight: parent.parent.on ? Font.DemiBold : Font.Normal
                                opacity: parent.parent.on ? 1 : (tabArea.containsMouse ? 0.8 : 0.5)
                            }
                            Rectangle {
                                visible: modelData.n > 0
                                width: cnt.implicitWidth + ui.px(10); height: ui.px(15); radius: height / 2
                                color: modelData.key === "updates" ? ui.warn : ui.tint(0.16)
                                anchors.verticalCenter: parent.verticalCenter
                                Txt {
                                    id: cnt
                                    ui: view.ui
                                    anchors.centerIn: parent
                                    text: modelData.n
                                    font.pixelSize: ui.fs(9)
                                    color: modelData.key === "updates" ? ui.warnText : ui.fg
                                }
                            }
                        }
                        Rectangle {
                            visible: parent.on
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            radius: 1
                            color: ui.accent
                        }
                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ui.tabName = modelData.key
                        }
                    }
                }
            }
        }

        // ---- content card -------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            radius: ui.r(2.5)
            color: ui.tint(0.035)
            border.width: 1
            border.color: ui.tint(0.07)
            clip: true

        // ---- main ----
        Item {
            id: mainArea
            anchors.fill: parent
            anchors.margins: ui.px(10)

            RowLayout {
                anchors.fill: parent
                spacing: ui.px(12)
                visible: ui.tabName !== "settings"

                FilterSidebar {
                    ui: view.ui
                    visible: ui.filtersPanelKey === "left"
                    Layout.preferredWidth: ui.px(214)
                    Layout.fillHeight: true
                }
                Rectangle {
                    visible: ui.filtersPanelKey === "left"
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: ui.tint(0.10)
                }

                ResultsView {
                    id: results
                    ui: view.ui
                    Layout.fillWidth: !view.split
                    Layout.minimumWidth: ui.px(220)
                    // wide enough for the full stats line ("... upgraded today") without cutting it off
                    Layout.preferredWidth: view.split
                        ? Math.max(ui.px(240), Math.min(ui.px(500), mainArea.width * 0.46)) : ui.px(300)
                    Layout.maximumWidth: view.split ? Math.max(ui.px(240), Math.min(ui.px(500), mainArea.width * 0.46)) : 100000
                    Layout.fillHeight: true
                }

                Rectangle {
                    visible: view.split
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: ui.tint(0.10)
                }

                // the stage: big preview + actions for the selected (or top) plugin
                DetailPane {
                    ui: view.ui
                    inline: true
                    p: ui.stageItem
                    visible: view.split
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.fillHeight: true
                }
            }

            SettingsView {
                id: settingsView
                ui: view.ui
                anchors.fill: parent
                visible: ui.tabName === "settings"
            }

            DetailPane {
                ui: view.ui
                p: ui.selected
                visible: !view.split && ui.selected !== null && ui.tabName !== "settings"
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: Math.min(ui.px(420), parent.width - ui.px(40))
            }
        }

        }

        // ---- activity log ----
        Rectangle {
            Layout.fillWidth: true
            visible: ui.showLog
            implicitHeight: ui.px(110)
            radius: Math.max(2, ui.radius)
            color: ui.tint(0.05)
            border.width: 1
            border.color: ui.tint(0.10)
            clip: true
            ListView {
                anchors.fill: parent
                anchors.margins: ui.px(8)
                model: ui.service ? ui.service.log.slice().reverse() : []
                delegate: Txt {
                    ui: view.ui
                    width: ListView.view.width
                    elide: Text.ElideRight
                    font.pixelSize: ui.fs(10)
                    color: modelData.ok ? ui.fg : ui.bad
                    text: Qt.formatTime(new Date(modelData.time), "HH:mm:ss") + "  " + modelData.text
                }
            }
            Txt {
                ui: view.ui
                anchors.centerIn: parent
                visible: !ui.service || ui.service.log.length === 0
                text: "Nothing has happened yet."
                opacity: 0.4
            }
        }

        // ---- footer: Esc hint, status, log, and the instant-apply note ----------------
        RowLayout {
            Layout.fillWidth: true
            spacing: ui.px(8)

            Rectangle {
                visible: !ui.popped
                implicitWidth: escLabel.implicitWidth + ui.px(12)
                implicitHeight: ui.px(18)
                radius: ui.r(1)
                color: ui.tint(0.08)
                Txt { id: escLabel; ui: view.ui; anchors.centerIn: parent; text: "Esc"; font.pixelSize: ui.fs(10); opacity: 0.75 }
            }
            Txt { ui: view.ui; visible: !ui.popped; text: "close"; font.pixelSize: ui.fs(10); opacity: 0.45 }

            Txt {
                ui: view.ui
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: ui.fs(10)
                opacity: 0.65
                visible: ui.tabName !== "settings"
                color: ui.service && ui.service.catalogState === "stale" ? ui.warn : ui.fg
                text: {
                    if (!ui.service) return ""
                    if (ui.service.busy) return ui.service.busyLabel + (ui.service.queue.length > 0 ? "  (+" + ui.service.queue.length + " queued)" : "")
                    if (ui.service.catalogState === "loading")
                        return ui.service.catalog.length > 0 ? "Checking for a newer catalog\u2026" : "Downloading catalog\u2026"
                    if (ui.service.catalogState === "stale") return "Offline: showing the saved catalog from " + Model.relTime(ui.service.catalogTime, ui.now)
                    if (ui.service.catalogState === "error") return ui.service.catalogError
                    return "Catalog checked " + Model.relTime(ui.service.catalogTime, ui.now)
                        + (ui.service.log.length ? "  \u00B7  " + ui.service.log[ui.service.log.length - 1].text : "")
                }
            }
            Txt {
                ui: view.ui
                Layout.fillWidth: true
                visible: ui.tabName === "settings"
                elide: Text.ElideRight
                font.pixelSize: ui.fs(10)
                opacity: 0.45
                text: settingsView.changed === 0 ? "All settings are at their defaults"
                    : settingsView.changed + (settingsView.changed === 1 ? " setting differs" : " settings differ") + " from the defaults"
            }
            Btn { ui: view.ui; visible: ui.tabName !== "settings"; text: ui.showLog ? "Hide log" : "Log"; implicitHeight: ui.px(22); active: ui.showLog; onClicked: ui.showLog = !ui.showLog }
            Txt { ui: view.ui; visible: ui.tabName === "settings"; text: "Changes apply instantly"; font.pixelSize: ui.fs(10); opacity: 0.45 }
        }
    }

    // ---- confirmation dialog ----
    Rectangle {
        anchors.fill: parent
        visible: ui.confirm !== null
        radius: ui.radius
        color: Qt.rgba(ui.surface.r, ui.surface.g, ui.surface.b, 0.85)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: function(w) { w.accepted = true } }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - ui.px(40), ui.px(460))
            implicitHeight: dlg.implicitHeight + ui.px(36)
            height: implicitHeight
            radius: ui.radius
            color: ui.surface
            border.width: 1
            border.color: ui.tint(0.18)

            ColumnLayout {
                id: dlg
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: ui.px(18)
                spacing: ui.px(10)

                readonly property string kind: ui.confirm ? ui.confirm.kind : ""
                readonly property var plug: ui.confirm ? ui.confirm.p : null

                Txt {
                    ui: view.ui
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: ui.fs(15)
                    font.weight: Font.DemiBold
                    text: dlg.plug ? (dlg.kind === "remove" ? "Remove " : (dlg.kind === "update" ? "Update " : "Install ")) + dlg.plug.name + "?" : ""
                }
                Txt {
                    ui: view.ui
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    opacity: 0.75
                    text: {
                        if (!dlg.plug) return ""
                        if (dlg.kind === "remove") return "The plugin folder is deleted from your plugins directory."
                        var t = "Plugins run as unsandboxed code inside your shell, with your user permissions. Installing fetches the plugin's current upstream code"
                        t += dlg.plug.verified ? ", which may be newer than the snapshot that earned its Verified badge." : "."
                        if (!dlg.plug.verified) t += "\n\nThis plugin is NOT verified."
                        return t
                    }
                }
                Txt {
                    ui: view.ui
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    visible: dlg.plug && dlg.plug.repo !== "" && dlg.kind !== "remove"
                    font.pixelSize: ui.fs(10)
                    opacity: 0.55
                    text: dlg.plug ? "From " + dlg.plug.repo : ""
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: ui.px(8)
                    Btn { ui: view.ui; text: "Cancel"; onClicked: ui.confirm = null }
                    Btn {
                        ui: view.ui
                        kind: dlg.kind === "remove" ? "danger" : "primary"
                        text: dlg.kind === "remove" ? "Remove" : (dlg.kind === "update" ? "Update" : "Install")
                        onClicked: { var c = ui.confirm; ui.confirm = null; if (c) ui.runAction(c.kind, c.p) }
                    }
                }
            }
        }
    }
}
