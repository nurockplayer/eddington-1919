Reviewed `16e45b0` against its parent using static inspection and in-memory mocks. No files changed or network calls made.

1. **blocker — Approval can be bypassed.** [meshy.py:68](art/pipeline/meshy.py:68)  
   Passing `--approved` directly reaches the paid POST without checking `APPROVAL.toml` or the budget. The mock confirmed this with no approval file present. **Fix:** enforce approval and budget reservation inside the shared operation that creates paid tasks; a CLI boolean must not substitute for those checks.

2. **blocker — Lost responses and retries can double-spend.** [meshy.py:77](art/pipeline/meshy.py:77)  
   The POST precedes the ledger write. If the server creates the task but its response is lost, the ledger remains empty. Retrying creates another task; `factory.gen()` also continues to subsequent assets after failure. A mock admitted all six attempts under a 15-credit approval. Even recorded unfinished tasks have no resume path. **Fix:** durably reserve before POST, stop on ambiguous creation outcomes, reconcile unresolved attempts, and resume existing task IDs/downloads.

3. **blocker — Concurrent invocations can exceed approval.** [factory.py:139](art/pipeline/factory.py:139)  
   Reading spend, checking allowance, and creating the task are not synchronized. Two processes can both observe zero spend and submit 15-credit tasks against the same 15-credit approval; the concurrency mock reproduced this. **Fix:** lock the batch ledger across validation and a durable reservation, before releasing the lock and submitting.

4. **major — Cost inputs fail open.** [factory.py:132](art/pipeline/factory.py:132)  
   TOML `credits = nan` defeats both comparisons. Missing `est_credits` defaults to zero, permitting a paid textured request with zero approved credits. Estimates also are not checked against generator options. Both input bypasses were reproduced. **Fix:** validate finite, nonnegative numeric fields and require a verified cost bound matching the requested model/options.

5. **major — Unknown terminal charges erase reservations.** [factory.py:76](art/pipeline/factory.py:76), [meshy.py:88](art/pipeline/meshy.py:88)  
   Missing `consumed_credits` becomes zero; `null` also becomes zero in the reducer. Either removes the outstanding estimate, including for failed/canceled tasks whose charge or refund is unresolved. The mock reduced a 15-credit reservation to zero. **Fix:** distinguish unknown charges from confirmed zero/refunds, retain unresolved reservations, and reduce events idempotently per task.

6. **major — Reader and writer can use different ledgers.** [meshy.py:78](art/pipeline/meshy.py:78)  
   Factory reads the selected batch directory’s ledger; Meshy derives its ledger from `batch.id`. Copying `af01` into `af02` without updating that ID makes approval checks read `af02` while charges accumulate under `af01`. **Fix:** derive both paths from the canonical registry location and reject inconsistent batch IDs before spending.

7. **major — Production-output isolation is unenforced.** [factory.py:63](art/pipeline/factory.py:63)  
   Setting `candidates_dir = "assets/models"` makes `factory ingest` overwrite a production GLB with the same asset ID. Paths and identifiers are not confined. **Fix:** validate resolved destinations beneath `assets/candidates/<batch>/`, reject traversal/absolute identifiers, and enforce the boundary again before export.

8. **major — Cleanup happens after dimensions and origin are fitted.** [ingest.py:98](art/pipeline/blender/ingest.py:98)  
   Loose vertices or degenerate outliers influence orientation, scale, and centering, then disappear during cleanup. The surviving model remains incorrectly fitted. Subsequent decimation can also change its bounds without recentering. **Fix:** clean before fitting and recompute final bounds, scale, and bottom-center after topology changes.

9. **major — The advertised Tripo route cannot run.** [factory.py:145](art/pipeline/factory.py:145)  
   Factory passes `--batch` and `--approved`, which `tripo.py` does not accept. Its parser exits with code 2; reproduced without network access. **Fix:** disable this route until its adapter implements the shared approval, reservation, and accounting contract.

10. **minor — Turned dimensions are labeled as raw dimensions.** [ingest.py:141](art/pipeline/blender/ingest.py:141)  
    After a 90° turn, `size` contains the rotated bounds, but the receipt records it as `raw_dims_m`. **Fix:** preserve the original dimensions separately.

11. **major — Generated-asset licences cannot be resolved reliably.** [meshy.py:98](art/pipeline/meshy.py:98), [factory.py:257](art/pipeline/factory.py:257)  
    Receipts omit the account plan/licence basis. Reporting selects the lexicographically last receipt instead of the task actually ingested, so multiple attempts can produce incorrect attribution. **Fix:** follow the ingest receipt to the exact source task and record its applicable plan, dated terms source, and resolved licence. The six current Meshy assets are correctly blocked; current paid/free terms could not be independently verified under the no-network constraint.

12. **major — Failed stages can reuse stale PASS evidence.** [factory.py:171](art/pipeline/factory.py:171)  
    Validation ignores the subprocess exit code and reads existing G2 JSON. A mocked exit 127 still printed `PASS`. Preview and QA similarly accept existing artifacts, and `report()` does not bind evidence to the current candidate. **Fix:** require successful execution and fresh, candidate-bound outputs; propagate failures through `all`.

The committed counts and verdict totals reconcile. Current af01 model paths match the export exclusion, the QA hook is inactive during ordinary launches, and the default `validate.py` interface remains compatible. Godot/Blender execution and an exported build were not tested.

VERDICT: REQUEST_CHANGES

