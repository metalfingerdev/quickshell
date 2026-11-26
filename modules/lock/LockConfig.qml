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
	readonly property string defaultImage: saving ? Quickshell.shellPath("assets/wallpapers/lockscreen.jpg") : Quickshell.shellPath("assets/wallpapers/lockscreen.gif")
	readonly property string defaultAvatar: Quickshell.shellPath("assets/avatar.gif")

	property string image: ""
	// shown instead of the background on battery saver; "" leaves the background as it is
	property string imageStill: ""
	readonly property bool saving: Toggles.profile === "power-saver"
	readonly property string chosen: saving && imageStill !== "" ? imageStill : image
	property string avatar: ""
	property string avatarShape: "circle"
	property string name: ""
	property string info: ""
	// how far the picture softens behind the sign-in: 0 not at all .. 1 (Settings' Lock)
	property real blur: 1

	property Store store: Store {
		category: "lock"
		property alias image: root.image
		property alias imageStill: root.imageStill
		property alias avatar: root.avatar
		property alias avatarShape: root.avatarShape
		property alias name: root.name
		property alias info: root.info
		property alias blur: root.blur
	}

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
