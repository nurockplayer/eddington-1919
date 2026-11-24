CI `suites` on #475 head 24ab856 FAILED (run 45291234475, 2026-11-24 09:05 JST): `test_third_contact_gap` exit=1, `FAIL: simulation matches the approved P2 oracle` (95 checks, 1 failure). main 4e8a319 (which includes #356 P2) is green on the same suite, so the P4 branch changes something the P2 oracle pins.

Goal: find what in the P4 diff moves the third-contact simulation and fix it so the approved P2 oracle matches again without changing the oracle or P2 behaviour. If the P4 save/restore genuinely must change that simulation, stop and report `DECISION:` instead.
Done when: `test_third_contact_gap` and `test_checkpoint` both pass; push; the capture frames stay valid (recapture only if the fix changes anything visible, into accept/475/<new sha>/). Keep the PR draft.
Test: tachi-run --host -- sh -c 'for t in test_third_contact_gap test_checkpoint; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 1500 godot --headless --path . --script res://tests/$t.gd || exit 1; done'
Budget: 30m
