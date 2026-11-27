pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components
import "Generations.js" as Read

// NixOS's generations, and the flake this machine is built from. Read-only on purpose: switching,
// rolling back and deleting take root, and stay the person's to run with nixos-rebuild.
Singleton {
    id: root

    // NIXOS_FLAKE: set by the quickshell unit, from Home Manager's session variable of the same name
    // its config/* clones (the dotfiles, each a repo of its own and an input) are checked against the lock
    property string flake: Quickshell.env("NIXOS_FLAKE") || Quickshell.env("HOME") + "/nixos-dotfiles"
    property Store store: Store {
        category: "generations"
        property alias flake: root.flake
    }

    property var list: []
    property var inputs: []
    property var clones: ({})       // repo name -> [head, uncommitted files, unpushed commits]
    property var heads: ({})        // input name -> its branch upstream
    property var changes: ({})      // generation id -> the closure's diff from the one before
    property int diffing: -1
    property real checkedAt: 0
    readonly property bool checking: upstream.running
    readonly property var running: list.find(g => g.current) ?? null
    readonly property bool found: list.length > 0

    // Cleaning up, by hand: the generations a cleanup of `days` would drop (0: every one but the running),
    // and the cleanup itself as root, through the polkit prompt. Never on a timer: the rollback is the point.
    property bool cleaning: false
    function removable(days) {
        const cut = now() - days * 86400
        return list.filter(g => !g.current && (days === 0 || g.made < cut)).length
    }
    function clean(days) {
        if (cleaning || ![0, 7, 14, 30].includes(days)) return
        cleaning = true
        Activities.start("cleanup", "Cleaning up generations")
        const gc = days === 0 ? "-d" : "--delete-older-than " + days + "d"
        // absolute paths: pkexec gives the command a bare PATH. The boot menu is rewritten so it drops them too.
        cleaner.command = ["pkexec", "/run/current-system/sw/bin/sh", "-c",
            "/run/current-system/sw/bin/nix-collect-garbage " + gc
            + " && /nix/var/nix/profiles/system/bin/switch-to-configuration boot"]
        cleaner.running = true
    }
    Process {
        id: cleaner
        onExited: code => {
            root.cleaning = false
            Activities.finish("cleanup", code === 0 ? "done" : "failed")
            root.refresh()
        }
    }

    function now() { return Date.now() / 1000 }
    function ago(seconds) { return Read.ago(seconds, now()) }
    function refresh() {
        if (!lister.running) lister.running = true
        if (!local.running) local.running = true
    }
    function standing(input) {
        return Read.standing(input, clones[input.repo], heads[input.name]?.[0] ?? "")
    }
    readonly property int attention: inputs.filter(i => standing(i).attention).length

    // What changed from the generation before, once: a closure diff reads the whole store
    function diff(gen) {
        const before = list.find(g => g.id < gen.id)
        if (!before || gen.id in changes || differ.running) return
        diffing = gen.id
        differ.command = ["nix", "store", "diff-closures", before.path, gen.path]
        differ.running = true
    }

    // Asks every input's host for its branch, so it runs when asked and not more than every ten minutes
    property bool wanted: false     // asked before the lock was read: it runs once it is
    function check(force) {
        if (upstream.running || (!force && now() - checkedAt < 600)) return
        if (local.running) { wanted = true; return }
        const args = []
        for (const i of inputs.filter(i => i.url !== "" && i.type !== "path"))
            args.push(i.name, i.url, i.ref !== "" ? "refs/heads/" + i.ref : "HEAD")
        if (args.length === 0) return
        upstream.command = ["sh", "-c", "while [ $# -ge 3 ]; do (printf '%s\\t%s\\n' \"$1\" "
            + "\"$(timeout 15 git ls-remote \"$2\" \"$3\" 2>/dev/null | head -n 1 | cut -f1)\") & shift 3; done; wait", "sh"].concat(args)
        upstream.running = true
    }

    Process {
        id: lister
        command: ["sh", "-c", "for l in /nix/var/nix/profiles/system-*-link; do t=$(readlink -f \"$l\"); "
            + "printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"${l##*/}\" \"$(stat -c %Y \"$l\")\" \"$t\" \"$(cat \"$t/nixos-version\" 2>/dev/null)\" \"$(readlink \"$t/kernel\")\"; done; "
            + "printf 'current\\t%s\\nbooted\\t%s\\n' \"$(readlink -f /run/current-system)\" \"$(readlink -f /run/booted-system)\""]
        stdout: StdioCollector { onStreamFinished: root.list = Read.generations(text) }
    }

    // the lock, a record separator, then each clone under config/
    Process {
        id: local
        command: ["sh", "-c", "cd \"$1\" 2>/dev/null || exit 0; cat flake.lock; printf '\\n\\036\\n'; "
            + "for d in config/*/; do [ -d \"$d.git\" ] || continue; printf '%s\\t%s\\t%s\\t%s\\n' \"$(basename \"$d\")\" "
            + "\"$(git -C \"$d\" rev-parse HEAD 2>/dev/null)\" \"$(git -C \"$d\" --no-optional-locks status --porcelain 2>/dev/null | wc -l)\" "
            + "\"$(git -C \"$d\" rev-list --count '@{u}..HEAD' 2>/dev/null || echo -1)\"; done", "sh", root.flake]
        stdout: StdioCollector {
            onStreamFinished: {
                const [lock, repos] = text.split("\x1e")
                root.inputs = Read.inputs(lock)
                root.clones = Read.table(repos)
                if (root.wanted) { root.wanted = false; root.check(false) }
            }
        }
    }

    Process {
        id: upstream
        stdout: StdioCollector {
            onStreamFinished: {
                root.heads = Read.table(text)
                root.checkedAt = root.now()
            }
        }
    }

    Process {
        id: differ
        stdout: StdioCollector {
            onStreamFinished: {
                const next = Object.assign({}, root.changes)
                next[root.diffing] = Read.closureDiff(text)
                root.changes = next
                root.diffing = -1
            }
        }
    }

    IpcHandler {
        target: "generations"

        function flake(path: string): void { root.flake = path; root.refresh() }
        function list(): string { return JSON.stringify(root.list, null, 2) }
    }
}
