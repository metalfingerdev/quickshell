pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components

// awww restores the last wallpaper by itself, so at startup this only asks it what is showing.
Singleton {
    id: root

    // The folders the picker shows (Settings → Wallpaper): any, anywhere. The island's own pictures are
    // always listed with them, nothing to tell them apart; they're only what a first install starts with.
    property var folders: [Quickshell.env("HOME") + "/Pictures/Wallpapers"]
    property string transition: "fade"       // awww: none fade simple wipe grow center outer wave any random
    property real duration: 0.8

    property var files: []
    property string current: ""
    readonly property int currentIndex: files.indexOf(current)

    ColorQuantizer {
        id: quantizer
        source: root.current ? root.fileUrl(root.current) : ""
        depth: 3
        rescaleSize: 96              // decode small: it only needs the colours
    }
    readonly property var swatches: Array.from(quantizer.colors ?? [])
    // The schemes this image offers (Config.wallpaperOptions: an accent, and the surfaces' hue and
    // tint from the picture's cast), the first being Auto. The one picked in views/Colours.qml is kept
    // for the image it was picked for; another image starts at its own Auto.
    readonly property var options: Config.wallpaperOptions(swatches)
    property int pickedIndex: 0
    property string pickedFor: ""
    readonly property int optionIndex: pickedFor !== "" && pickedFor === current
        ? Math.max(0, Math.min(pickedIndex, options.length - 1)) : 0
    readonly property var option: options.length > 0 ? options[optionIndex] : null
    readonly property color seed: option ? option.accent : "#4f9d8f"
    readonly property string optionKey: current + "|" + optionIndex       // which image, which option
    function pick(index) { pickedIndex = index; pickedFor = current }

    // shellPath keeps ~/.config/quickshell, a link that follows rebuilds, where a store path would be gone
    // after the next garbage collection.
    readonly property string shipped: Quickshell.shellPath("assets/wallpapers")

    property Store store: Store {
        category: "wallpaper"
        property alias folders: root.folders
        property alias animated: root.animated
        property alias pickedIndex: root.pickedIndex
        property alias pickedFor: root.pickedFor
    }

    function fileUrl(p) { return "file://" + p.split("/").map(encodeURIComponent).join("/") }
    function baseName(p) { return p ? p.split("/").pop() : "" }

    function reload() { lister.running = true }

    // Says what's wrong ("" = fine).
    function addFolder(path) {
        path = path.replace(/\/+$/, "")
        if (!path.startsWith("/")) return `not an absolute path: ${path}`
        if (!folders.includes(path)) folders = folders.concat([path])
        return ""
    }
    function removeFolder(path) { folders = folders.filter(f => f !== path) }
    // next tick: the listing's command is a binding on `folders`, not updated yet when this runs
    onFoldersChanged: Qt.callLater(reload)

    // A first login: awww has nothing to restore, so the island's own wallpaper goes up once both the query
    // and the listing are done and nothing shows. From then on awww restores whatever was picked last.
    property bool queried: false
    property bool listed: false
    function firstWallpaper() {
        if (queried && listed && current === "") { set(shipped + "/wallpaper.gif"); applySaver() }
    }

    // Battery saver: awww keeps decoding an animated GIF's frames, so a GIF with a still (the same name as
    // .jpg, .png or .webp beside it, wherever it is) shows the still meanwhile, and comes back when the
    // profile leaves power-saver. `animated` is remembered, so a restart while saving still brings it back.
    readonly property bool saving: Toggles.profile === "power-saver"
    property string animated: ""
    // prints the still beside the GIF given, or nothing (LockConfig asks the same)
    readonly property string stillScript: 'for e in jpg jpeg png webp JPG JPEG PNG WEBP; do f="${1%.*}.$e"; [ -f "$f" ] && { echo "$f"; exit 0; }; done'
    function applySaver() {
        if (saving) {
            if (/\.gif$/i.test(current)) { stillFinder.from = current; stillFinder.running = true }
        } else if (animated !== "") {
            set(animated)
        }
    }
    Process {
        id: stillFinder
        property string from: ""
        command: ["sh", "-c", root.stillScript, "sh", from]
        stdout: StdioCollector {
            onStreamFinished: {
                const still = text.trim()
                if (still && root.saving && root.current === stillFinder.from) { root.set(still); root.animated = stillFinder.from }
            }
        }
    }
    onSavingChanged: applySaver()

    function set(path) {
        if (!path) return
        animated = ""            // a pick of your own ends the saver's swap
        current = path
        // waits (up to ~10 s) for awww-daemon, so it's safe right after login
        Quickshell.execDetached(["sh", "-c",
            'i=0; until awww query >/dev/null 2>&1; do i=$((i+1)); [ "$i" -gt 50 ] && exit 1; sleep 0.2; done; '
          + 'exec awww img "$1" --transition-type "$2" --transition-duration "$3"',
            "sh", path, transition, String(duration)])
    }

    function step(delta) {
        if (files.length === 0) return
        set(files[(Math.max(0, currentIndex) + delta + files.length) % files.length])
    }

    function random() {
        if (files.length < 2) return set(files[0])
        let i
        do { i = Math.floor(Math.random() * files.length) } while (i === currentIndex)
        set(files[i])
    }

    Component.onCompleted: { query.running = true; reload() }

    // what awww shows now: "<output>: WxH, scale: 1, currently displaying: image: /path"
    Process {
        id: query
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/image:\s*(.+)$/m)
                if (m && root.current === "") root.current = m[1].trim()
                root.queried = true
                root.firstWallpaper()
                root.applySaver()
            }
        }
    }

    Process {
        id: lister
        // each folder, then the island's own; a missing folder is only skipped
        command: ["find", "-L"].concat(root.folders, [root.shipped, "-maxdepth", "1", "-type", "f", "(",
                  "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
                  "-iname", "*.webp", "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", ")", "-printf", "%s\t%p\n"])
        stdout: StdioCollector {
            onStreamFinished: {
                // A copy (same name and size) is the same picture, listed once: the first folder's, so
                // yours rather than the island's.
                const seen = {}, out = []
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab < 0) continue
                    const path = line.slice(tab + 1), key = line.slice(0, tab) + "/" + root.baseName(path)
                    if (!seen[key]) { seen[key] = true; out.push(path) }
                }
                root.files = out.sort((a, b) => root.baseName(a).localeCompare(root.baseName(b)))
                root.listed = true
                root.firstWallpaper()
                root.applySaver()
            }
        }
    }

    IpcHandler {
        target: "wallpaper"

        function next(): void    { root.step(1) }
        function prev(): void    { root.step(-1) }
        function random(): void  { root.random() }
        function reload(): void  { root.reload() }
        function set(path: string): void { root.set(path) }
        function current(): string { return root.current }
    }
}
