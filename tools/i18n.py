#!/usr/bin/env python3
"""Localization helper for Eddington 1919.

A small GDScript tokenizer (strings and ``#`` comments, no regex-only parsing)
drives three subcommands:

  wrap     rewrite each player-facing CJK string literal as ``L.t("...")``
  extract  write locale/messages.pot and merge it into locale/{en,ja,ko}.po
  check    fail on an unwrapped CJK literal; --require-translated adds the
           translation and placeholder/BBCode gates

Stdlib only. The zh-TW source text is the msgid.
"""

from __future__ import annotations

import argparse
import bisect
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
LOCALES = ("en", "ja", "ko")
PO_DIR = ROOT / "locale"

CJK_RE = re.compile("[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af\uff00-\uffef\u3000-\u303f]")

# Files and class-level spans whose CJK is not a translatable msgid.
ALLOWLIST_FILES = {"scripts/lookdev.gd"}
NAMES_CONST_RE = re.compile(r"(?m)^[ \t]*const[ \t]+NAMES\b")

WRAPPERS = ("t", "tn", "tc")
WRAPPER_TAIL_RE = re.compile(r"(?:^|[^A-Za-z0-9_.])L\.(t|tn|tc)\(\s*$")

# Plural forms each catalogue carries. en inflects, ja and ko do not.
PLURAL_FORMS = {"en": "nplurals=2; plural=(n != 1);", "ja": "nplurals=1; plural=0;",
                "ko": "nplurals=1; plural=0;"}

CONST_RE = re.compile(r"(?m)^[ \t]*const\b")
FUNC_SIG_RE = re.compile(r"\bfunc\b[ \t]*[A-Za-z0-9_]*[ \t]*\(")
ANNOTATION_RE = re.compile(r"(?m)(?:^|[\s(,])@[A-Za-z_][A-Za-z0-9_]*[ \t]*\(")

IDENT_CHARS = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")


class Token:
    __slots__ = ("start", "end", "content_start", "content_end", "quote",
                 "triple", "raw", "line")

    def __init__(self, start, end, content_start, content_end, quote, triple, raw, line):
        self.start = start
        self.end = end
        self.content_start = content_start
        self.content_end = content_end
        self.quote = quote
        self.triple = triple
        self.raw = raw
        self.line = line

    def text(self, source: str) -> str:
        return source[self.start:self.end]


def _read_string(source: str, i: int) -> Token:
    """Read the literal starting at ``i`` (a quote). Mirrors GDScript escapes."""
    n = len(source)
    prefix = ""
    start = i
    if i > 0 and source[i - 1] in "rR&^":
        before = source[i - 2] if i > 1 else ""
        if source[i - 1] in "&^" or before not in IDENT_CHARS:
            prefix = source[i - 1]
            start = i - 1
    quote = source[i]
    triple = source[i:i + 3] == quote * 3
    opener = quote * 3 if triple else quote
    raw = prefix in ("r", "R")
    j = i + len(opener)
    content_end = n
    while j < n:
        ch = source[j]
        if not raw and ch == "\\":
            j += 2
            continue
        if triple:
            if source.startswith(opener, j):
                content_end = j
                j += len(opener)
                break
            j += 1
        else:
            if ch == quote:
                content_end = j
                j += 1
                break
            if ch == "\n":
                content_end = j
                break
            j += 1
    return Token(start, min(j, n), i + len(opener), content_end, quote, triple, raw, 0)


def tokenize(source: str) -> list[Token]:
    tokens: list[Token] = []
    i, n = 0, len(source)
    while i < n:
        c = source[i]
        if c == "#":
            j = source.find("\n", i)
            if j < 0:
                break
            i = j
            continue
        if c in "\"'":
            token = _read_string(source, i)
            tokens.append(token)
            i = max(token.end, i + 1)
            continue
        i += 1
    line_starts = [0]
    for match in re.finditer("\n", source):
        line_starts.append(match.end())
    for token in tokens:
        token.line = bisect.bisect_right(line_starts, token.start)
    return tokens


def decode_escapes(text: str, raw: bool = False) -> str:
    """GDScript escape forms -> the string the game sees at runtime."""
    if raw:
        return text
    out: list[str] = []
    i = 0
    n = len(text)
    simple = {"n": "\n", "t": "\t", "r": "\r", "a": "\a", "b": "\b",
              "f": "\f", "v": "\v", "\\": "\\", '"': '"', "'": "'"}
    while i < n:
        ch = text[i]
        if ch != "\\" or i + 1 >= n:
            out.append(ch)
            i += 1
            continue
        nxt = text[i + 1]
        if nxt == "\n":
            i += 2
        elif nxt == "\r" and i + 2 < n and text[i + 2] == "\n":
            i += 3
        elif nxt in simple:
            out.append(simple[nxt])
            i += 2
        elif nxt == "u" and i + 6 <= n:
            try:
                out.append(chr(int(text[i + 2:i + 6], 16)))
            except ValueError:
                out.append(nxt)
            i += 6
        elif nxt == "U" and i + 10 <= n:
            try:
                out.append(chr(int(text[i + 2:i + 10], 16)))
            except ValueError:
                out.append(nxt)
            i += 10
        else:
            out.append(nxt)
            i += 2
    return "".join(out)


def has_cjk(text: str) -> bool:
    return bool(CJK_RE.search(text))


def statement_end(source: str, i: int) -> int:
    """End of the statement starting at ``i`` (bracket depth 0 at a newline)."""
    depth = 0
    n = len(source)
    while i < n:
        c = source[i]
        if c == "#":
            j = source.find("\n", i)
            if j < 0:
                return n
            i = j
            continue
        if c in "\"'":
            i = max(_read_string(source, i).end, i + 1)
            continue
        if c in "([{":
            depth += 1
            i += 1
        elif c in ")]}":
            depth = max(0, depth - 1)
            i += 1
        elif c == "\n":
            if depth == 0:
                prev = source[:i].rstrip()[-1:]
                if prev == "\\" or prev in "=,+-*/%<>|&^~":
                    i += 1
                    continue
                return i
            i += 1
        else:
            i += 1
    return n


def _paren_span(source: str, open_paren: int) -> int:
    """Index just past the closing paren matching ``open_paren``."""
    depth = 0
    i = open_paren
    n = len(source)
    while i < n:
        c = source[i]
        if c == "#":
            j = source.find("\n", i)
            if j < 0:
                return n
            i = j
            continue
        if c in "\"'":
            i = max(_read_string(source, i).end, i + 1)
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return n


def masked_source(source: str, tokens: list[Token]) -> str:
    """Source with string bodies and comments blanked, same length and newlines."""
    chars = list(source)
    for token in tokens:
        for k in range(token.start, token.end):
            if chars[k] != "\n":
                chars[k] = " "
    string_spans = [(token.start, token.end) for token in tokens]
    i, n = 0, len(source)
    while i < n:
        if _inside(i, string_spans):
            i += 1
            continue
        if source[i] == "#":
            j = source.find("\n", i)
            if j < 0:
                j = n
            for k in range(i, j):
                chars[k] = " "
            i = j
        else:
            i += 1
    return "".join(chars)


def const_spans(source: str, masked: str) -> list[tuple[int, int]]:
    return [(match.start(), statement_end(source, match.end()))
            for match in CONST_RE.finditer(masked)]


def signature_spans(source: str, masked: str) -> list[tuple[int, int]]:
    spans = []
    for match in FUNC_SIG_RE.finditer(masked):
        open_paren = match.end() - 1
        spans.append((match.start(), _paren_span(source, open_paren)))
    return spans


def annotation_spans(source: str, masked: str) -> list[tuple[int, int]]:
    spans = []
    for match in ANNOTATION_RE.finditer(masked):
        open_paren = match.end() - 1
        spans.append((match.start(), _paren_span(source, open_paren)))
    return spans


def _inside(position: int, spans: list[tuple[int, int]]) -> bool:
    return any(start <= position < end for start, end in spans)


def wrapper_kind(source: str, position: int) -> str | None:
    """``t``, ``tn`` or ``tc`` when the literal at ``position`` is an argument of one."""
    match = WRAPPER_TAIL_RE.search(source[:position])
    return match.group(1) if match else None


def plural_forms(locale: str) -> int:
    return 2 if PLURAL_FORMS[locale].startswith("nplurals=2") else 1


def script_paths() -> list[Path]:
    return sorted(SCRIPTS.rglob("*.gd"))


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def analysis(source: str, path: Path):
    """Classify every CJK literal in one script.

    Returns (editable, skipped) where editable is a list of tokens to wrap and
    skipped is a list of (token, reason).
    """
    tokens = tokenize(source)
    masked = masked_source(source, tokens)
    consts = const_spans(source, masked)
    names = []
    if rel(path) == "scripts/l10n.gd":
        for match in NAMES_CONST_RE.finditer(masked):
            names.append((match.start(), statement_end(source, match.end())))
    signatures = signature_spans(source, masked)
    annotations = annotation_spans(source, masked)
    allowlisted = rel(path) in ALLOWLIST_FILES

    editable: list[Token] = []
    skipped: list[tuple[Token, str]] = []
    for token in tokens:
        value = decode_escapes(source[token.content_start:token.content_end], token.raw)
        if not has_cjk(value):
            continue
        if allowlisted or _inside(token.start, names):
            continue
        if _inside(token.start, consts):
            skipped.append((token, "const"))
            continue
        if _inside(token.start, signatures):
            skipped.append((token, "default parameter"))
            continue
        if _inside(token.start, annotations):
            skipped.append((token, "annotation"))
            continue
        if WRAPPER_TAIL_RE.search(source[:token.start]):
            continue
        following = source[token.end:]
        if re.match(r"[ \t]*:", following):
            skipped.append((token, "dictionary key or match pattern"))
            continue
        if source[token.start] in "&^":
            skipped.append((token, "StringName or NodePath literal"))
            continue
        editable.append(token)
    return editable, skipped


def command_wrap(args: argparse.Namespace) -> int:
    total = 0
    reports = 0
    for path in script_paths():
        source = path.read_text(encoding="utf-8")
        editable, skipped = analysis(source, path)
        for token, reason in skipped:
            value = decode_escapes(source[token.content_start:token.content_end], token.raw).replace("\n", "\\n")
            print("%s:%d: %s: %s" % (rel(path), token.line, reason, value))
            reports += 1
        if not editable:
            continue
        edits = [(token.start, token.end,
                  "L.t(" + source[token.start:token.end] + ")") for token in editable]
        for start, end, replacement in sorted(edits, reverse=True):
            source = source[:start] + replacement + source[end:]
        path.write_text(source, encoding="utf-8")
        total += len(edits)
        print("%s: wrapped %d" % (rel(path), len(edits)))
    print("wrap: %d wrapped, %d reported" % (total, reports))
    return 0


# --- gettext --------------------------------------------------------------

PO_STRING = r'"(?:[^"\\]|\\.)*"'


def po_encode(text: str) -> str:
    escaped = (text.replace("\\", "\\\\").replace('"', '\\"')
               .replace("\n", "\\n").replace("\t", "\\t").replace("\r", "\\r"))
    return '"%s"' % escaped


def po_decode(text: str) -> str:
    out: list[str] = []
    i = 0
    simple = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}
    while i < len(text):
        if text[i] == "\\" and i + 1 < len(text):
            out.append(simple.get(text[i + 1], text[i + 1]))
            i += 2
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


def _po_field(block: str, name: str) -> str | None:
    # A value may continue over quoted lines, as PO editors write long entries.
    match = re.search(r"(?m)^%s[ \t]+((?:%s\s*)+)" % (re.escape(name), PO_STRING), block)
    if not match:
        return None
    parts = re.findall(PO_STRING, match.group(1))
    return "".join(po_decode(part[1:-1]) for part in parts)


def parse_po(path: Path) -> tuple[str, dict[str, object]]:
    """Return (header block, {msgid: msgstr or [msgstr forms]}); keeps every entry.

    A plural entry's value is the list of ``msgstr[0]`` … in index order.
    """
    if not path.exists():
        return "", {}
    text = path.read_text(encoding="utf-8").strip("\n")
    header = ""
    entries: dict[str, object] = {}
    for block in re.split(r"\n\s*\n", text):
        msgid = _po_field(block, "msgid")
        if msgid is None:
            continue
        if msgid == "" and not header:
            header = block
            continue
        if _po_field(block, "msgid_plural") is not None:
            forms: list[str] = []
            while True:
                form = _po_field(block, "msgstr[%d]" % len(forms))
                if form is None:
                    break
                forms.append(form)
            entries[msgid] = forms
            continue
        entries[msgid] = _po_field(block, "msgstr") or ""
    return header, entries


def _pot_header() -> str:
    return (
        'msgid ""\n'
        'msgstr ""\n'
        '"Project-Id-Version: Eddington 1919\\n"\n'
        '"MIME-Version: 1.0\\n"\n'
        '"Content-Type: text/plain; charset=UTF-8\\n"\n'
        '"Content-Transfer-Encoding: 8bit\\n"\n'
        '"Plural-Forms: nplurals=2; plural=(n != 1);\\n"'
    )


def _po_header(locale: str) -> str:
    return (
        'msgid ""\n'
        'msgstr ""\n'
        '"Project-Id-Version: Eddington 1919\\n"\n'
        '"Language: %s\\n"\n'
        '"MIME-Version: 1.0\\n"\n'
        '"Content-Type: text/plain; charset=UTF-8\\n"\n'
        '"Content-Transfer-Encoding: 8bit\\n"\n'
        '"Plural-Forms: %s\\n"' % (locale, PLURAL_FORMS[locale])
    )


def with_plural_forms(header: str, locale: str) -> str:
    """The header block with this catalogue's ``Plural-Forms`` line in place."""
    line = '"Plural-Forms: %s\\n"' % PLURAL_FORMS[locale]
    if re.search(r'(?m)^"Plural-Forms:', header):
        return re.sub(r'(?m)^"Plural-Forms:.*$', lambda _match: line, header)
    return header.rstrip("\n") + "\n" + line


def write_po(path: Path, header: str, entries: dict[str, object],
             refs: dict[str, list[str]] | None = None,
             plurals: set[str] | None = None) -> None:
    """Write the file; a list value or a msgid in ``plurals`` is a plural entry."""
    plurals = plurals or set()
    blocks = [header.rstrip("\n")]
    for msgid in sorted(entries):
        lines = []
        if refs and refs.get(msgid):
            lines.append("#: " + " ".join(refs[msgid]))
        lines.append("msgid " + po_encode(msgid))
        value = entries[msgid]
        if isinstance(value, list) or msgid in plurals:
            forms = value if isinstance(value, list) else [value]
            lines.append("msgid_plural " + po_encode(msgid))
            for index, form in enumerate(forms):
                lines.append("msgstr[%d] %s" % (index, po_encode(form)))
        else:
            lines.append("msgstr " + po_encode(str(value)))
        blocks.append("\n".join(lines))
    path.write_text("\n\n".join(blocks) + "\n", encoding="utf-8")


def collect_msgids() -> dict[str, dict]:
    """Every msgid with its refs and the wrappers it is used through.

    A const string is collected as ``const``: it is still a msgid, but it gains
    its wrapper where it is used.
    """
    found: dict[str, dict] = {}
    for path in script_paths():
        source = path.read_text(encoding="utf-8")
        tokens = tokenize(source)
        masked = masked_source(source, tokens)
        consts = const_spans(source, masked)
        names = []
        if rel(path) == "scripts/l10n.gd":
            for match in NAMES_CONST_RE.finditer(masked):
                names.append((match.start(), statement_end(source, match.end())))
        if rel(path) in ALLOWLIST_FILES:
            continue
        for token in tokens:
            if _inside(token.start, names):
                continue
            value = decode_escapes(source[token.content_start:token.content_end], token.raw)
            if not has_cjk(value):
                continue
            if _inside(token.start, consts):
                kind = "const"
            else:
                kind = wrapper_kind(source, token.start)
                if kind is None:
                    continue
            entry = found.setdefault(value, {"refs": set(), "kinds": set()})
            entry["refs"].add("%s:%d" % (rel(path), token.line))
            entry["kinds"].add(kind)
    return found


def command_extract(args: argparse.Namespace) -> int:
    found = collect_msgids()
    conflicts = sorted(msgid for msgid, entry in found.items()
                       if "tn" in entry["kinds"] and "t" in entry["kinds"])
    if conflicts:
        for msgid in conflicts:
            print("CONFLICT: used through both L.t and L.tn: " + msgid.replace("\n", "\\n"))
        print("extract: %d conflicting msgid(s), nothing written" % len(conflicts))
        return 1
    plurals = {msgid for msgid, entry in found.items() if "tn" in entry["kinds"]}
    refs = {msgid: sorted(entry["refs"]) for msgid, entry in found.items()}
    msgids = sorted(refs)
    write_po(PO_DIR / "messages.pot", _pot_header(),
             {msgid: [""] * plural_forms("en") if msgid in plurals else "" for msgid in msgids},
             refs, plurals)
    print("extract: %d msgids -> locale/messages.pot" % len(msgids))
    for locale in LOCALES:
        path = PO_DIR / ("%s.po" % locale)
        header, entries = parse_po(path)
        header = with_plural_forms(header or _po_header(locale), locale)
        count = plural_forms(locale)
        before = len(entries)
        for msgid in msgids:
            current = entries.get(msgid)
            if msgid in plurals:
                forms = current if isinstance(current, list) else [""] if not current else [str(current)]
                entries[msgid] = list(forms[:count]) + [""] * max(0, count - len(forms))
            elif isinstance(current, list):
                entries[msgid] = current[0] if current else ""
            elif current is None:
                entries[msgid] = ""
        write_po(path, header, entries, plurals=plurals)
        print("extract: %s.po %d -> %d entries" % (locale, before, len(entries)))
    return 0


# --- check ----------------------------------------------------------------

SPEC_RE = re.compile(r"%(?:%|[-+ 0#]*\d*(?:\.\d+)?[a-zA-Z])")
TAG_RE = re.compile(r"\[(/?)([A-Za-z][A-Za-z0-9]*)(?:=[^\]]*)?\]")
IGNORED_TAGS = {"lb", "rb"}


def placeholders(text: str) -> Counter[str]:
    return Counter(match.group(0) for match in SPEC_RE.finditer(text))


def tag_problems(msgid: str, msgstr: str) -> list[str]:
    problems = []

    def tags(text: str) -> list[tuple[bool, str]]:
        return [(match.group(1) == "/", match.group(2).lower())
                for match in TAG_RE.finditer(text) if match.group(2).lower() not in IGNORED_TAGS]

    source_tags = tags(msgid)
    translated_tags = tags(msgstr)
    if Counter(name for _, name in source_tags) != Counter(name for _, name in translated_tags):
        problems.append("BBCode tags differ")
    stack: list[str] = []
    balanced = True
    for closing, name in translated_tags:
        if closing:
            if not stack or stack.pop() != name:
                balanced = False
                break
        else:
            stack.append(name)
    if not balanced or stack:
        problems.append("BBCode tags unbalanced")
    return problems


def _translated_problems(locale: str, msgid: str, msgstr: str) -> int:
    """Placeholder and BBCode problems in one translated string."""
    problems = 0
    if placeholders(msgid) != placeholders(msgstr):
        print("PLACEHOLDERS %s: %s" % (locale, msgid.replace("\n", "\\n")))
        problems += 1
    for problem in tag_problems(msgid, msgstr):
        print("%s %s: %s" % (problem.upper().replace(" ", "-"), locale, msgid.replace("\n", "\\n")))
        problems += 1
    return problems


def command_check(args: argparse.Namespace) -> int:
    failures = 0
    for path in script_paths():
        source = path.read_text(encoding="utf-8")
        editable, _ = analysis(source, path)
        for token in editable:
            value = decode_escapes(source[token.content_start:token.content_end], token.raw)
            print("UNWRAPPED %s:%d: %s" % (rel(path), token.line, value.replace("\n", "\\n")))
            failures += 1

    if args.require_translated:
        found = collect_msgids()
        plurals = {msgid for msgid, entry in found.items() if "tn" in entry["kinds"]}
        for locale in LOCALES:
            path = PO_DIR / ("%s.po" % locale)
            if not path.exists():
                print("MISSING %s" % rel(path))
                failures += 1
                continue
            _, entries = parse_po(path)
            count = plural_forms(locale)
            for msgid in sorted(found):
                current = entries.get(msgid)
                if msgid in plurals:
                    forms = current if isinstance(current, list) else []
                    for index in range(count):
                        form = forms[index] if index < len(forms) else ""
                        if not form:
                            print("UNTRANSLATED %s: %s [%d]" % (locale, msgid.replace("\n", "\\n"), index))
                            failures += 1
                            continue
                        failures += _translated_problems(locale, msgid, form)
                else:
                    msgstr = current if isinstance(current, str) else ""
                    if not msgstr:
                        print("UNTRANSLATED %s: %s" % (locale, msgid.replace("\n", "\\n")))
                        failures += 1
                        continue
                    failures += _translated_problems(locale, msgid, msgstr)

    print("check: %d problem(s)" % failures)
    return 1 if failures else 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("wrap", help="wrap CJK literals in L.t(...)")
    sub.add_parser("extract", help="write messages.pot and merge the .po files")
    check = sub.add_parser("check", help="gate unwrapped literals and translations")
    check.add_argument("--require-translated", action="store_true",
                       help="also require a translated msgstr in en, ja and ko")
    args = parser.parse_args(argv)
    if args.command == "wrap":
        return command_wrap(args)
    if args.command == "extract":
        return command_extract(args)
    return command_check(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
