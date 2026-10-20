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
| **Isolation.** Candidates never overwrite production assets. | GLBs go to `assets/candidates/<batch>/`. That directory is excluded from exports (`export_presets.cfg`) and no shipped scene references it. Validation writes to `art/factory/<batch>/g2/`, not `art/validation/`. |
| **Paid generation needs the Owner's approval and a budget.** | `factory.py gen` refuses to run unless `art/factory/<batch>/APPROVAL.toml` exists with `approved_by`, `credits` (no more than the batch's `budget_credits`) and optionally `assets`. Before each task it checks the append-only `ledger.jsonl`: spent credits plus this attempt's estimate must stay within the approval. `meshy.py` without `--approved` only prints the request. |
| **Every asset carries a licence.** | `licence` is a required field in `batch.toml`. `report` writes `LICENCES.md`, mapping each asset to its build script or its generator receipt (task id, options, credits). |
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
