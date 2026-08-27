// Self-check for the sync negotiation: bun booksync.test.js
//
// The safety property is the ordering in step 1: a finished book is recorded in
// .sync.json (and fsynced) before anything is unlinked, so a crash can only
// ever leave the book still present.

import { strict as assert } from "assert";
import { mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from "fs";

const ROOT = "/tmp/booksync-test";
rmSync(ROOT, { recursive: true, force: true });
for (const b of ["alice in wonderland", "the hobbit"]) {
  mkdirSync(`${ROOT}/.compiled/${b}`, { recursive: true });
  writeFileSync(`${ROOT}/.compiled/${b}/book.wgb`, "WGB2");
}
const src = readFileSync(new URL("./booksync.js", import.meta.url), "utf8")
  .replaceAll('"/media/books"', JSON.stringify(ROOT));
writeFileSync(`${ROOT}/mod.js`, src);
const { handleSync } = await import(`${ROOT}/mod.js`);

const sync = async (body) =>
  (await handleSync(new Request("http://x/booksync", {
    method: "POST", body: JSON.stringify(body),
  }))).json();

// A fresh card is offered everything.
const fresh = await sync({ have: [], done: [] });
assert.deepEqual(fresh.get.sort(), ["alice in wonderland", "the hobbit"]);
assert.deepEqual(fresh.delete, []);

// Steady state offers nothing.
const level = await sync({ have: ["alice in wonderland", "the hobbit"], done: [] });
assert.deepEqual(level.get, [], "nothing new means nothing to download");

// A finished book is deleted and recorded in the read history.
const done = await sync({
  have: ["alice in wonderland", "the hobbit"],
  done: [{ dir: "the hobbit", title: "The Hobbit", author: "Tolkien" }],
});
assert.deepEqual(done.delete, ["the hobbit"], "server confirms before device unlinks");
assert.equal(done.get.includes("the hobbit"), false, "a retired book is not re-offered");
assert.equal(existsSync(`${ROOT}/.compiled/the hobbit`), false, "book removed on disk");
assert.deepEqual(
  JSON.parse(readFileSync(`${ROOT}/.sync.json`, "utf8")).finished.map((f) => f.title),
  ["The Hobbit"]);

// Reporting it again is idempotent — the device re-sends until a sync succeeds.
const again = await sync({ have: [], done: [{ dir: "the hobbit", title: "The Hobbit", author: "Tolkien" }] });
assert.deepEqual(again.delete, ["the hobbit"]);
assert.equal(
  JSON.parse(readFileSync(`${ROOT}/.sync.json`, "utf8")).finished.length, 1,
  "read history deduplicates on title|author");

// Path segments are validated: these names are used to build file paths.
const evil = await sync({ have: [], done: [{ dir: "../etc", title: "x" }] });
assert.deepEqual(evil.delete, [], "traversal rejected");

rmSync(ROOT, { recursive: true, force: true });
console.log("ok");
