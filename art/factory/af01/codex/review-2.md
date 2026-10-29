Reviewed `16e45b0..7dda567` at HEAD `7dda567b77aa584347b70ced20c89a4d704c3183`, offline and read-only. Tests were inspected, not executed: the sandbox prohibits their temporary writes.

The normal Meshy POST now calls `reserve()` first, but recovery can invalidate that reservation and erase committed credits.

1. **blocker — Reconciliation can release a live reservation or erase a completed charge.**  
   `art/pipeline/factory.py:159–164`; `art/pipeline/budget.py:98–101,154–156`; `art/pipeline/meshy.py:93–98`.  
   **Scenario:** A reserves 15 credits and pauses before POST. `resolve A --not-created` releases it. B reserves the same 15 credits; A resumes and still sends its POST. Both requests can spend against a 15-credit approval. Separately, `resolve` checks state outside the lock; a terminal charge recorded between that check and its append can subsequently be overwritten with zero.  
   **Fix:** Validate reconciliation transitions under the lock, reject releases of known tasks or terminal charges, and coordinate dispatch with reconciliation so a released reservation cannot subsequently send.

2. **major — Terminal credits reintroduce a numeric fail-open.**  
   `art/pipeline/meshy.py:106–107`; `art/pipeline/budget.py:96–106,147`.  
   **Scenario:** `consumed_credits` is recorded without validation. A negative value reduces committed spend. Python’s JSON decoder also accepts `NaN`; once committed spend becomes NaN, `spent + est > approved` is always false, allowing further reservations beyond the approval.  
   **Fix:** Validate response and replayed ledger amounts as finite, nonnegative numbers. Treat invalid charges as unresolved and retain the estimate; reject nonstandard JSON constants.

3. **major — Reservations are flushed, but not durably persisted before POST.**  
   `art/pipeline/budget.py:79–82`.  
   **Scenario:** After `flush()`, Meshy accepts the request, then the host crashes before filesystem buffers reach durable storage. The reservation can disappear, making those credits available again after restart. This differs from an ordinary process crash, which the new ordering handles.  
   **Fix:** Synchronize the ledger to durable storage before permitting POST, including the directory entry when creating the ledger. Fail closed if persistence fails.

4. **major — An empty approved-assets list authorizes every asset.**  
   `art/pipeline/budget.py:140–141`.  
   **Scenario:** An otherwise valid approval containing `assets = []` bypasses the membership check because the list is falsey. A string is also accepted and uses substring membership instead of asset-ID membership.  
   **Fix:** Validate `assets` as a list of asset IDs. Distinguish an absent restriction from an explicitly empty list; the latter must authorize nothing.

5. **major — G2 failures and some QA crashes still return success.**  
   `art/pipeline/factory.py:199–208,270–281`.  
   **Scenario:** G2 returns exit 1 with `"pass": false`; `validate()` prints FAIL but never increments `fails`, so `all` continues. QA likewise accepts any nonzero exit if the completion marker and JSON exist, labelling it a teardown crash without establishing that cause.  
   **Fix:** Count failed G2 checks as stage failures and propagate nonzero QA exits. Preserve completed captures as diagnostic evidence without turning the failed execution into success.

6. **major — Reporting can count artifacts from failed stages as current evidence.**  
   `art/pipeline/factory.py:83–85,229–234,305–314`.  
   **Scenario:** Preview writes its screenshot and then crashes. Preview correctly fails, but a subsequent `report` sets `g3=true` solely because that screenshot is newer than the GLB. Partial QA captures have the same problem. Existing `usable` reviews also survive candidate replacement or deletion.  
   **Fix:** Require a successful stage receipt tied to the candidate’s content hash. Bind review decisions to that identity and invalidate dependent evidence when it changes.

7. **major — Licence provenance remains mutable and can identify the wrong generation.**  
   `art/pipeline/meshy.py:114–121`; `art/pipeline/factory.py:178,289–296`.  
   **Scenario:** Generate under `meshy_plan="free"`, change the approval to `"paid"`, then resume the old task: its receipt is rewritten as paid/no-attribution. Additionally, re-ingest removes the GLB but preserves the old ingest receipt; failure after exporting the replacement but before writing its receipt leaves the new candidate attributed to the old task.  
   **Fix:** Snapshot generation options, approval identity and plan with the reservation. Reuse that immutable metadata on resume. Invalidate old ingest provenance before replacement and publish a receipt tied to the exported GLB’s hash.

8. **major — Cleaning before fitting now destroys valid small-scale inputs.**  
   `art/pipeline/blender/ingest.py:42–47,95–97`.  
   **Scenario:** A triangulated cube with side `1e-4` has triangle areas `5e-9`. The new pre-fit cleanup deletes every face using the absolute `1e-8` threshold; `bounds()` then fails on an empty mesh. Previously, fitting it to a one-metre specification before cleanup preserved it.  
   **Fix:** Use scale-relative tolerances for pre-fit cleanup, then apply the absolute G2 tolerances after fitting.

9. **major — Candidate isolation still has bypasses.**  
   `art/pipeline/blender/ingest.py:70–72`; `art/pipeline/budget.py:50`; `art/pipeline/factory.py:178`.  
   **Scenario:** Direct ingest accepts `--export assets/models/foo.glb --allow-outside yes`, bypassing the new guard. Also, a candidate directory symlink into `assets/models` passes the registry’s string check; the factory can unlink the production file **before** ingest’s resolved-path guard rejects export.  
   **Fix:** Remove the unrestricted override and validate resolved destinations before any deletion or write, including procedural builds.

10. **minor — Existing ledgers have no migration path.**  
    `art/pipeline/budget.py:89`.  
    **Scenario:** A ledger written by `16e45b0` contains task-based rows without `attempt`. Upgrading causes `state()` to raise `KeyError`, breaking planning, reporting, reservation and reconciliation. This fails closed for spending, but makes existing commitments unavailable through the tooling.  
    **Fix:** Add a versioned migration or compatible reader preserving both confirmed charges and outstanding estimates.

| Previous finding | Assessment |
|---|---|
| Approval bypass through `meshy.py --approved` | **fixed** for the original bypass: it now calls `reserve()`. Scope and recovery defects remain above. |
| POST before ledger / double-spend | **partially** — reservation precedes POST; durability and reconciliation remain unsafe (#1, #3). |
| Concurrent over-approval | **partially** — reservation admission is locked; reconciliation can release its capacity incorrectly (#1). |
| NaN/missing estimates fail open | **fixed** — approval amounts and estimates receive finite-number checks and a cost floor. |
| Unknown terminal charges zeroed | **fixed** for missing/null credits: the estimate remains committed. Present-but-invalid values remain unsafe (#2). |
| Reader/writer ledger mismatch | **partially** — current readers/writers share the canonical directory and schema; legacy ledgers are unsupported (#10). |
| `candidates_dir` could target production | **partially** — literal production paths are rejected; bypasses remain (#9). |
| Cleanup after fitting; no reseating after decimation | **partially** — ordering and reseating changed correctly, but pre-fit cleanup introduces #8. |
| Tripo route could not run | **partially** — factory now refuses it explicitly; a functioning gated adapter remains absent. |
| Raw dimensions mislabeled | **fixed** — dimensions are captured before rotation and fitting. |
| Licence not traced to ingested task | **partially** — receipt selection follows ingest provenance, but provenance can become incorrect (#7). |
| Stale evidence / ignored exit codes | **partially** — output clearing improves reruns; failures and evidence acceptance remain incomplete (#5–6). |

**VERDICT: REQUEST_CHANGES**

