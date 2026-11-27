import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services
import qs.modules.parts

// NixOS (Generations): every generation kept, and what one changed from the one before; and the
// flake's inputs, how old each is and whether upstream has moved, with whatever keeps an edit to one
// of the dotfiles' own clones from reaching the system; and, by hand, cleaning old generations up
// (never on a timer). Only Clean up changes the system, and it asks for the password first.
Panel {
    id: root

    property string section: "generations"
    property var picked: null
    property int keepDays: 14       // Clean up: generations older than this go; 0 is every one but the running
    readonly property var rows: picked ? Generations.changes[picked.id] ?? null : null

    implicitWidth: 640
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

    icon: "history"
    title: "NixOS"
    subtitle: root.section === "updates"
        ? (Generations.checking ? "Asking upstream…"
           : Generations.attention > 0 ? Generations.attention + " of " + Generations.inputs.length + " inputs want something"
           : Generations.inputs.length + " inputs" + (Generations.checkedAt > 0 ? ", checked " + Generations.ago(Generations.checkedAt) : ""))
        : root.section === "cleanup" ? Generations.cleaning ? "Cleaning up…" : Generations.list.length + " generations kept"
        : Generations.running ? "Running generation " + Generations.running.id + ", NixOS " + Generations.running.version.split(" ")[0]
        : "Every system kept"
    actions: Pill {
        visible: root.section === "updates"
        enabled: !Generations.checking
        implicitHeight: 48
        icon: "refresh"
        text: "Check"
        shortcut: "c"
        onClicked: Generations.check(true)
    }
    keys: [["⏎", root.section === "generations" ? "what changed" : root.section === "updates" ? "upstream" : "choose"], ["G U L", "section"], ["⌫", "back"]]

    Segmented {
        width: parent.width
        options: [{ key: "generations", label: "Generations", shortcut: "g" },
                  { key: "updates", label: "Updates", shortcut: "u" },
                  { key: "cleanup", label: "Clean up", shortcut: "l" }]
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

    // Clean up: what a cleanup drops, chosen by age. It removes the older generations and their packages
    // and rewrites the boot menu, so there is no rolling back to them: hence a choice, and a prompt.
    Flow {
        visible: root.section === "cleanup"
        width: parent.width
        spacing: Config.spaceS

        Repeater {
            model: [{ days: 7, text: "Older than 7 days" }, { days: 14, text: "Older than 14 days" },
                    { days: 30, text: "Older than 30 days" }, { days: 0, text: "All but the running one" }]

            Chip {
                required property var modelData
                text: modelData.text + "  ·  " + Generations.removable(modelData.days)
                selected: root.keepDays === modelData.days
                onClicked: root.keepDays = modelData.days
            }
        }
    }
    Rectangle {
        visible: root.section === "cleanup"
        width: parent.width
        height: note.implicitHeight + 2 * Config.spaceM
        radius: Config.innerRadius
        color: Config.tile

        Label {
            id: note
            anchors { left: parent.left; right: parent.right; margins: Config.spaceM; verticalCenter: parent.verticalCenter }
            wrapMode: Text.Wrap
            color: Config.dim
            text: Generations.removable(root.keepDays) === 0 ? "Nothing to clean up with this choice."
                : Generations.removable(root.keepDays) + " generation(s) go, with the packages only they use, and the boot menu "
                  + "drops them: there is no going back to them. The running one stays."
        }
    }
    Pill {
        visible: root.section === "cleanup"
        kind: "filled"
        icon: "cleaning_services"
        text: Generations.cleaning ? "Cleaning up…" : "Clean now"
        enabled: !Generations.cleaning && Generations.removable(root.keepDays) > 0
        onClicked: Generations.clean(root.keepDays)
    }

    EmptyState {
        width: parent.width
        visible: root.section === "generations" ? !Generations.found : root.section === "updates" && Generations.inputs.length === 0
        icon: root.section === "generations" ? "history" : "folder_off"
        title: root.section === "generations" ? "No generations to read" : "No flake.lock in " + Generations.flake
        hint: root.section === "generations" ? "They are the links in /nix/var/nix/profiles, on NixOS."
            : "Point it at the flake this machine is built from: qs ipc call generations flake <folder>"
    }
}
