| Prior finding | Assessment |
|---|---|
| 1. Resolve releases live reservations / overwrites terminal charges | **Fixed** — eligibility checks and append now share the lock; live and terminal attempts are rejected. |
| 2. Negative/NaN terminal credits | **Fixed** — invalid charges retain the estimate; nonstandard JSON constants fail closed. |
| 3. Ledger not durable before POST | **Fixed** — reservation append fsyncs the file and, when newly created, its directory before returning. |
| 4. Empty/string approval assets | **Fixed** — strings are rejected; an empty list approves nothing. |
| 5. G2 failures / QA nonzero exits return success | **Fixed** — reported G2 failures increment the failure count; QA requires exit zero. |
| 6. Failed-stage evidence / unbound reviews | **Partially fixed** — hashes bind receipts and reviews, but import failures can still produce receipts; deleting a candidate retains its old usable verdict (`factory.py:229,267,322`). |
| 7. Mutable licence provenance / stale ingest receipt | **Fixed** — reservation snapshots approval metadata; ingest provenance is invalidated and checked against the candidate hash. |
| 8. Cleanup destroys tiny-unit meshes | **Fixed** — pre-fit cleanup thresholds now scale with source dimensions. |
| 9. `--allow-outside` / symlink isolation bypass | **Partially fixed** — override and batch-directory symlinks are blocked, but `assets/candidates → assets/models` passes both checks and permits production exports (`budget.py:54`, `blender/ingest.py:74`). |
| 10. Legacy rows without attempt IDs | **Fixed** — rejected before further reservations. |

New major findings:

- **Resume can reduce already confirmed spend.** [budget.py:124](art/pipeline/budget.py:124): `meshy.py:85–107` accepts completed attempts and appends another terminal observation. If a subsequent response omits `consumed_credits`, it replaces the known charge with `None`. An offline in-memory probe demonstrated **30 confirmed credits falling to the 15-credit estimate**, reopening approval capacity. Preserve confirmed charges when subsequent observations are unknown.

- **Procedural builds can overwrite production models.** [factory.py:140](art/pipeline/factory.py:140): a valid batch can select the existing `art/pipeline/blender/build_coelostat.py`, which exports directly to `assets/models/coelostat.glb` at line 102. The candidate-path validation does not constrain the builder’s destination; the later missing-candidate failure occurs after production has been overwritten.

Verification used offline source inspection and in-memory probes; no paid requests or filesystem mutations.

VERDICT: REQUEST_CHANGES