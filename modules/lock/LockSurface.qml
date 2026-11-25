import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.modules.components
import qs.modules.services

// After Apple's: the picture and the time, nothing else, until a key or the pointer wants in; then the
// picture softens and the sign-in comes up. What it shows comes from LockConfig and what's typed from
// the LockContext, so every screen matches.
Rectangle {
	id: root
	required property LockContext context
	// an animated background or avatar plays while this is on (Lock.qml: not while the screens are off)
	property bool animate: true

	readonly property bool awake: context.awake
	property real veil: awake ? 1 : 0
	Behavior on veil { NumberAnimation { duration: Config.motionMs } }

	// a shadow, not a backing: the words stay readable on a bright picture and cover none of it
	component Lifted: MultiEffect {
		shadowEnabled: true
		shadowColor: "#000000"
		shadowOpacity: 0.6
		shadowBlur: 0.6
		shadowVerticalOffset: 1
		shadowHorizontalOffset: 0
		blurMax: 24
	}

	// The island's black: the lock comes in over the island that covered the screen, and leaves back
	// to it (Lock.qml). It stays for good if there is no picture.
	color: Config.dynamicSurface

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}

	// Under everything. Only a real move wakes it: Qt re-sends hover while something animates under a
	// still pointer, and the picture fading in would wake the sign-in by itself.
	MouseArea {
		anchors.fill: parent
		hoverEnabled: true
		property point from: Qt.point(-1, -1)
		onPositionChanged: mouse => {
			if (from.x < 0) { from = Qt.point(mouse.x, mouse.y); return; }
			if (Math.abs(mouse.x - from.x) + Math.abs(mouse.y - from.y) < 6) return;
			from = Qt.point(mouse.x, mouse.y);
			root.context.wake();
		}
		onPressed: root.context.wake();
	}

	Item {
		anchors.fill: parent
		opacity: root.context.leaving ? 0 : 1
		Behavior on opacity { NumberAnimation { duration: Config.motionMs } }

		AnimatedImage {
			id: background
			// the lock image, or the wallpaper if there is none or it can't be loaded (it moved, say)
			property string broken: ""
			readonly property string path: LockConfig.image !== "" && LockConfig.image !== broken ? LockConfig.image : Wallpaper.current

			anchors.fill: parent
			source: path ? Wallpaper.fileUrl(path) : ""
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
			// as the avatar's below; no sourceSize, which would rescale every frame of a GIF on the CPU
			playing: root.animate && status === Image.Ready
			cache: false
			opacity: status === Image.Ready ? 1 : 0
			// not right away: a missing file errors while `source` is being set, from `path`'s own binding
			onStatusChanged: if (status === Image.Error) Qt.callLater(() => broken = LockConfig.image);
			Behavior on opacity { NumberAnimation { duration: Config.motionMs } }

			// awake, it softens and dims behind the sign-in; at rest no effect runs at all
			layer.enabled: root.veil > 0
			layer.effect: MultiEffect {
				blurEnabled: true
				blur: root.veil
				blurMax: 64
				brightness: -0.18 * root.veil
			}
		}

		Column {
			anchors {
				horizontalCenter: parent.horizontalCenter
				top: parent.top
				topMargin: parent.height * 0.08
			}
			layer.enabled: true
			layer.effect: Lifted {}

			Label {
				anchors.horizontalCenter: parent.horizontalCenter
				text: Qt.formatDateTime(clock.date, "dddd d MMMM")
				color: Config.dynamicInk
				font.pixelSize: Config.title
				font.weight: Font.DemiBold
			}
			Label {
				anchors.horizontalCenter: parent.horizontalCenter
				text: Qt.formatDateTime(clock.date, "HH:mm")
				color: Config.dynamicInk
				// Qt's default text renderer looks rough this big
				renderType: Text.NativeRendering
				font.pixelSize: Config.display * 2.5
				font.weight: Font.DemiBold
				font.features: { "tnum": 1 }
			}
		}

		// Never hidden, only see-through: an invisible field can't hold the focus, and the first key
		// typed at rest should already be the password's.
		Column {
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				bottomMargin: parent.height * 0.1
			}
			spacing: Config.spaceM
			opacity: root.veil
			transform: Translate { y: (1 - root.veil) * Config.spaceXl }

			ClippingRectangle {
				anchors.horizontalCenter: parent.horizontalCenter
				width: 96
				height: 96
				radius: LockConfig.avatarShape === "square" ? Config.innerRadius : width / 2
				color: Config.high

				AnimatedImage {
					id: avatar
					anchors.fill: parent
					source: LockConfig.avatar ? Wallpaper.fileUrl(LockConfig.avatar) : ""
					fillMode: Image.PreserveAspectCrop
					asynchronous: true
					// It turns itself off for a still picture and wouldn't start the next GIF: the status
					// makes this say it again after every load.
					playing: root.animate && root.awake && status === Image.Ready
					cache: false                 // a long GIF would keep every frame in memory
				}

				Icon {
					anchors.centerIn: parent
					visible: avatar.status !== Image.Ready
					name: "person"
					size: 56
					filled: true
					color: Config.dim
					// Qt's default renderer garbles a filled Material Symbol this big
					renderType: Text.NativeRendering
				}
			}

			Column {
				anchors.horizontalCenter: parent.horizontalCenter
				layer.enabled: true
				layer.effect: Lifted {}

				Label {
					anchors.horizontalCenter: parent.horizontalCenter
					width: Math.min(implicitWidth, 480)
					elide: Text.ElideRight
					text: LockConfig.shownName
					color: Config.dynamicInk
					font.pixelSize: Config.large
					font.weight: Font.DemiBold
				}
				Label {
					anchors.horizontalCenter: parent.horizontalCenter
					visible: text !== ""
					width: Math.min(implicitWidth, 480)
					elide: Text.ElideRight
					text: LockConfig.shownInfo
					color: Config.dynamicDim
				}
			}

			SearchBar {
				id: passwordBox
				anchors.horizontalCenter: parent.horizontalCenter
				width: 320
				height: 48
				icon: ""
				placeholder: "Enter Password"
				fill: Qt.rgba(Config.dynamicInk.r, Config.dynamicInk.g, Config.dynamicInk.b, 0.18)
				focus: true
				enabled: !root.context.unlockInProgress
				field.echoMode: TextInput.Password
				field.inputMethodHints: Qt.ImhSensitiveData
				transform: Translate { id: nudge }

				onKey: root.context.wake();
				onTextChanged: root.context.currentText = text;
				onAccepted: root.context.tryUnlock();
				// Escape lets it rest, as Apple's does
				onEscaped: { root.context.currentText = ""; root.context.awake = false; }

				Pill {
					visible: root.context.currentText !== ""
					implicitHeight: 36
					icon: "arrow_forward"
					kind: "filled"
					activeFocusOnTab: false
					onClicked: root.context.tryUnlock();
				}
			}

			// always takes its place, so nothing above jumps when it shows
			Label {
				anchors.horizontalCenter: parent.horizontalCenter
				text: root.context.unlockInProgress ? "Checking…" : "Incorrect password"
				opacity: root.context.unlockInProgress || root.context.showFailure ? 1 : 0
				color: root.context.unlockInProgress ? Config.dynamicDim : Config.bad
				font.weight: Font.Medium
				layer.enabled: true
				layer.effect: Lifted {}
			}
		}
	}

	SequentialAnimation {
		id: shake
		NumberAnimation { target: nudge; property: "x"; to: -12; duration: 50 }
		NumberAnimation { target: nudge; property: "x"; to: 10; duration: 70 }
		NumberAnimation { target: nudge; property: "x"; to: -6; duration: 60 }
		NumberAnimation { target: nudge; property: "x"; to: 0; duration: 50 }
	}

	Connections {
		target: LockConfig

		function onImageChanged() {
			background.broken = "";
		}
	}

	Connections {
		target: root.context

		// Update the text in the box to match the text in the context.
		// This makes sure multiple monitors have the same text.
		function onCurrentTextChanged() {
			passwordBox.text = root.context.currentText;
		}

		function onShowFailureChanged() {
			if (root.context.showFailure) shake.restart();
		}
	}
}
