// Self-check for the position merge rule: bun booksync.test.js
//
// The middle case is the one that matters — two positions a few pages apart
// that round to the same reading percentage. The old percentage-based merge
// compared them equal and silently discarded the advance.

import { ahead } from "./booksync.js";
import { strict as assert } from "assert";

const base = [4, 12, 0, 8210];

assert.equal(ahead([4, 12, 0, 8400], base), true, "further into same paragraph wins");
assert.equal(ahead([4, 12, 0, 8100], base), false, "behind in same paragraph loses");
assert.equal(ahead(base, base), false, "identical is not ahead (no pointless write)");

assert.equal(ahead([5, 0, 0, 0], base), true, "later chapter wins outright");
assert.equal(ahead([3, 999, 9, 99999], base), false, "earlier chapter loses outright");

assert.equal(ahead([4, 13, 0, 0], base), true, "later paragraph beats larger text_offset");
assert.equal(ahead([4, 12, 1, 8210], base), true, "later line within paragraph wins");

// A wiped card must get its reading positions back with the books.
// Regression: reply.pos was built from `have` alone, which is empty on a fresh
// card, so a restored device started every book at page one.
{
  const { mkdirSync, writeFileSync, readFileSync, rmSync } = await import("fs");
  const ROOT = "/tmp/booksync-freshcard-test";
  rmSync(ROOT, { recursive: true, force: true });
  for (const b of ["alice in wonderland", "the hobbit"]) {
    mkdirSync(`${ROOT}/.compiled/${b}`, { recursive: true });
    writeFileSync(`${ROOT}/.compiled/${b}/book.wgb`, "WGB2");
  }
  writeFileSync(`${ROOT}/.sync.json`, JSON.stringify({
    pos: { "alice in wonderland": [7, 21, 0, 0], "the hobbit": [1, 66, 13, 398] },
    finished: [],
  }));
  const src = readFileSync(new URL("./booksync.js", import.meta.url), "utf8")
    .replaceAll('"/media/books"', JSON.stringify(ROOT));
  writeFileSync(`${ROOT}/mod.js`, src);
  const { handleSync } = await import(`${ROOT}/mod.js`);

  const fresh = await (await handleSync(new Request("http://x/booksync", {
    method: "POST", body: JSON.stringify({ have: [], pos: {}, done: [] }),
  }))).json();
  assert.equal(fresh.get.length, 2, "fresh card downloads both books");
  assert.deepEqual(fresh.pos["alice in wonderland"], [7, 21, 0, 0],
    "position comes back for a book being downloaded");
  assert.deepEqual(fresh.pos["the hobbit"], [1, 66, 13, 398]);

  // Steady state still sends nothing when the two sides agree.
  const level = await (await handleSync(new Request("http://x/booksync", {
    method: "POST",
    body: JSON.stringify({ have: ["the hobbit"], pos: { "the hobbit": [1, 66, 13, 398] }, done: [] }),
  }))).json();
  assert.equal(level.pos["the hobbit"], undefined, "no wasted bytes when level");
  rmSync(ROOT, { recursive: true, force: true });
}

console.log("ok");
