#!/usr/bin/env python3
"""parse_po keeps what a PO editor writes: python3 tools/test_i18n_po.py"""
import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import i18n

PO = '''msgid ""
msgstr ""
"Language: en\\n"
"Content-Type: text/plain; charset=UTF-8\\n"

#: scripts/a.gd:1
msgid "單行"
msgstr "one line"

#: scripts/a.gd:2
msgid ""
"很長的"
"一句"
msgstr ""
"A long sentence, "
"wrapped by an \\"editor\\".\\n"

msgid "還沒翻"
msgstr ""
'''

with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / "en.po"
    path.write_text(PO, encoding="utf-8")
    header, entries = i18n.parse_po(path)
    assert "Language: en" in header, header
    assert entries == {
        "單行": "one line",
        "很長的一句": 'A long sentence, wrapped by an "editor".\n',
        "還沒翻": "",
    }, entries
    i18n.write_po(path, header, entries)
    assert i18n.parse_po(path) == (header, entries), "round trip changed the catalog"

# --- apply ----------------------------------------------------------------

APPLY_PO = '''msgid ""
msgstr ""
"Language: en\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"

msgid "單行"
msgstr ""

msgid "%d 張"
msgid_plural "%d 張"
msgstr[0] ""
msgstr[1] ""

msgid "[b]粗體[/b]與 %s"
msgstr ""
'''


def apply_case(batch, po=APPLY_PO):
    """Run apply in its own catalogue; return (exit code, entries, original text)."""
    folder = tempfile.mkdtemp()
    i18n.PO_DIR = Path(folder)
    path = Path(folder) / "en.po"
    path.write_text(po, encoding="utf-8")
    source = Path(folder) / "batch.json"
    source.write_text(json.dumps(batch, ensure_ascii=False), encoding="utf-8")
    code = i18n.main(["apply", "en", str(source)])
    return code, i18n.parse_po(path)[1], path.read_text(encoding="utf-8")


code, entries, _ = apply_case([
    {"msgid": "單行", "msgstr": "one line"},
    {"msgid": "%d 張", "msgstr_plural": ["%d plate", "%d plates"]},
    {"msgid": "[b]粗體[/b]與 %s", "msgstr": "[b]Bold[/b] and %s"},
])
assert code == 0, code
assert entries["單行"] == "one line", entries
assert entries["%d 張"] == ["%d plate", "%d plates"], entries

for batch in (
    [{"msgid": "沒這個", "msgstr": "not here"}],
    [{"msgid": "%d 張", "msgstr_plural": ["plate", "plates"]}],
    [{"msgid": "%d 張", "msgstr_plural": ["%d plate"]}],
    [{"msgid": "%d 張", "msgstr": "line"}],
    [{"msgid": "[b]粗體[/b]與 %s", "msgstr": "Bold and %s"}],
    [{"msgid": "單行", "msgstr": "one", "msgstr_plural": ["one", "many"]}],
):
    before = APPLY_PO
    code, entries, after = apply_case(batch)
    assert code == 1, (batch, code)
    assert after == before, (batch, after)
    assert all(not value if isinstance(value, str) else not any(value)
               for value in entries.values()), (batch, entries)

# --- apply keeps what it was not asked to change --------------------------

METADATA_PO = '''msgid ""
msgstr ""
"Language: en\\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"

#. translator note
#: scripts/a.gd:3
msgid "單行"
msgstr ""

#~ msgid "舊的"
#~ msgstr "old"
'''

code, entries, after = apply_case([{"msgid": "單行", "msgstr": "one line"}], METADATA_PO)
assert code == 0, code
assert entries["單行"] == "one line", entries
assert "#. translator note" in after, after
assert "#: scripts/a.gd:3" in after, after
assert '#~ msgid "舊的"' in after, after

# The same msgid under two contexts cannot be addressed by a contextless batch.
CONTEXT_PO = '''msgid ""
msgstr ""

msgctxt "a"
msgid "開"
msgstr ""

msgctxt "b"
msgid "開"
msgstr ""
'''

code, entries, after = apply_case([{"msgid": "開", "msgstr": "open"}], CONTEXT_PO)
assert code == 1, code
assert after == CONTEXT_PO, after

# A reordered placeholder is refused: the caller still passes the msgid's order.
ORDER_PO = '''msgid ""
msgstr ""

msgid "[%s]把 %d 個底片匣放上架子"
msgstr ""
'''

code, entries, after = apply_case(
    [{"msgid": "[%s]把 %d 個底片匣放上架子", "msgstr": "Put %d plate holders on the rack [%s]"}], ORDER_PO)
assert code == 1, code
assert after == ORDER_PO, after
code, entries, after = apply_case(
    [{"msgid": "[%s]把 %d 個底片匣放上架子", "msgstr": "[%s] Put %d plate holders on the rack"}], ORDER_PO)
assert code == 0, code

# An updated entry stops being fuzzy; its other flags and other entries stay.
FUZZY_PO = '''msgid ""
msgstr ""

#, fuzzy
msgid "甲"
msgstr "old a"

#, fuzzy, python-format
msgid "乙"
msgstr "old b"

#, fuzzy
msgid "丙"
msgstr "old c"
'''

code, entries, after = apply_case(
    [{"msgid": "甲", "msgstr": "new a"}, {"msgid": "乙", "msgstr": "new b"}], FUZZY_PO)
assert code == 0, code
assert entries["甲"] == "new a" and entries["乙"] == "new b", entries
assert '#, fuzzy\nmsgid "甲"' not in after, after
assert '#, python-format\nmsgid "乙"' in after, after
assert '#, fuzzy\nmsgid "丙"' in after, after

# --- check --locales ------------------------------------------------------

with tempfile.TemporaryDirectory() as folder:
    root = Path(folder)
    (root / "scripts").mkdir()
    (root / "scripts" / "a.gd").write_text('func _f():\n\tprint(L.t("你好"))\n',
                                          encoding="utf-8")
    (root / "locale").mkdir()
    saved = i18n.ROOT, i18n.SCRIPTS, i18n.PO_DIR
    i18n.ROOT, i18n.SCRIPTS, i18n.PO_DIR = root, root / "scripts", root / "locale"
    i18n.write_po(i18n.PO_DIR / "en.po", i18n._po_header("en"), {"你好": "hello"})
    assert i18n.main(["check", "--require-translated", "--locales", "en"]) == 0
    assert i18n.main(["check", "--require-translated", "--locales", "ja"]) == 1
    assert i18n.main(["check", "--require-translated"]) == 1
    assert i18n.main(["check", "--require-translated", "--locales", "xx"]) == 1
    i18n.ROOT, i18n.SCRIPTS, i18n.PO_DIR = saved

print("test_i18n_po: passed")
