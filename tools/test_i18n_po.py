#!/usr/bin/env python3
"""parse_po keeps what a PO editor writes: python3 tools/test_i18n_po.py"""
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
print("test_i18n_po: passed")
