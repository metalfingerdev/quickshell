pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components

// Everything the launcher's Emoji filter offers: Unicode's own list of emoji (emoji-test.txt, from
// nixpkgs' unicode-emoji: names and groups, no skin-tone copies), then the characters a keyboard
// hasn't got (dashes, arrows, maths, currency, quotes, keys) and kaomoji. Each is { glyph, name, group, keys }.
Singleton {
    id: root

    // newer than this, and Noto Color Emoji may draw a box instead
    readonly property real newest: 16.0

    property var emoji: []
    readonly property var all: emoji.concat(characters, kaomoji)
    readonly property bool ready: emoji.length > 0

    // the last ones picked, newest first
    property string recentText: ""
    readonly property var recent: recentText === "" ? [] : recentText.split("\u001f")
    property Store store: Store {
        category: "emoji"
        property alias recent: root.recentText
    }
    function remember(glyph) {
        recentText = [glyph].concat(recent.filter(g => g !== glyph)).slice(0, 24).join("\u001f")
    }

    // Every word of the query has to match: the start of a word of the name scores most, inside the
    // name less, the group's words least. Nothing typed: the recent ones, then everything in order.
    function search(query) {
        const words = query.toLowerCase().split(/\s+/).filter(w => w !== "")
        if (words.length === 0) {
            const firsts = recent.map(g => all.find(e => e.glyph === g)).filter(e => e)
            return firsts.concat(all.filter(e => !recent.includes(e.glyph)))
        }
        const scored = []
        for (const e of all) {
            const name = e.name.toLowerCase(), parts = name.split(/[\s\-:,.()]+/)
            let score = 0
            for (const w of words) {
                const s = name.startsWith(w) ? 4 : parts.some(p => p.startsWith(w)) ? 3 : name.includes(w) ? 2
                        : e.keys.includes(w) ? 1 : 0
                if (s === 0) { score = 0; break }
                score += s
            }
            if (score > 0) scored.push({ e: e, score: score + (recent.includes(e.glyph) ? 2 : 0) })
        }
        return scored.sort((a, b) => b.score - a.score || a.e.name.length - b.e.name.length).map(s => s.e)
    }

    // emoji-test.txt: "# group: …", "# subgroup: …", then "1F600 ; fully-qualified # 😀 E1.0 grinning face"
    function parse(text) {
        const out = []
        let group = "", subgroup = ""
        for (const line of text.split("\n")) {
            if (line.startsWith("# group: ")) { group = line.slice(9).trim(); continue }
            if (line.startsWith("# subgroup: ")) { subgroup = line.slice(12).trim().replace(/-/g, " "); continue }
            const m = line.match(/;\s*fully-qualified\s*#\s*(\S+)\s+E(\d+\.\d+)\s+(.+)$/)
            if (!m || group === "Component" || Number(m[2]) > newest || m[3].includes("skin tone")) continue
            out.push({ glyph: m[1], name: m[3].trim(), group: group, keys: (group + " " + subgroup).toLowerCase() })
        }
        return out
    }

    Process {
        running: true
        command: ["sh", "-c", "IFS=:; for d in ${XDG_DATA_DIRS:-} /etc/profiles/per-user/$USER/share /run/current-system/sw/share; do "
                            + "f=\"$d/unicode/emoji/emoji-test.txt\"; [ -f \"$f\" ] && { printf '%s' \"$f\"; exit 0; }; done"]
        stdout: StdioCollector { onStreamFinished: list.path = text.trim() }
    }
    FileView {
        id: list
        printErrors: false
        onLoaded: root.emoji = root.parse(text())
    }

    function make(group, pairs) { return pairs.map(p => ({ glyph: p[0], name: p[1], group: group, keys: group.toLowerCase() })) }

    readonly property var characters: make("Characters", [
        ["—", "em dash"], ["–", "en dash"], ["…", "ellipsis dots"], ["•", "bullet"], ["·", "middle dot"],
        ["→", "arrow right"], ["←", "arrow left"], ["↑", "arrow up"], ["↓", "arrow down"], ["↔", "arrow left right"],
        ["⇒", "double arrow right implies"], ["⇐", "double arrow left"], ["↵", "return arrow"],
        ["✓", "check mark tick"], ["✗", "cross mark x"], ["×", "multiply times"], ["÷", "divide"], ["±", "plus minus"],
        ["≈", "approximately"], ["≠", "not equal"], ["≤", "less than or equal"], ["≥", "greater than or equal"],
        ["∞", "infinity"], ["°", "degree"], ["√", "square root"], ["π", "pi"], ["∆", "delta"], ["∑", "sum sigma"],
        ["µ", "micro mu"], ["Ω", "omega ohm"], ["½", "one half"], ["¼", "one quarter"], ["¾", "three quarters"],
        ["²", "squared superscript two"], ["³", "cubed superscript three"],
        ["₹", "rupee"], ["€", "euro"], ["£", "pound sterling"], ["¥", "yen"], ["¢", "cent"],
        ["©", "copyright"], ["®", "registered"], ["™", "trademark"], ["§", "section"], ["¶", "pilcrow paragraph"],
        ["†", "dagger"], ["“", "quote left double"], ["”", "quote right double"], ["‘", "quote left single"],
        ["’", "apostrophe quote right single"], ["«", "guillemet left"], ["»", "guillemet right"],
        ["¿", "inverted question mark"], ["¡", "inverted exclamation mark"],
        ["⌘", "command key cmd"], ["⌥", "option key alt"], ["⇧", "shift key"], ["⌫", "backspace key"],
        ["⏎", "return key enter"], ["★", "star black"], ["☆", "star white"], ["♪", "music note"], ["☐", "ballot box"],
        ["☑", "ballot box check"]
    ])

    readonly property var kaomoji: make("Kaomoji", [
        ["¯\\_(ツ)_/¯", "shrug"], ["(╯°□°)╯︵ ┻━┻", "table flip angry"], ["┬─┬ノ( º _ ºノ)", "table back calm"],
        ["( ͡° ͜ʖ ͡°)", "lenny face"], ["ಠ_ಠ", "look of disapproval"], ["(•_•)", "neutral stare"],
        ["( •_•)>⌐■-■", "deal with it sunglasses"], ["ʕ•ᴥ•ʔ", "bear"], ["♥‿♥", "love eyes"],
        ["(づ｡◕‿‿◕｡)づ", "hug"], ["ᕕ( ᐛ )ᕗ", "happy walk"], ["(ง'̀-'́)ง", "fight"], ["(｡•́︿•̀｡)", "sad"],
        ["(ಥ﹏ಥ)", "cry tears"], ["٩(◕‿◕)۶", "joy happy"], ["(☞ﾟヮﾟ)☞", "point you"], ["(－‸ლ)", "facepalm"],
        ["┐(￣ヘ￣)┌", "whatever"], ["(￣▽￣)ノ", "wave hi"], ["(＾▽＾)", "smile grin"]
    ])
}
