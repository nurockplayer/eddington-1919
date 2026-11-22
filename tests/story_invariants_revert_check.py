"""Run under tachi-run --host; temporarily mutate real flow sources, restore always."""
from pathlib import Path
import subprocess
import tempfile

SUITE = "res://tests/test_story_invariants.gd"
MAIN = "scripts/main.gd"
CODA = "scripts/content_coda.gd"
EPILOGUE = "scripts/cambridge/content_epilogue.gd"
CHART = "scripts/cambridge/epilogue_chart.gd"
MUTANTS = [
    ("measurement", MAIN, '\tui.close_viewer()\n\t_telegram = results.get',
     '\tif _pressed_eddington:\n\t\tsim.plates[0].reading += 1.0\n\tui.close_viewer()\n\t_telegram = results.get', "F15 measurement unchanged"),
    ("grade", MAIN, '\tvar seq := []\n\tfor l in _grade.presentation:',
     '\tif _pressed_eddington:\n\t\t_grade.fit = 0\n\tvar seq := []\n\tfor l in _grade.presentation:', "F15 asking preserves grade"),
    ("telegram", MAIN, '\t_telegram = results.get("telegram", 1)',
     '\t_telegram = 0 if _pressed_eddington else results.get("telegram", 1)', "F15 asking preserves telegram text"),
    ("fraud-four-locales", CODA, '\tif pressed:\n',
     '\tmemory.append({"zh_TW": "你們造假。", "en": "Your team committed fraud.", "ja": "あなたたちは捏造した。", "ko": "당신들은 조작했다."}[L.current()])\n\tif pressed:\n', "F15 no fraud accusation"),
    ("proof", EPILOGUE, '\t\t"inconclusive":\n\t\t\treturn L.t(',
     '\t\t"inconclusive":\n\t\t\treturn {"zh_TW": "你的底片證明了 1.75。", "en": "Your plates proved 1.75.", "ja": "あなたの乾板が1.75を証明した。", "ko": "당신의 건판이 1.75를 증명했다."}[L.current()]\n\t\t"mutation_unused":\n\t\t\treturn L.t(', "F16 no player-plate proof"),
    ("wrong-branch", EPILOGUE, '\tmatch ledger_case(run):',
     '\tmatch "conceded":', "F16 Ashby retains inconclusive branch"),
    ("missing-four-inch", CHART, 'Sobral 4 吋', 'Sobral', "F16 displayed 4-inch instrument"),
    ("missing-astrographic", CHART, 'Sobral 天體照相儀', 'Sobral', "F16 displayed astrographic instrument"),
    ("unlabelled-error", CHART, '±0.12″ 機率誤差', '±0.12″', "F16 0.12 labelled probable error"),
    ("sigma-error", CHART, '±0.12″ 機率誤差', '±0.12″ 1σ', "F16 no sigma label"),
]


def run(label, expected=None):
    with tempfile.TemporaryFile(mode="w+") as log:
        for command in [
            ["godot", "--headless", "--path", ".", "--check-only", "--script", SUITE],
            ["perl", "-e", "alarm shift; exec @ARGV", "1500", "godot", "--headless", "--path", ".", "--script", SUITE],
        ]:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT)
            if result.returncode:
                break
        log.seek(0)
        output = log.read()
    counts = [line for line in output.splitlines() if "checks, " in line]
    print(f"{label}: exit={result.returncode}; {counts[-1] if counts else 'no counts'}", flush=True)
    if expected:
        failures = [line for line in output.splitlines() if line.startswith("FAIL:") and expected in line]
        assert result.returncode == 1 and counts and failures, output[-12000:]
        if label in ("fraud-four-locales", "proof"):
            for locale in ("zh_TW", "en", "ja", "ko"):
                assert any(f"FAIL: {locale}/" in line for line in failures), (locale, failures)
        print(f"  rejected: {failures[0]}", flush=True)
    else:
        assert result.returncode == 0 and counts, output[-12000:]


run("baseline-main-story")
for name, filename, old, new, expected in MUTANTS:
    path = Path(filename)
    original = path.read_text()
    assert old in original, (name, "mutation target missing")
    try:
        path.write_text(original.replace(old, new))
        run(name, expected)
    finally:
        path.write_text(original)
run("restored-main-story")
print(f"PASS: {len(MUTANTS)} mutations rejected; main story restored and passing", flush=True)
