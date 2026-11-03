#!/usr/bin/env python3
"""Inspect a release ZIP and extract its bundled PCK."""

import re
import shutil
import sys
import zipfile


def name(info):
    # Some Godot ZIPs contain UTF-8 names without setting the UTF-8 flag.
    if not info.flag_bits & 0x800:
        try:
            return info.filename.encode("cp437").decode("utf-8")
        except UnicodeError:
            pass
    return info.filename


def main():
    action, archive, *args = sys.argv[1:]
    with zipfile.ZipFile(archive) as zf:
        entries = zf.infolist()
        if action == "list" and not args:
            for entry in entries:
                path = name(entry)
                print(path)
                if re.search(r"(^|/)(assets/licensed|tests)/", path):
                    sys.exit("Forbidden licensed assets or tests in release ZIP")
        elif action == "extract-pck" and len(args) == 1:
            packs = [entry for entry in entries if re.search(
                r"(^|/)[^/]+\.app/Contents/Resources/[^/]+\.pck$|^[^/]+\.pck$", name(entry)
            )]
            if len(packs) != 1:
                sys.exit("Expected one PCK at ZIP root or inside .app/Contents/Resources")
            with zf.open(packs[0]) as source, open(args[0], "wb") as dest:
                shutil.copyfileobj(source, dest)
        else:
            sys.exit("Usage: release_zip.py list <zip> | extract-pck <zip> <out>")


if __name__ == "__main__":
    main()
