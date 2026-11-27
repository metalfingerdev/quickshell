pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components
import qs.modules.services

// "" means the default: the shipped picture and avatar (assets/), the full name in passwd, user@host.
Singleton {
	id: root

	// Shipped with the island (assets/): shown when you've set none or yours doesn't load. On battery saver the
	// background is its still, as the wallpaper is; the avatar keeps playing.
	readonly property string defaultImage: saving ? Quickshell.shellPath("assets/wallpapers/lockscreen.webp") : Quickshell.shellPath("assets/wallpapers/lockscreen.gif")
	readonly property string defaultAvatar: Quickshell.shellPath("assets/avatar.gif")

	property string image: ""
	// On battery saver a GIF background shows its still, as the wallpaper does: the same name as .jpg, .png
	// or .webp beside it, wherever it is.
	readonly property bool saving: Toggles.profile === "power-saver"
	property string still: ""
	readonly property string chosen: saving && still !== "" ? still : image
	onImageChanged: lookForStill()
	Component.onCompleted: lookForStill()
	function lookForStill() {
		still = ""
		if (!/\.gif$/i.test(image)) return
		// set here, not bound: a binding on `image` may not have caught up when imageChanged runs this
		stillFinder.command = ["sh", "-c", Wallpaper.stillScript, "sh", image]
		stillFinder.running = false
		stillFinder.running = true
	}
	Process {
		id: stillFinder
		stdout: StdioCollector { onStreamFinished: root.still = text.trim() }
	}
	property string avatar: ""
	// The login screen's own pictures ("" = the shipped ones). It runs as another user that can't read your
	// home, so a chosen picture is copied to greeterDir (see sync); it falls back to the shipped one if
	// the copy is missing or won't load.
	property string greeterImage: ""
	property string greeterAvatar: ""
	property string avatarShape: "circle"
	property string name: ""
	property string info: ""
	// how far the picture softens behind the sign-in: 0 not at all .. 1 (Settings' Lock)
	property real blur: 1

	property Store store: Store {
		category: "lock"
		property alias image: root.image
		property alias avatar: root.avatar
		property alias greeterImage: root.greeterImage
		property alias greeterAvatar: root.greeterAvatar
		property alias avatarShape: root.avatarShape
		property alias name: root.name
		property alias info: root.info
		property alias blur: root.blur
	}

	// Where the greeter reads from: made for you by features/island-greeter (tmpfiles), so no root is needed.
	readonly property string greeterDir: "/var/lib/island-greeter"
	property bool greeterAvailable: false
	Process {
		command: ["test", "-w", root.greeterDir]
		running: true
		onExited: code => root.greeterAvailable = code === 0
	}
	function ext(path) { return (path.split(".").pop().replace(/[^A-Za-z0-9]/g, "") || "img").toLowerCase() }
	// The files, then config.json saying which to show (and the name, shape and softness, which are the
	// lock's own). The names carry the extension so the greeter picks the decoder; stale ones go first.
	function sync() {
		if (!greeterAvailable) return
		const bg = greeterImage !== "" ? "background." + ext(greeterImage) : ""
		const av = greeterAvatar !== "" ? "avatar." + ext(greeterAvatar) : ""
		const json = JSON.stringify({ background: bg, avatar: av, shape: avatarShape, name: shownName, blur: blur })
		syncer.command = ["sh", "-c",
			'd=$1; shift; rm -f "$d"/background.* "$d"/avatar.*; [ -n "$3" ] && cp -- "$3" "$d/$1"; [ -n "$4" ] && cp -- "$4" "$d/$2"; '
			+ 'printf %s "$5" > "$d/config.json.tmp" && mv -f "$d/config.json.tmp" "$d/config.json"; chmod a+r "$d"/* 2>/dev/null; true',
			"sh", greeterDir, bg, av, greeterImage, greeterAvatar, json]
		syncer.running = false
		syncer.running = true
	}
	Process { id: syncer }
	Timer { id: syncSoon; interval: 600; onTriggered: root.sync() }
	onGreeterImageChanged: syncSoon.restart()
	onGreeterAvatarChanged: syncSoon.restart()
	onAvatarShapeChanged: syncSoon.restart()
	onBlurChanged: syncSoon.restart()
	onNameChanged: syncSoon.restart()
	onGreeterAvailableChanged: if (greeterAvailable) syncSoon.restart()

	readonly property string user: Quickshell.env("USER") ?? ""
	property string fullName: ""
	property string host: ""
	readonly property string defaultInfo: host ? `${user}@${host}` : user
	readonly property string shownName: name || fullName || user
	readonly property string shownInfo: info || defaultInfo

	// Says what's wrong ("" = fine). A relative path can't work: neither IPC nor a text field has a
	// directory to resolve it against.
	function setPicture(key, path) {
		if (path !== "" && !path.startsWith("/")) return `not an absolute path: ${path}`;
		root[key] = path;
		return "";
	}

	// user:x:uid:gid:Full Name,office,...:home:shell
	Process {
		command: ["getent", "passwd", root.user]
		running: root.user !== ""
		stdout: StdioCollector {
			onStreamFinished: root.fullName = (text.split(":")[4] ?? "").split(",")[0];
		}
	}

	FileView {
		path: "/proc/sys/kernel/hostname"
		printErrors: false
		onLoaded: root.host = text().trim();
	}
}
