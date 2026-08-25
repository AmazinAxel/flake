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

console.log("ok");
