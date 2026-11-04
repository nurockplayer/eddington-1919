#!/usr/bin/env python3
"""Inspect a release ZIP, extract its bundled PCK, or pack release files."""

import os
import re
import shutil
import sys
import time
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
    if action == "pack" and args:
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as zf:
            for path in args:
                info = zipfile.ZipInfo(
                    os.path.basename(path), time.localtime(os.stat(path).st_mtime)[:6]
                )
                info.create_system = 3
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (0o100755 if os.access(path, os.X_OK) else 0o100644) << 16
                with open(path, "rb") as source, zf.open(info, "w") as dest:
                    shutil.copyfileobj(source, dest)
        return
    with zipfile.ZipFile(archive) as zf:
        entries = zf.infolist()
        if action == "list" and not args:
            for entry in entries:
                path = name(entry)
                print(path)
                if re.search(r"(^|/)(assets/licensed|tests)/", path):
                    sys.exit("Forbidden licensed assets or tests in release ZIP")
            binaries = [entry for entry in entries if name(entry).endswith(".x86_64")]
            if binaries:
                if len(binaries) != 1 or "/" in name(binaries[0]):
                    sys.exit("Expected exactly one Linux binary at ZIP root")
                if not (binaries[0].external_attr >> 16) & 0o111:
                    sys.exit("Linux binary in release ZIP is not executable")
                stem = name(binaries[0])[: -len(".x86_64")]
                if not any(name(entry) == stem + ".pck" for entry in entries):
                    sys.exit("Expected a PCK matching the Linux binary")
        elif action == "extract-pck" and len(args) == 1:
            packs = [entry for entry in entries if re.search(
                r"(^|/)[^/]+\.app/Contents/Resources/[^/]+\.pck$|^[^/]+\.pck$", name(entry)
            )]
            if len(packs) != 1:
                sys.exit("Expected one PCK at ZIP root or inside .app/Contents/Resources")
            with zf.open(packs[0]) as source, open(args[0], "wb") as dest:
                shutil.copyfileobj(source, dest)
        else:
            sys.exit(
                "Usage: release_zip.py list <zip> | extract-pck <zip> <out>"
                " | pack <zip> <file>..."
            )


if __name__ == "__main__":
    main()
