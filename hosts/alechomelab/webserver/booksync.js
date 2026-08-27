// Book sync for the Xteink X4 running wintergreen.
//
// The device speaks HTTP rather than SMB: ESP-IDF ships no SMB client, and
// SMB3 (which this host pins) signs every packet, which costs radio-on time on
// a battery device. Samba stays for dropping EPUBs onto /media/books; the
// reader never touches it.
//
// One POST decides the whole sync, so a no-op costs a single round trip.
//
// Reading positions are not synced: the device keeps its own book.pos and this
// side never sees it. .sync.json holds only the append-only read history.

import { readdirSync, statSync, existsSync, rmSync, renameSync, writeFileSync, readFileSync, openSync, fsyncSync, closeSync } from "fs";

export const BOOKS = "/media/books";
export const COMPILED = `${BOOKS}/.compiled`;
const STATE = `${BOOKS}/.sync.json`;

// Book directory names are used as path segments, so they are validated rather
// than trusted. Anything with a slash or a dot-segment is rejected outright.
const SAFE = /^[A-Za-z0-9 ._-]+$/;
const safeName = (s) =>
  typeof s === "string" && s.length > 0 && s.length < 128 && SAFE.test(s) && !s.includes("..");

function load() {
  try {
    const s = JSON.parse(readFileSync(STATE, "utf8"));
    return { finished: s.finished ?? [] };
  } catch {
    return { finished: [] };
  }
}

// Atomic: a torn state file would lose the read history for the whole library.
// fsync before rename, because rename only orders the directory entry.
function save(state) {
  const tmp = `${STATE}.tmp`;
  writeFileSync(tmp, JSON.stringify(state));
  const fd = openSync(tmp, "r");
  fsyncSync(fd);
  closeSync(fd);
  renameSync(tmp, STATE);
}

const compiledBooks = () => {
  try {
    return readdirSync(COMPILED, { withFileTypes: true })
      .filter((e) => e.isDirectory() && existsSync(`${COMPILED}/${e.name}/book.wgb`))
      .map((e) => e.name);
  } catch {
    return [];
  }
};

export async function handleSync(req) {
  let body;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "bad json" }, { status: 400 });
  }

  const have = Array.isArray(body.have) ? body.have.filter(safeName) : [];
  const state = load();

  const reply = {};

  // 1. Retire finished books. The state write is fsynced *before* anything is
  // unlinked, so a crash can only ever leave the book still present — the
  // device likewise waits for `delete` before removing its own copy.
  const done = Array.isArray(body.done) ? body.done : [];
  const deleted = [];
  for (const d of done) {
    if (!d || !safeName(d.dir)) continue;
    const title = String(d.title ?? d.dir).slice(0, 200);
    const author = String(d.author ?? "").slice(0, 200);
    const key = `${title}|${author}`;
    if (!state.finished.some((f) => `${f.title}|${f.author}` === key))
      state.finished.push({ title, author, at: Math.floor(Date.now() / 1000) });
    deleted.push(d.dir);
  }

  if (deleted.length) save(state);

  for (const dir of deleted) {
    rmSync(`${COMPILED}/${dir}`, { recursive: true, force: true });
    for (const f of [`${BOOKS}/${dir}.epub`, `${BOOKS}/${dir}.EPUB`])
      if (existsSync(f)) rmSync(f, { force: true });
  }

  // 2. What the device is missing, and only that.
  const gone = new Set(deleted);
  reply.get = compiledBooks().filter((n) => !have.includes(n) && !gone.has(n));
  reply.delete = deleted;

  return Response.json(reply);
}

// GET /booksync/<dir>/<file> — one file out of a compiled book.
//
// The segments must be percent-decoded before validation: book names contain
// spaces, so the device sends "/booksync/the%20odyssey/book.wgb" and
// URL.pathname keeps the escape. Undecoded, safeName() rejected the "%" and
// every book file 404'd — and because the router falls through to the dashboard
// HTML, the device happily wrote *that* to the card as book.wgb.
//
// Decoding happens before validation, never after, so an encoded "..%2f" cannot
// slip a traversal past safeName().
export function handleBookFile(pathname) {
  let parts;
  try {
    parts = pathname.split("/").filter(Boolean).map(decodeURIComponent);
  } catch {
    return new Response("not found", { status: 404 });  // malformed escape
  }
  if (parts.length !== 3 || !safeName(parts[1]) || !safeName(parts[2]))
    return new Response("not found", { status: 404 });

  const path = `${COMPILED}/${parts[1]}/${parts[2]}`;
  try {
    if (!statSync(path).isFile()) return new Response("not found", { status: 404 });
  } catch {
    return new Response("not found", { status: 404 });
  }
  // Bun.file sets Content-Length, which the device's read loop needs.
  return new Response(Bun.file(path));
}
