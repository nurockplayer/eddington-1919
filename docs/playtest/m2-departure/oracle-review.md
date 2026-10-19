# Oracle final source and visual review

Transport: Ego-lite, ChatGPT UI Pro. Conversation: https://chatgpt.com/c/6ad6a0fc-f17c-83e8-a78f-18069a2cf0e1

The text below is the independent review response. Final native rerun receipts are recorded separately in M2_VERIFICATION.md.

No blocking findings.

Reviewed final candidate f9f90f35b70afda5544118ca764d89d5fd5b49ff2df51c0ed6201389d823603f in
m2-final-source.zip
.

Confirmed repairs and provenance

Raw candidate verified: All 29 raw source files match their manifest SHA-256 values. Recomputing the SHA-256 of the sorted JSON file-hash map also reproduces the exact candidate digest above. All six previously omitted files are present.

The figures discrepancy is resolved: Raw scripts/cambridge/figures.gd hashes to 6aa271404e9d1f438ef76933090dd295d7b7896b01ebd536a6338ff9a54ad696. Removing its two trailing blank lines reproduces the earlier rendered-bundle hash exactly. This clears the previous provenance limitation.

The blocking pause defect is repaired: M2’s correction and gift delays now pause with the scene tree, and its arrival and montage tweens explicitly use TWEEN_PAUSE_STOP. This closes the reported path that advanced the montage while paused and entered PREP with an invisible pause state. See scripts/cambridge/departure_director.gd:83–84,177,189,252,256.

The exposed-log-edge guard is sound: Director synchronization propagates pause, busy, dialogue, and log state into the checklist guard; both marking and continuation respect it. I found no resulting deadlock or read-before-mark bypass. See scripts/cambridge/departure_director.gd:93–95 and scripts/cambridge/departure_checklist.gd:194–197,216–218.

The smudge repair is supported by the preview: Positioning now uses the row font’s measured prefix and number widths. The supplied fixture shows readable 16.83 over faint old ink. See scripts/cambridge/departure_checklist.gd:159–176,231–238 and
smudge-preview.png
.

The Director-owned content and the previously reviewed simulation, judgment, main, and shared UI files remain unchanged.

Evidence and verification limits

The new pause assertions use real-time waits that continue while the game is paused, so they meaningfully test frozen gift, fade, and caption progress (tests/test_departure.gd:253–275). The supplied
negative-control log
 reports the three expected timing failures; the supplied
current departure log
 reports 202 checks, 0 failures.

I independently verified the archive hashes and reviewed the source and image; I did not rerun Godot. The departure regression ends after resuming the first montage caption, so it does not itself demonstrate the completed resumed transition into unpaused PREP. The final native route and careful reruns remain pending and are not credited as completed by this verdict. The smudge image is a render-only fixture. No human playtest is claimed.
