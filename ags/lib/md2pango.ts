// vibecoded by Claude
 
// ────────────────────────────────────────────────────────────
// XML Escaping
// ────────────────────────────────────────────────────────────
 
function esc(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/'/g, "&apos;")
    .replace(/"/g, "&quot;");
}
 
// ────────────────────────────────────────────────────────────
// Inline Parser
// ────────────────────────────────────────────────────────────
// Parses a single line of text and returns Pango markup.
// Handles: code spans, images, links, bold/italic/bold-italic,
// strikethrough, and bare URLs. Properly nests tags.
 
function parseInline(src: string): string {
  let out = "";
  let i = 0;
  const len = src.length;
 
  while (i < len) {
    // ── Code span (`...` or ``...``) ──
    if (src[i] === "`") {
      let ticks = 0;
      let j = i;
      while (j < len && src[j] === "`") { ticks++; j++; }
      const closer = "`".repeat(ticks);
      const closeIdx = src.indexOf(closer, j);
      if (closeIdx !== -1) {
        // Verify exact tick count (not part of a longer run)
        const afterClose = closeIdx + ticks;
        if (afterClose >= len || src[afterClose] !== "`") {
          const code = src.slice(j, closeIdx);
          // Trim single leading/trailing space per CommonMark
          const trimmed = (code.length > 1 && code[0] === " " && code[code.length - 1] === " ")
            ? code.slice(1, -1) : code;
          out += `<tt>${esc(trimmed)}</tt>`;
          i = afterClose;
          continue;
        }
      }
      // No valid close — emit literal backticks
      out += esc(closer);
      i = j;
      continue;
    }
 
    // ── Image: ![alt](url) ──
    if (src[i] === "!" && i + 1 < len && src[i + 1] === "[") {
      const result = parseLinkOrImage(src, i + 1);
      if (result) {
        out += `[${esc(result.text)}]`;
        i = result.end;
        continue;
      }
    }
 
    // ── Link: [text](url) ──
    if (src[i] === "[") {
      const result = parseLinkOrImage(src, i);
      if (result) {
        const inner = parseInline(result.text);
        out += `<a href="${esc(result.url)}">${inner}</a>`;
        i = result.end;
        continue;
      }
    }
 
    // ── Strikethrough: ~~text~~ ──
    if (src[i] === "~" && i + 1 < len && src[i + 1] === "~") {
      const closeIdx = src.indexOf("~~", i + 2);
      if (closeIdx !== -1 && closeIdx > i + 2) {
        const inner = src.slice(i + 2, closeIdx);
        out += `<s>${parseInline(inner)}</s>`;
        i = closeIdx + 2;
        continue;
      }
    }
 
    // ── Emphasis: ***, **, *, ___, __, _ ──
    if (src[i] === "*" || src[i] === "_") {
      const ch = src[i];
      let count = 0;
      let j = i;
      while (j < len && src[j] === ch) { count++; j++; }
 
      // Cap at 3 — more than 3 is treated as literal
      if (count > 3) {
        out += esc(ch.repeat(count));
        i = j;
        continue;
      }
 
      // For underscore, enforce CommonMark word-boundary rules:
      // - cannot open if preceded by alphanumeric
      // - cannot open if followed by whitespace
      if (ch === "_") {
        const before = i > 0 ? src[i - 1] : "";
        const after = j < len ? src[j] : "";
        const precededByAlnum = /\w/.test(before);
        const followedBySpace = /\s/.test(after) || after === "";
        if (precededByAlnum || followedBySpace) {
          out += esc(ch.repeat(count));
          i = j;
          continue;
        }
      }
 
      // For asterisks, opener must not be followed by whitespace
      if (ch === "*" && j < len && /\s/.test(src[j])) {
        out += esc(ch.repeat(count));
        i = j;
        continue;
      }
 
      const closeResult = findEmphClose(src, j, ch, count);
      if (closeResult !== -1) {
        const inner = src.slice(j, closeResult);
        if (count === 3) {
          out += `<b><i>${parseInline(inner)}</i></b>`;
        } else if (count === 2) {
          out += `<b>${parseInline(inner)}</b>`;
        } else {
          out += `<i>${parseInline(inner)}</i>`;
        }
        i = closeResult + count;
        continue;
      }
 
      // No matching closer — emit literal
      out += esc(ch.repeat(count));
      i = j;
      continue;
    }
 
    // ── Bare URL: https://... or http://... ──
    if ((src[i] === "h") && src.slice(i, i + 8).match(/^https?:\/\//)) {
      const urlMatch = src.slice(i).match(/^https?:\/\/[^\s\)<>\]'"`,;!]*/);
      if (urlMatch) {
        let url = urlMatch[0];
        // Strip trailing punctuation that's likely not part of URL
        while (url.length > 0 && ".,:;".includes(url[url.length - 1])) {
          url = url.slice(0, -1);
        }
        out += `<a href="${esc(url)}">${esc(url)}</a>`;
        i += url.length;
        continue;
      }
    }
 
    // ── Regular character ──
    out += esc(src[i]);
    i++;
  }
 
  return out;
}
 
// Find closing emphasis delimiter. Returns index of the first char of the
// closing delimiter, or -1 if not found. Ensures the closer has exactly
// `count` delimiter characters and is not preceded by whitespace.
function findEmphClose(src: string, start: number, ch: string, count: number): number {
  const needle = ch.repeat(count);
  let pos = start;
 
  while (pos < src.length) {
    const idx = src.indexOf(needle, pos);
    if (idx === -1) return -1;
 
    // Must be exactly `count` chars (not part of a longer run)
    const before = idx > 0 ? src[idx - 1] : "";
    const after = idx + count < src.length ? src[idx + count] : "";
 
    const exactCount = before !== ch && after !== ch;
    const notPrecededBySpace = before !== " " && before !== "\t";
    // Content between opener and closer must not be empty
    const hasContent = idx > start;
    // For underscore, closer must not be followed by alphanumeric
    const underscoreOk = ch !== "_" || !/\w/.test(after);
 
    if (exactCount && notPrecededBySpace && hasContent && underscoreOk) {
      return idx;
    }
 
    pos = idx + 1;
  }
  return -1;
}
 
// Parse [text](url) starting at the '['. Returns null on failure.
function parseLinkOrImage(
  src: string, start: number
): { text: string; url: string; end: number } | null {
  if (src[start] !== "[") return null;
 
  // Find matching ]
  let depth = 0;
  let j = start;
  for (; j < src.length; j++) {
    if (src[j] === "[") depth++;
    else if (src[j] === "]") {
      depth--;
      if (depth === 0) break;
    }
  }
  if (depth !== 0) return null;
 
  const closeBracket = j;
  // Must be followed by (
  if (closeBracket + 1 >= src.length || src[closeBracket + 1] !== "(") return null;
 
  // Find matching )
  const parenStart = closeBracket + 2;
  let parenDepth = 1;
  let k = parenStart;
  for (; k < src.length && parenDepth > 0; k++) {
    if (src[k] === "(") parenDepth++;
    else if (src[k] === ")") parenDepth--;
  }
  if (parenDepth !== 0) return null;
 
  const text = src.slice(start + 1, closeBracket);
  const url = src.slice(parenStart, k - 1).trim();
 
  return { text, url, end: k };
}
 
// ────────────────────────────────────────────────────────────
// Block Parser
// ────────────────────────────────────────────────────────────
 
const RE_HEADING_ATX = /^(#{1,6})\s+(.*?)(?:\s+#+)?\s*$/;
const RE_FENCE = /^(`{3,}|~{3,})([a-zA-Z0-9_-]*)\s*$/;
const RE_HR = /^(?:[-*_]\s*){3,}$/;
const RE_UL = /^(\s*)([-*+])\s+(.*)/;
const RE_OL = /^(\s*)(\d+)([.)]) (.*)/;
const RE_BLOCKQUOTE = /^(\s*>\s?)(.*)/;
const RE_SETEXT_H1 = /^===+\s*$/;
const RE_SETEXT_H2 = /^---+\s*$/;
const RE_TABLE_SEP = /^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?\s*$/;
 
const BULLET_CHARS = ["•", "◦", "‣", "▪"];
const HEADING_SIZES = [
  "xx-large",  // h1
  "x-large",   // h2
  "large",     // h3
  "large",     // h4
  "medium",    // h5
  "medium",    // h6
];
 
interface ListItem {
  indent: number;
  ordered: boolean;
  number: number;
  content: string;
  children: string[];  // continuation lines
}
 
export function convert(markdown: string): string {
  const lines = markdown.split("\n");
  const output: string[] = [];
  let i = 0;
 
  while (i < lines.length) {
    const line = lines[i];
 
    // ── Fenced code block ──
    const fenceMatch = line.match(RE_FENCE);
    if (fenceMatch) {
      const fence = fenceMatch[1];
      const lang = fenceMatch[2];
      const codeLines: string[] = [];
      i++;
      while (i < lines.length) {
        // Closing fence must be at least as long, same char
        if (lines[i].match(new RegExp(`^${fence[0]}{${fence.length},}\\s*$`))) {
          i++;
          break;
        }
        codeLines.push(lines[i]);
        i++;
      }
      output.push(renderCodeBlock(codeLines, lang));
      continue;
    }
 
    // ── Indented code block (4 spaces or 1 tab, only if preceded by blank) ──
    if ((line.startsWith("    ") || line.startsWith("\t")) && !isListLine(line)) {
      const prev = output.length > 0 ? output[output.length - 1] : "";
      if (prev.trim() === "" || output.length === 0) {
        const codeLines: string[] = [];
        while (i < lines.length && (lines[i].startsWith("    ") || lines[i].startsWith("\t") || lines[i].trim() === "")) {
          const cl = lines[i].startsWith("\t") ? lines[i].slice(1) : lines[i].slice(4);
          codeLines.push(cl);
          i++;
        }
        // Trim trailing blank lines from code block
        while (codeLines.length > 0 && codeLines[codeLines.length - 1].trim() === "") {
          codeLines.pop();
        }
        if (codeLines.length > 0) {
          output.push(renderCodeBlock(codeLines, ""));
          continue;
        }
      }
    }
 
    // ── ATX Heading ──
    const headingMatch = line.match(RE_HEADING_ATX);
    if (headingMatch) {
      const level = headingMatch[1].length; // 1-6
      const text = headingMatch[2].trim();
      output.push(renderHeading(text, level));
      i++;
      continue;
    }
 
    // ── Setext heading (check next line) ──
    if (i + 1 < lines.length && line.trim() !== "") {
      if (lines[i + 1].match(RE_SETEXT_H1)) {
        output.push(renderHeading(line.trim(), 1));
        i += 2;
        continue;
      }
      if (lines[i + 1].match(RE_SETEXT_H2)) {
        output.push(renderHeading(line.trim(), 2));
        i += 2;
        continue;
      }
    }
 
    // ── Horizontal rule ──
    if (line.match(RE_HR) && line.trim().length >= 3) {
      output.push("─".repeat(40));
      i++;
      continue;
    }
 
    // ── Blockquote ──
    const bqMatch = line.match(RE_BLOCKQUOTE);
    if (bqMatch) {
      const bqLines: string[] = [];
      while (i < lines.length) {
        const m = lines[i].match(RE_BLOCKQUOTE);
        if (m) {
          bqLines.push(m[2]);
        } else if (lines[i].trim() === "") {
          // Blank line might continue blockquote if next is also bq
          if (i + 1 < lines.length && lines[i + 1].match(RE_BLOCKQUOTE)) {
            bqLines.push("");
          } else {
            break;
          }
        } else {
          break;
        }
        i++;
      }
      // Recursively convert blockquote content, then prefix each line
      const inner = convert(bqLines.join("\n"));
      const prefixed = inner
        .split("\n")
        .map((l) => `<span foreground="#888">┃</span> ${l}`)
        .join("\n");
      output.push(prefixed);
      continue;
    }
 
    // ── Table ──
    if (isTableStart(lines, i)) {
      const tableLines: string[] = [];
      while (i < lines.length && lines[i].includes("|")) {
        tableLines.push(lines[i]);
        i++;
      }
      output.push(renderTable(tableLines));
      continue;
    }
 
    // ── List (unordered or ordered, with nesting) ──
    if (line.match(RE_UL) || line.match(RE_OL)) {
      const listResult = parseList(lines, i);
      output.push(listResult.markup);
      i = listResult.nextIndex;
      continue;
    }
 
    // ── Blank line ──
    if (line.trim() === "") {
      output.push("");
      i++;
      continue;
    }
 
    // ── Paragraph / plain text ──
    output.push(parseInline(line));
    i++;
  }
 
  return output.join("\n");
}
 
// ────────────────────────────────────────────────────────────
// Block Renderers
// ────────────────────────────────────────────────────────────
 
function renderHeading(text: string, level: number): string {
  const size = HEADING_SIZES[Math.min(level, 6) - 1];
  const inner = parseInline(text);
  return `<span size="${size}"><b>${inner}</b></span>`;
}
 
function renderCodeBlock(codeLines: string[], _lang: string): string {
  const escaped = codeLines.map(esc).join("\n");
  return `<span background="#1e1e2e" foreground="#cdd6f4"><tt> ${escaped.split("\n").join(" \n ")} </tt></span>`;
}
 
function isListLine(line: string): boolean {
  return !!(line.match(RE_UL) || line.match(RE_OL));
}
 
// ── List Parser ──
 
interface ParseListResult {
  markup: string;
  nextIndex: number;
}
 
function parseList(lines: string[], startIdx: number): ParseListResult {
  const items: Array<{
    indent: number;
    ordered: boolean;
    number: number;
    lines: string[];
  }> = [];
 
  let i = startIdx;
 
  while (i < lines.length) {
    const line = lines[i];
    const ulMatch = line.match(RE_UL);
    const olMatch = line.match(RE_OL);
 
    if (ulMatch) {
      items.push({
        indent: ulMatch[1].length,
        ordered: false,
        number: 0,
        lines: [ulMatch[3]],
      });
      i++;
    } else if (olMatch) {
      items.push({
        indent: olMatch[1].length,
        ordered: true,
        number: parseInt(olMatch[2], 10),
        lines: [olMatch[4]],
      });
      i++;
    } else if (line.trim() === "") {
      // Blank line — might be loose list. Check if list continues.
      if (i + 1 < lines.length && (lines[i + 1].match(RE_UL) || lines[i + 1].match(RE_OL) || lines[i + 1].match(/^\s{2,}/))) {
        // Continuation — add blank to current item
        if (items.length > 0) {
          items[items.length - 1].lines.push("");
        }
        i++;
      } else {
        break;
      }
    } else if (line.match(/^\s{2,}/) && items.length > 0) {
      // Continuation line for current list item
      items[items.length - 1].lines.push(line.trimStart());
      i++;
    } else {
      break;
    }
  }
 
  // Determine nesting levels from indentation
  const indents = [...new Set(items.map((it) => it.indent))].sort((a, b) => a - b);
  const indentToLevel = new Map<number, number>();
  indents.forEach((indent, idx) => indentToLevel.set(indent, idx));
 
  const rendered = items.map((item) => {
    const level = indentToLevel.get(item.indent) ?? 0;
    const padding = "  ".repeat(level);
    const content = item.lines.join("\n");
 
    let marker: string;
    if (item.ordered) {
      marker = `${item.number}.`;
    } else {
      marker = BULLET_CHARS[Math.min(level, BULLET_CHARS.length - 1)];
    }
 
    // If content has multiple lines, it might contain sub-blocks
    const parsedContent = item.lines.length > 1
      ? item.lines.map((l) => parseInline(l)).join("\n" + padding + "  ")
      : parseInline(content);
 
    return `${padding}${marker} ${parsedContent}`;
  });
 
  return {
    markup: rendered.join("\n"),
    nextIndex: i,
  };
}
 
// ── Table ──
 
function isTableStart(lines: string[], idx: number): boolean {
  if (idx + 1 >= lines.length) return false;
  if (!lines[idx].includes("|")) return false;
  return !!lines[idx + 1].match(RE_TABLE_SEP);
}
 
function parseTableRow(line: string): string[] {
  let trimmed = line.trim();
  if (trimmed.startsWith("|")) trimmed = trimmed.slice(1);
  if (trimmed.endsWith("|")) trimmed = trimmed.slice(0, -1);
  return trimmed.split("|").map((c) => c.trim());
}
 
function renderTable(tableLines: string[]): string {
  if (tableLines.length < 2) return parseInline(tableLines.join("\n"));
 
  const header = parseTableRow(tableLines[0]);
  // Skip separator line (index 1)
  const rows = tableLines.slice(2).map(parseTableRow);
  const colCount = header.length;
 
  // Calculate column widths
  const widths = new Array(colCount).fill(0);
  for (let c = 0; c < colCount; c++) {
    widths[c] = Math.max(widths[c], (header[c] || "").length);
    for (const row of rows) {
      widths[c] = Math.max(widths[c], (row[c] || "").length);
    }
  }
 
  const pad = (s: string, w: number) => s + " ".repeat(Math.max(0, w - s.length));
  const sep = widths.map((w) => "─".repeat(w + 2)).join("┬");
 
  const formatRow = (cells: string[], bold: boolean): string => {
    const parts = cells.map((cell, ci) => {
      const content = parseInline(pad(cell || "", widths[ci]));
      return bold ? ` <b>${content}</b> ` : ` ${content} `;
    });
    return parts.join("│");
  };
 
  const out: string[] = [];
  out.push(`<tt>${formatRow(header, true)}</tt>`);
  out.push(`<tt>${sep}</tt>`);
  for (const row of rows) {
    out.push(`<tt>${formatRow(row, false)}</tt>`);
  }
  return out.join("\n");
}
 
// ────────────────────────────────────────────────────────────
// Validation — ensure output is safe for Pango
// ────────────────────────────────────────────────────────────
 
// Strips any broken tags so GTK never gets invalid markup.
// Parses the output and ensures all tags are properly closed.
function validatePango(markup: string): string {
  const tagStack: string[] = [];
  const selfClosing = new Set(["br", "hr"]);
 
  // Walk through and track open/close tags
  const tagRe = /<\/?([a-zA-Z]+)(?:\s[^>]*)?\/?>/g;
  let match: RegExpExecArray | null;
  const issues: boolean[] = [];
 
  // Simple validation pass
  const tempStack: string[] = [];
  let valid = true;
 
  tagRe.lastIndex = 0;
  while ((match = tagRe.exec(markup)) !== null) {
    const full = match[0];
    const name = match[1].toLowerCase();
 
    if (selfClosing.has(name)) continue;
 
    if (full.startsWith("</")) {
      // Closing tag
      if (tempStack.length > 0 && tempStack[tempStack.length - 1] === name) {
        tempStack.pop();
      } else {
        valid = false;
        break;
      }
    } else if (!full.endsWith("/>")) {
      // Opening tag
      tempStack.push(name);
    }
  }
 
  if (!valid || tempStack.length > 0) {
    // Markup is broken — strip all tags and return plain escaped text
    return markup.replace(/<[^>]+>/g, "");
  }
 
  return markup;
}
 
// ────────────────────────────────────────────────────────────
// Public API
// ────────────────────────────────────────────────────────────
 
export default function md2pango(markdown: string): string {
  if (!markdown) return "";
 
  const raw = convert(markdown);
  return validatePango(raw);
}
 
export { md2pango, parseInline, esc as escapeXml };
 