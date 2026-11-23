#!/usr/bin/env python3
"""Check the all-suites path filters for PRs and pushes, using only stdlib."""
import ast
from fnmatch import fnmatchcase
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
workflow = (ROOT / ".github/workflows/all-suites.yml").read_text(encoding="utf-8")


def selects(kind, patterns, changed):
    if kind == "paths-ignore":
        return any(not any(fnmatchcase(path, pattern) for pattern in patterns)
                   for path in changed)
    # These filters use **, docs/** and **.md. For these patterns fnmatchcase
    # has the same matching behaviour as GitHub's path globs.
    for path in changed:
        included = False
        for pattern in patterns:
            excluded = pattern.startswith("!")
            if fnmatchcase(path, pattern[1:] if excluded else pattern):
                included = not excluded
        if included:
            return True
    return False


cases = [
    (["docs/audio/SOURCES.md"], True),
    (["docs/design/FUN_PLAN.md"], False),
    (["docs/notes.txt"], False),
    (["README.md"], False),
    (["scripts/README.md"], False),
    (["scripts/player.gd"], True),
    (["assets/sfx/bed_surf.ogg"], True),
    (["assets/music/departure_motif.ogg"], True),
    (["README.md", "docs/audio/SOURCES.md"], True),
    (["docs/notes.txt", "scripts/player.gd"], True),
]
events = dict(re.findall(r"^  (push|pull_request):\n((?:    .*\n)*)", workflow, re.M))
assert set(events) == {"push", "pull_request"}, events
for event, block in events.items():
    match = re.search(r"^    (paths(?:-ignore)?): (.+)$", block, re.M)
    assert match, f"{event}: expected an inline path filter"
    kind, values = match.groups()
    patterns = ast.literal_eval(values)
    for changed, expected in cases:
        actual = selects(kind, patterns, changed)
        assert actual == expected, f"{event}: {changed}: selected={actual}, expected={expected}"

print(f"test_audio_workflow_paths: OK ({len(events) * len(cases)} cases)")
