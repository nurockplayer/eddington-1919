# Asset Factory

The factory is a batch layer on top of the art pipeline ([PIPELINE.md](../PIPELINE.md)). It takes a registry of candidate assets, sends each one down the route that suits it, and drives every candidate through the gates the production assets already pass:

```
batch.toml ─► concept (GPT via Codex, image→3D routes only)
          ─► build (Blender procedural)  │  gen (Meshy / Tripo, PAID, gated) ─► ingest (Blender)
          ─► G2 validate.py ─► G3 lookdev per asset ─► in-game QA in the real scene ─► review.toml ─► report
```

Everything is one command per stage: `python3 art/pipeline/factory.py <stage> <batch>`. Run `plan` to see each asset's route, its stage status and the budget; `all` runs the free stages end to end. The stage list is in the script's docstring.

## Rules

| Rule | How it is enforced |
|---|---|
| **Isolation.** Candidates never overwrite production assets. | `budget.load_batch` requires `candidates_dir = assets/candidates/<batch>`, a batch id that matches its directory, and asset ids matching `[a-z][a-z0-9_]*`. `ingest.py` refuses to export anywhere outside `assets/candidates/`. GLBs go to `assets/candidates/<batch>/`. That directory is excluded from exports (`export_presets.cfg`) and no shipped scene references it. Validation writes to `art/factory/<batch>/g2/`, not `art/validation/`. |
| **Paid generation needs the Owner's approval and a budget.** | Only `meshy.py` can spend. Before it sends a request, `budget.reserve()` takes a file lock and checks `art/factory/<batch>/APPROVAL.toml`: `approved_by`, finite `credits` no higher than the batch's `budget_credits`, `meshy_plan = "paid"\|"free"` and an optional `assets` list. It also checks that `est_credits` covers the verified price of the generator options. It then appends a *reservation* to `ledger.jsonl`. An attempt whose charge is not confirmed (lost response, crash, unknown `consumed_credits`) stays committed at its estimate and blocks that asset until it is resumed (`meshy.py --resume <attempt>`) or reconciled (`factory.py resolve`). `gen` stops at the first failure. Tripo is refused until its adapter uses the same gate. Covered by `python3 -I art/pipeline/test_budget.py` (23 offline checks). |
| **Every asset carries a licence.** | `licence` is a required field in `batch.toml`. `report` writes `LICENCES.md`, tracing each candidate to its build script or to the receipt of the exact task that was ingested (task id, credits, Meshy plan, licence, terms source). |
| **Evidence is fresh.** | Each stage deletes its old output before it runs, and a tool that exits non-zero counts as a failure. A successful stage writes a receipt keyed by the candidate's sha256. `report` counts only evidence whose receipt matches the current GLB, and marks a review verdict `stale_review` when its `glb_sha256` no longer matches. `all` stops at the first failing stage, G2 failures included. |
| **Nothing is promoted silently.** | A candidate becomes a production asset only when the Owner or Director says so. Promotion copies the entry into `art/assets.toml` and the GLB into `assets/models/`, and is logged in `art/LOG.md`. |
| **Real in-game QA.** | `factory.py qa` runs `tests/factory_qa.gd` inside the real Príncipe scene, with the game's own lighting states, grade, SSAO and weathering. It shoots each candidate from player eye height, then captures wide views with and without all candidates, recording draw calls, primitives and forced-draw time. Candidates get no colliders, so gameplay cannot change. |

## Routes

| Route | Use it for | Cost | Reproducible |
|---|---|---|---|
| `blender_procedural` | Instruments, joinery, architecture, repeated kit props, and anything that must be instanced or hit exact dimensions (BIBLE §3) | $0 | Yes: the script plus the palette produce the same GLB every run |
| `meshy` (REST `meshy.py`, or the Meshy MCP when working interactively) | Organic and irregular forms: cloth, sacks, rock, split wood, wicker | 15 credits per textured `meshy-t2.5` smart-topology attempt | Partly: the receipt keeps the task id and options, but regenerating gives a new mesh |
| `tripo` (`tripo.py`) | Same niche as Meshy | ~30 credits per textured attempt (vendor docs) | Partly. The client is written but has never run, because there is no key |
| `mpfb` (`build_person.py`) | People only (r06) | $0 | Yes |

## Promotion checklist (per candidate)

1. G2 passes.
2. G3 lookdev: dimensions read against the 1.75 m figure, the silhouette reads, and colours sit with the palette chips.
3. In-game QA: the asset reads as a period object at gameplay distance, does not out-shine the evidence (BIBLE S1), and does not look toy-like (§3a).
4. The licence is clear: a project-original script, or a generator receipt plus the plan the account was on.
5. Owner OK, then promotion as described in the Rules table.
