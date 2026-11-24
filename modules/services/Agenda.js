.pragma library

// Events as the calendar reader keeps them ({ cal, title, where, allDay, start, end }, from the
// soonest, start and end in seconds), on this computer's clock. From Nihil-Shell's Agenda.js
// (MIT: nixos-dotfiles, modules/features/nilo-agent/LICENSE), now ours.

// Seconds at the midnight a day begins; a day past the month's end is the next month's.
function midnight(y, m, d) {
    return new Date(y, m, d).getTime() / 1000
}

// The next ones not over at `now` (seconds), those under way first, as they're kept.
function upcoming(events, now, count) {
    return (events ?? []).filter(event => event.end > now || (event.end === event.start && event.start >= now)).slice(0, count)
}

// How many days from `now`'s to the one a moment falls on: 0 today, 1 tomorrow, -1 yesterday.
function daysAway(seconds, now) {
    const a = new Date(seconds * 1000), b = new Date(now * 1000)
    return Math.round((midnight(a.getFullYear(), a.getMonth(), a.getDate()) - midnight(b.getFullYear(), b.getMonth(), b.getDate())) / 86400)
}
