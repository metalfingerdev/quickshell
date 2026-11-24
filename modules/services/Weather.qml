pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components
import "OpenMeteo.js" as OpenMeteo

// The weather at one place, from Open-Meteo (no key, no account): every half hour once a place is
// set, and again when the network comes back after a read that failed. Only the place's coordinates
// go out. Set by name with `qs ipc call weather place Mumbai` (Open-Meteo's search finds it), and
// forgotten with an empty one. From Nihil-Shell's Weather (MIT: nixos-dotfiles,
// modules/features/nilo-agent/LICENSE), now ours.
Singleton {
    id: root

    property string name: ""        // "" = no place
    property string label: ""       // with its region and country
    property real lat: 0
    property real lon: 0
    Store {
        category: "weather"
        property alias name: root.name
        property alias label: root.label
        property alias lat: root.lat
        property alias lon: root.lon
    }
    readonly property bool placed: name !== ""
    readonly property string spot: placed ? lat + "," + lon : ""

    // what was last read, and where: { now: { temp, feels, code, day }, days: [{ date, code, max, min }] }
    property var forecast: null
    property string of: ""
    property bool failed: false
    readonly property bool current: forecast !== null && of === spot
    property string searching: ""
    property string notFound: ""

    readonly property var skies: ({
        clear: "Clear", fewClouds: "Mostly clear", partly: "Partly cloudy", cloudy: "Cloudy", fog: "Fog",
        drizzle: "Drizzle", rain: "Rain", showers: "Showers", snow: "Snow", storm: "Thunderstorm"
    })
    function skyName(code) { return skies[OpenMeteo.sky(code)] ?? "" }
    function icon(code, day) {
        return ({
            clear: day ? "sunny" : "clear_night",
            fewClouds: day ? "partly_cloudy_day" : "partly_cloudy_night",
            partly: day ? "partly_cloudy_day" : "partly_cloudy_night",
            cloudy: "cloud", fog: "foggy", drizzle: "rainy", rain: "rainy", showers: "rainy",
            snow: "weather_snowy", storm: "thunderstorm"
        })[OpenMeteo.sky(code)] ?? "cloud"
    }
    // 14°, -3°: whole degrees, and no minus for what rounds to nothing
    function degrees(value) { return (Math.round(value) || 0) + "°" }

    function read() {
        if (!placed || page.running) return
        page.asked = spot
        page.command = ["curl", "-sS", "--max-time", "20", "--proto", "=https", "-w", "\n%{http_code}",
                        OpenMeteo.forecastUrl(lat, lon)]
        page.running = true
    }

    function search(text) {
        const wanted = text.trim()
        notFound = ""
        if (wanted === "") {
            name = ""
            label = ""
            forecast = null
            return
        }
        if (finder.running) return
        searching = wanted
        finder.command = ["curl", "-sS", "--max-time", "20", "--proto", "=https", "-w", "\n%{http_code}",
                          OpenMeteo.searchUrl(wanted, "en")]
        finder.running = true
    }

    onSpotChanged: read()
    Component.onCompleted: read()

    Timer {
        interval: 30 * 60 * 1000
        running: root.placed
        repeat: true
        onTriggered: root.read()
    }
    Timer {
        id: retry
        interval: 10 * 60 * 1000
        onTriggered: root.read()
    }
    // a place changed while the last one read is read next
    Timer {
        id: again
        interval: 50
        onTriggered: page.running ? again.restart() : root.read()
    }

    Connections {
        target: Net
        function onCurrentChanged() { if (root.failed) root.read() }
        function onEthernetChanged() { if (root.failed) root.read() }
    }

    Process {
        id: page
        property string asked: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const got = OpenMeteo.answer(text)
                const read = got.status === "200" ? OpenMeteo.forecast(got.body) : null
                if (read === null) {
                    root.failed = true
                    retry.restart()
                } else {
                    root.forecast = read
                    root.of = page.asked
                    root.failed = false
                }
                if (page.asked !== root.spot) again.restart()
            }
        }
    }

    Process {
        id: finder
        stdout: StdioCollector {
            onStreamFinished: {
                const got = OpenMeteo.answer(text)
                const found = got.status === "200" ? OpenMeteo.place(got.body) : null
                if (found !== null) {
                    root.lat = found.lat
                    root.lon = found.lon
                    root.label = found.label
                    root.name = found.name
                } else {
                    root.notFound = root.searching
                }
                root.searching = ""
            }
        }
    }

    IpcHandler {
        target: "weather"

        function place(name: string): void { root.search(name) }
        function read(): void              { root.read() }
        function status(): string {
            return JSON.stringify({ place: root.label, notFound: root.notFound, failed: root.failed,
                                    now: root.current ? root.forecast.now : null })
        }
    }
}
