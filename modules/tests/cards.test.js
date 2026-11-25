// Run: node modules/tests/cards.test.js
const assert = require("assert")
const { load, test } = require("./harness")
const C = load("services/Cards.js")

const board = [{ id: "a", text: "A", column: 0 }, { id: "b", text: "B", column: 1 }, { id: "c", text: "C", column: 0 },
               { id: "d", text: "D", column: 2 }]
const ids = cards => cards.map(c => c.id).join("")

test("a hand-edited file is read as far as it makes sense", () => {
    const got = C.read(JSON.stringify({ cards: [{ id: "x", text: " Buy milk ", column: 7 }, { text: "No id" }, { id: "x", text: "Again" },
                                               { id: "y", text: "  " }, { id: "z", column: 1 }] }))
    assert.deepStrictEqual(got, [{ id: "x", text: "Buy milk", column: 2 }, { id: "card1", text: "No id", column: 0 }])
    assert.deepStrictEqual(C.read("[{\"id\":\"q\",\"text\":\"Q\",\"column\":1}]"), [{ id: "q", text: "Q", column: 1 }])
    assert.deepStrictEqual(C.read("not json"), [])
})
test("what is saved reads back the same", () => {
    assert.deepStrictEqual(C.read(C.save(board)), board)
})
test("a new card goes on top of To do; an empty one is no card", () => {
    assert.strictEqual(ids(C.add(board, " New ", "n")), "nabcd")
    assert.strictEqual(C.add(board, "  ", "n"), board)
})
test("an edit to nothing removes the card", () => {
    assert.strictEqual(C.edit(board, "a", "A2")[0].text, "A2")
    assert.strictEqual(ids(C.edit(board, "a", "")), "bcd")
})
test("a card moved goes to the bottom of its new column, and nowhere past the ends", () => {
    const moved = C.move(board, "a", 1)
    assert.strictEqual(ids(C.column(moved, 1)), "ba")
    assert.strictEqual(C.move(board, "a", 0), board)
    assert.strictEqual(C.move(board, "d", 5).find(c => c.id === "d").column, 2)
})
test("shifting swaps with the neighbour in the same column only", () => {
    assert.strictEqual(ids(C.shift(board, "c", -1)), "cbad")
    assert.strictEqual(C.shift(board, "a", -1), board)
    assert.strictEqual(C.shift(board, "b", 1), board)
})
test("clearing Done leaves the rest as it was", () => {
    assert.strictEqual(ids(C.clearDone(board)), "abc")
})
