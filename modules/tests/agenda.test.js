// Run: node modules/tests/agenda.test.js
// On a clock with summer time: the days that change it are where day counts go wrong.
process.env.TZ = "Europe/London"
const assert = require("assert")
const { load, test } = require("./harness")
const A = load("services/Agenda.js")

const at = (y, m, d, h = 0, min = 0) => new Date(y, m, d, h, min).getTime() / 1000
const ev = (title, start, end) => ({ cal: "c", title, where: "", allDay: false, start, end })
const now = at(2026, 10, 19, 11)

test("a day past the month's end is the next month's midnight", () => {
    assert.strictEqual(A.midnight(2026, 10, 31), at(2026, 11, 1))
})
test("upcoming keeps what isn't over, under way first, and a moment still to come", () => {
    const events = [
        ev("Done", at(2026, 10, 19, 8), at(2026, 10, 19, 9)),
        ev("Lab", at(2026, 10, 19, 10), at(2026, 10, 19, 12)),
        ev("Reminder", at(2026, 10, 19, 18), at(2026, 10, 19, 18)),
        ev("Passed reminder", at(2026, 10, 19, 7), at(2026, 10, 19, 7)),
        ev("Tomorrow", at(2026, 10, 20, 9), at(2026, 10, 20, 10)),
    ]
    assert.deepStrictEqual(A.upcoming(events, now, 5).map(e => e.title), ["Lab", "Reminder", "Tomorrow"])
    assert.deepStrictEqual(A.upcoming(events, now, 1).map(e => e.title), ["Lab"])
    assert.deepStrictEqual(A.upcoming(null, now, 3), [])
})
test("days away counts calendar days, not 24-hour spans", () => {
    assert.strictEqual(A.daysAway(at(2026, 10, 19, 23, 59), now), 0)
    assert.strictEqual(A.daysAway(at(2026, 10, 20, 0, 1), at(2026, 10, 19, 23, 59)), 1)
    assert.strictEqual(A.daysAway(at(2026, 10, 18, 12), now), -1)
})
test("days away across the clocks going back stays whole", () => {
    // 25 October 2026: the UK leaves summer time, so that day is 25 hours long
    assert.strictEqual(A.daysAway(at(2026, 9, 26, 0, 30), at(2026, 9, 24, 23, 30)), 2)
})
