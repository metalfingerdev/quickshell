// Run: node modules/tests/open-meteo.test.js
// After Nihil-Shell's own (MIT: nixos-dotfiles, modules/features/nilo-agent/LICENSE).
const assert = require("assert")
const { load, test } = require("./harness")
const O = load("services/OpenMeteo.js")

test("a place's name goes in the search whole, whatever it has in it", () => {
    assert.strictEqual(O.searchUrl("L'Hospitalet & co?", "en"),
        "https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&language=en&name=L'Hospitalet%20%26%20co%3F")
})
test("the forecast asks for a place to four decimals, on its own clock", () => {
    const url = O.forecastUrl(41.387917, -2.169919)
    assert.ok(url.startsWith("https://api.open-meteo.com/v1/forecast?latitude=41.3879&longitude=-2.1699&"), url)
    assert.ok(url.includes("timezone=auto"))
})
test("curl's answer splits into the body and the status", () => {
    assert.deepStrictEqual(O.answer('{"a":1}\n200'), { status: "200", body: '{"a":1}' })
    assert.deepStrictEqual(O.answer("\n000"), { status: "000", body: "" })
    assert.deepStrictEqual(O.answer(""), { status: "", body: "" })
})
test("the first place found, its label without repeats", () => {
    const text = JSON.stringify({ results: [
        { name: "Delhi", latitude: 28.651952, longitude: 77.231495, admin1: "Delhi", country: "India" },
        { name: "Delhi", latitude: 42.27, longitude: -74.91, country: "United States" }] })
    assert.deepStrictEqual(O.place(text), { name: "Delhi", label: "Delhi, India", lat: 28.652, lon: 77.2315 })
})
test("no place, or one without coordinates, is null", () => {
    assert.strictEqual(O.place('{"generationtime_ms":0.5}'), null)
    assert.strictEqual(O.place(JSON.stringify({ results: [{ name: "X", latitude: "1", longitude: 2 }] })), null)
    assert.strictEqual(O.place("not json"), null)
})
test("a forecast keeps only whole days, and feels falls back to the temperature", () => {
    const text = JSON.stringify({
        current: { temperature_2m: 21.4, weather_code: 3, is_day: 0 },
        daily: { time: ["2026-11-25", "2026-11-26", "bad"], weather_code: [3, 61, 0],
                 temperature_2m_max: [24, 22, 20], temperature_2m_min: [14, null, 10] } })
    assert.deepStrictEqual(O.forecast(text), {
        now: { temp: 21.4, feels: 21.4, code: 3, day: false },
        days: [{ date: "2026-11-25", code: 3, max: 24, min: 14 }] })
})
test("a forecast with no current weather is null", () => {
    assert.strictEqual(O.forecast(JSON.stringify({ daily: {} })), null)
    assert.strictEqual(O.forecast(JSON.stringify({ current: { temperature_2m: 20, weather_code: 1.5 } })), null)
})
test("WMO codes become skies, and an unknown one none", () => {
    const skies = [0, 1, 2, 3, 45, 53, 63, 81, 75, 86, 95, 4].map(O.sky)
    assert.deepStrictEqual(skies, ["clear", "fewClouds", "partly", "cloudy", "fog", "drizzle", "rain", "showers",
                                   "snow", "snow", "storm", ""])
})
