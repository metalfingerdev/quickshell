import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services
import "../../services/PrefsSchema.js" as Schema
import "../../services/GlassSchema.js" as GlassSchema
import "../../services/HyprLua.js" as HyprLua

// Every setting there is, as settings.json holds it. Nothing here is clamped to be sensible: a number
// field takes any number, and a colour any colour, so the island can be broken on purpose. The way back
// is the Reset buttons, `qs ipc call prefs reset`, or deleting ~/.config/island/settings.json.
Item {
    id: root

    readonly property int pad: 24
    property string page: "colours"
    property string query: ""
    property string mode: "shared"                    // the table the hyprglass and Hyprland pages edit
    property string target: "windows"                 // liquid glass: the windows' settings, or the island's
    property bool armed: false

    readonly property var pages: [
        { key: "colours", label: "Colours" }, { key: "roles", label: "Every colour" }, { key: "scheme", label: "Scheme" },
        { key: "island", label: "Island" }, { key: "geometry", label: "Geometry" }, { key: "motion", label: "Motion" },
        { key: "clock", label: "Clock" }, { key: "alerts", label: "Alerts" }, { key: "glass", label: "Glass" },
        { key: "hyprglass", label: "Liquid glass" }, { key: "hyprland", label: "Hyprland" }]
    readonly property var modes: [{ key: "shared", label: "Both" }, { key: "dark", label: "Dark" }, { key: "light", label: "Light" }]

    implicitWidth: 760 + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad
    Component.onCompleted: Glass.readDescriptions()

    // a row is a descriptor: what it is, and how to read, write and reset it
    function ofEntry(e) {
        return { id: e.key, label: e.label, sub: e.key, kind: e.kind, options: e.options ?? [], min: e.min ?? 0, max: e.max ?? 1, step: e.step ?? 0.01,
                 get: () => Prefs.shown(e), set: v => Prefs.set(e, v), isSet: () => Prefs.isSet(e),
                 reset: () => Prefs.set(e, Prefs.defaults[e.key]), hint: e.p === "roles" ? Config.current[e.m] : "" }
    }
    // a member of a { shared, dark, light } table property of Glass (hg or hl)
    function ofTable(prop, key, kind, label, sub, def, lo, hi, step) {
        const which = root.target
        const tables = () => prop === "hg" ? Glass.tables(which) : Glass[prop]
        const table = () => tables()[root.mode] ?? {}
        const write = v => {
            const own = Object.assign({}, tables())
            const t = Object.assign({}, own[root.mode] ?? {})
            if (v === undefined) delete t[key]; else t[key] = v
            own[root.mode] = t
            if (prop === "hg") Glass.hg = which === "island" ? { windows: Glass.tables("windows"), island: own } : { windows: own, island: Glass.tables("island") }
            else Glass[prop] = own
        }
        return { id: prop + which + root.mode + key, label: label, sub: sub, kind: kind, options: [], min: lo, max: hi, step: step,
                 get: () => table()[key] ?? (prop === "hg" ? Glass.glassValue(which, key) : def), set: write, isSet: () => key in table(), reset: () => write(undefined), hint: "" }
    }
    function rowsFor(page, query, target, mode) {
        const q = query.trim().toLowerCase()
        const hit = d => q === "" || (d.label + " " + d.sub).toLowerCase().includes(q)
        const plain = Schema.entries.filter(e => e.kind !== "object")
        if (q !== "") {
            let all = plain.map(ofEntry)
            GlassSchema.entries.forEach(g => all.push(ofTable("hg", g.key, g.kind, g.label, "hyprglass " + g.key, g.def, g.min, g.max, 0.01)))
            hyprlandRows().forEach(r => all.push(r))
            return all.filter(hit).slice(0, 80)
        }
        if (page === "hyprglass") return GlassSchema.entries.map(g => ofTable("hg", g.key, g.kind, g.label, g.key, g.def, g.min, g.max, 0.01))
        if (page === "hyprland") return hyprlandRows().slice(0, 120)
        return plain.filter(e => e.group === page).map(ofEntry)
    }
    function hyprlandRows() {
        return Glass.descriptions.filter(o => HyprLua.kindOf(o.default) !== null).map(o => {
            const kind = HyprLua.kindOf(o.default)
            return ofTable("hl", o.name, kind === "colour" ? "colour" : kind, o.name.replace(/^.*:/, "").replace(/_/g, " "), o.name + " · " + (o.description ?? ""),
                           kind === "colour" ? "#" + o.default.slice(2) + o.default.slice(0, 2) : o.default, o.min ?? 0, o.max ?? 1, (o.max ?? 1) <= 1 ? 0.01 : 1)
        })
    }
    readonly property var rows: rowsFor(page, query, target, mode)
    readonly property bool tabled: query === "" && (page === "hyprglass" || page === "hyprland")

    component Field: TextInput {
        color: Config.text
        font.family: Config.mono
        font.pixelSize: Config.body
        selectionColor: Config.secondary
        selectedTextColor: Config.secondaryInk
        clip: true
        onActiveFocusChanged: if (activeFocus) selectAll()
        Keys.onPressed: event => { Engine.key(); event.accepted = false }
    }

    component Entry: Rectangle {
        id: entry
        required property var modelData
        readonly property var d: modelData
        readonly property var value: d.get()
        width: parent.width
        height: 56
        radius: Config.innerRadius + 4
        color: Config.fill3

        Column {
            anchors { left: parent.left; leftMargin: Config.spaceL; right: control.left; rightMargin: Config.spaceM; verticalCenter: parent.verticalCenter }
            Label { width: parent.width; text: entry.d.label; elide: Text.ElideRight; font.pixelSize: Config.body + 1 }
            Label { width: parent.width; text: entry.d.sub; elide: Text.ElideRight; color: Config.dim; font.pixelSize: Config.small }
        }

        Row {
            id: control
            anchors { right: reset.left; rightMargin: Config.spaceS; verticalCenter: parent.verticalCenter }
            spacing: Config.spaceM

            Toggle {
                visible: entry.d.kind === "bool"
                anchors.verticalCenter: parent.verticalCenter
                checked: entry.value === true
                onToggled: on => entry.d.set(on)
            }
            Slider {
                visible: entry.d.kind === "number"
                anchors.verticalCenter: parent.verticalCenter
                width: 220
                value: (Number(entry.value ?? 0) - entry.d.min) / Math.max(1e-9, entry.d.max - entry.d.min)
                valueText: ""
                step: entry.d.step / Math.max(1e-9, entry.d.max - entry.d.min)
                onCommitted: v => entry.d.set(Math.round((entry.d.min + v * (entry.d.max - entry.d.min)) / entry.d.step) * entry.d.step)
            }
            Rectangle {
                visible: entry.d.kind === "colour"
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28; radius: 14
                color: String(entry.value ?? "") !== "" ? entry.value : entry.d.hint !== "" ? entry.d.hint : "transparent"
                border.width: 1
                border.color: Config.divider
            }
            Segmented {
                visible: entry.d.kind === "choice"
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(360, 90 * entry.d.options.length)
                height: 40
                options: entry.d.options.map(o => ({ key: o, label: o }))
                current: String(entry.value)
                onPicked: key => entry.d.set(key)
            }
            // any number, any text: the sliders are a convenience, not a limit
            Rectangle {
                visible: ["number", "colour", "text"].includes(entry.d.kind)
                anchors.verticalCenter: parent.verticalCenter
                width: 104; height: 36; radius: 18
                color: Config.high
                border.width: typed.activeFocus ? 2 : 0
                border.color: Config.primary
                Field {
                    id: typed
                    anchors { fill: parent; leftMargin: Config.spaceM; rightMargin: Config.spaceM }
                    verticalAlignment: TextInput.AlignVCenter
                    text: entry.value === undefined || entry.value === null ? "" : String(entry.value)
                    onEditingFinished: {
                        const t = text.trim()
                        if (t === "") entry.d.reset()
                        else entry.d.set(entry.d.kind === "number" ? Number(t) : t)
                    }
                }
            }
        }

        Pill {
            id: reset
            anchors { right: parent.right; rightMargin: Config.spaceS; verticalCenter: parent.verticalCenter }
            opacity: entry.d.isSet() ? 1 : 0
            enabled: opacity > 0
            kind: "text"
            icon: "restart_alt"
            implicitHeight: 40
            activeFocusOnTab: false
            Accessible.name: "Reset"
            onClicked: entry.d.reset()
        }
    }

    Column {
        id: column
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: "tune"
            title: "Advanced"
            subtitle: Prefs.file
            onBack: Engine.back()

            Pill { icon: "edit_document"; text: "Open file"; implicitHeight: 48; shortcut: "o"; onClicked: Toggles.open(Prefs.file) }
            Pill {
                icon: root.armed ? "warning" : "restart_alt"
                text: root.armed ? "Reset everything?" : "Reset all"
                implicitHeight: 48
                active: root.armed
                onClicked: { if (root.armed) { Prefs.reset(""); root.armed = false } else { root.armed = true; disarm.restart() } }
            }
        }
        Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

        SearchBar {
            width: parent.width
            height: 48
            placeholder: "Search every setting"
            onTextChanged: root.query = text
            onKey: Engine.key()
            onEscaped: { if (text !== "") text = ""; else Engine.close() }
        }

        Flow {
            visible: root.query === ""
            width: parent.width
            spacing: Config.spaceS
            Repeater {
                model: root.pages
                Chip { required property var modelData; text: modelData.label; selected: root.page === modelData.key; onClicked: root.page = modelData.key }
            }
        }
        Segmented {
            visible: root.query === "" && root.page === "hyprglass"
            width: parent.width
            options: [{ key: "windows", label: "Windows" }, { key: "island", label: "Island" }]
            current: root.target
            onPicked: key => root.target = key
        }
        Segmented {
            visible: root.tabled || root.query !== ""
            width: parent.width
            options: root.modes
            current: root.mode
            onPicked: key => root.mode = key
        }
        Label {
            visible: root.query === "" && root.page === "hyprland" && Glass.descriptions.length === 0
            text: "Reading Hyprland's options…"
            color: Config.dim
        }
        Label {
            visible: root.query === "" && root.page === "colours"
            width: parent.width
            wrapMode: Text.Wrap
            text: "With “Keep colours readable” off nothing is adjusted: a colour is drawn as you set it, readable or not."
            color: Config.dim
            font.pixelSize: Config.small + 1
        }

        ScrollList {
            width: parent.width
            maxHeight: 520
            spacing: Config.spaceXs
            visible: root.rows.length > 0

            Repeater {
                model: root.rows
                Entry {}
            }
        }
        EmptyState {
            width: parent.width
            compact: true
            visible: root.rows.length === 0 && !(root.page === "hyprland" && Glass.descriptions.length === 0)
            icon: "search_off"
            title: "No setting matches"
        }

        KeyHints {
            width: parent.width
            keys: [["Tab", "next setting"], ["O", "open the file"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
