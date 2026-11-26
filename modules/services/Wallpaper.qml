pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components

// awww restores the last wallpaper by itself, so at startup this only asks it what is showing.
Singleton {
    id: root

    property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
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

    // The pictures that come with the island, listed beside `dir`. shellPath keeps ~/.config/quickshell, a
    // link that follows rebuilds, where a store path would be gone after the next garbage collection.
    readonly property string shipped: Quickshell.shellPath("assets/wallpapers")
    // Settings → Wallpaper: the wallpaper a first login gets and battery saver swaps; "" = the shipped one
    property string basePath: ""
    property string stillPath: ""
    readonly property string base: basePath || shipped + "/wallpaper.gif"
    readonly property string still: stillPath || shipped + "/wallpaper.jpg"

    property Store store: Store {
        category: "wallpaper"
        property alias basePath: root.basePath
        property alias stillPath: root.stillPath
        property alias pickedIndex: root.pickedIndex
        property alias pickedFor: root.pickedFor
    }

    function fileUrl(p) { return "file://" + p.split("/").map(encodeURIComponent).join("/") }
    function baseName(p) { return p ? p.split("/").pop() : "" }

    function reload() { lister.running = true }

    // Says what's wrong ("" = fine). Choosing the base also shows it, and clearing it brings the shipped one back.
    function setPicture(key, path) {
        if (path !== "" && !path.startsWith("/")) return `not an absolute path: ${path}`
        root[key + "Path"] = path
        if (key === "base") set(base)
        else applySaver()
        return ""
    }

    // First login: awww has nothing to restore, so the base is set once both the query and the listing are
    // done and nothing shows.
    property bool queried: false
    property bool listed: false
    function firstWallpaper() {
        if (queried && listed && current === "" && base && (basePath !== "" || files.includes(base))) { set(base); applySaver() }
    }

    // Battery saver: awww keeps decoding an animated GIF's frames, so the base wallpaper is shown as its
    // still meanwhile, and comes back when the profile leaves power-saver. A wallpaper picked from the
    // list is left alone.
    readonly property bool saving: Toggles.profile === "power-saver"
    property string animated: ""
    function applySaver() {
        if (!still) return
        if (saving) {
            if (current === base) { const gif = current; set(still); animated = gif }
        } else if (animated !== "") {
            set(animated)
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
        command: ["find", "-L", root.dir, root.shipped, "-maxdepth", "1", "-type", "f", "(",
                  "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
                  "-iname", "*.webp", "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(s => s.length > 0).sort((a, b) => a.localeCompare(b))
                root.listed = true
                root.firstWallpaper()
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
