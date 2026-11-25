import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// NixOS (Generations): every generation kept, and what one changed from the one before; and the
// flake's inputs, how old each is and whether upstream has moved, with whatever keeps an edit to one
// of the dotfiles' own clones from reaching the system. Nothing here changes the system.
Item {
    id: root

    readonly property int pad: 24
    property string section: "generations"
    property var picked: null
    readonly property var rows: picked ? Generations.changes[picked.id] ?? null : null

    implicitWidth: 640
    implicitHeight: column.implicitHeight + 2 * pad
    Component.onCompleted: { Generations.refresh(); Generations.check(false) }

    function pick(gen) {
        picked = gen
        Generations.diff(gen)
    }
    // on GitHub, what upstream has that the lock doesn't
    function upstream(input) {
        const head = Generations.heads[input.name]?.[0] ?? ""
        if (input.url === "") return
        Toggles.open(input.type === "github" && head !== "" && head !== input.rev
                     ? input.url + "/compare/" + input.rev + "..." + head : input.url)
        Engine.close()
    }
    function glyph(kind) {
        return { added: "add_circle", removed: "remove_circle", changed: "sync", size: "data_usage" }[kind] ?? "sync"
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: "history"
            title: "NixOS"
            subtitle: root.section === "updates"
                ? (Generations.checking ? "Asking upstream…"
                   : Generations.attention > 0 ? Generations.attention + " of " + Generations.inputs.length + " inputs want something"
                   : Generations.inputs.length + " inputs" + (Generations.checkedAt > 0 ? ", checked " + Generations.ago(Generations.checkedAt) : ""))
                : Generations.running ? "Running generation " + Generations.running.id + ", NixOS " + Generations.running.version.split(" ")[0]
                : "Every system kept"
            onBack: Engine.back()

            Pill {
                visible: root.section === "updates"
                enabled: !Generations.checking
                implicitHeight: 48
                icon: "refresh"
                text: "Check"
                shortcut: "c"
                onClicked: Generations.check(true)
            }
        }

        Segmented {
            width: parent.width
            options: [{ key: "generations", label: "Generations", shortcut: "g" },
                      { key: "updates", label: "Updates", shortcut: "u" }]
            current: root.section
            onPicked: key => root.section = key
        }

        ScrollList {
            width: parent.width
            visible: root.section === "generations" && Generations.found
            maxHeight: (root.picked ? 3 : 6) * 68 + 14
            spacing: Config.spaceXs

            Repeater {
                model: root.section === "generations" ? Generations.list : []

                ListEntry {
                    required property var modelData
                    required property int index

                    width: parent.width
                    filled: true
                    focus: index === 0
                    active: root.picked?.id === modelData.id
                    icon: modelData.current ? "check_circle" : modelData.booted ? "restart_alt" : "history"
                    title: "Generation " + modelData.id + (modelData.current ? ", running" : "")
                           + (modelData.booted && !modelData.current ? ", booted" : "")
                    subtitle: modelData.version.split(" ")[0] + "  ·  Linux " + modelData.kernel
                    trailing: Generations.ago(modelData.made)
                    onClicked: root.pick(modelData)
                }
            }
        }

        SectionLabel {
            visible: root.section === "generations" && root.picked !== null
            text: root.picked ? "From generation " + (Generations.list.find(g => g.id < root.picked.id)?.id ?? "—") : ""
        }
        ScrollList {
            width: parent.width
            visible: root.section === "generations" && (root.rows?.length ?? 0) > 0
            maxHeight: 4 * 68 + 14
            spacing: Config.spaceXs

            Repeater {
                model: root.section === "generations" ? root.rows ?? [] : []

                ListEntry {
                    required property var modelData
                    width: parent.width
                    filled: true
                    icon: root.glyph(modelData.kind)
                    title: modelData.name
                    subtitle: modelData.change
                    trailing: modelData.size
                }
            }
        }
        EmptyState {
            width: parent.width
            compact: true
            visible: root.section === "generations" && root.picked !== null && (root.rows?.length ?? 0) === 0
            icon: Generations.diffing >= 0 ? "hourglass_top" : root.rows ? "check" : "history"
            title: Generations.diffing >= 0 ? "Comparing the two systems…"
                 : root.rows ? "No package changed: only the configuration did"
                 : "The first generation kept: nothing to compare it with"
        }

        ScrollList {
            width: parent.width
            visible: root.section === "updates" && Generations.inputs.length > 0
            maxHeight: 6 * 68 + 14
            spacing: Config.spaceXs

            Repeater {
                model: root.section === "updates" ? Generations.inputs : []

                ListEntry {
                    required property var modelData
                    required property int index
                    readonly property var standing: Generations.standing(modelData)

                    width: parent.width
                    filled: true
                    focus: index === 0
                    active: standing.attention
                    icon: standing.attention ? "upgrade" : standing.text !== "" ? "check_circle" : "deployed_code"
                    title: modelData.name
                    subtitle: (standing.text !== "" ? standing.text + "  ·  " : "") + "locked " + Generations.ago(modelData.modified)
                    trailing: modelData.ref
                    onClicked: root.upstream(modelData)
                }
            }
        }

        EmptyState {
            width: parent.width
            visible: root.section === "generations" ? !Generations.found : Generations.inputs.length === 0
            icon: root.section === "generations" ? "history" : "folder_off"
            title: root.section === "generations" ? "No generations to read" : "No flake.lock in " + Generations.flake
            hint: root.section === "generations" ? "They are the links in /nix/var/nix/profiles, on NixOS."
                : "Point it at the flake this machine is built from: qs ipc call generations flake <folder>"
        }

        KeyHints {
            width: parent.width
            keys: [["⏎", root.section === "generations" ? "what changed" : "upstream"], ["G U", "section"], ["⌫", "back"]]
        }
    }
}
