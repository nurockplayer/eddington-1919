# Asset Factory pilot af01: report

**Scope:** 20 candidate environment assets for the Príncipe 1919 camp at Roça Sundy. The pilot reuses the existing Blender kit, the G2 validator, Godot lookdev (G3) and the real game scene, adds a gated paid route, and evaluates Meshy MCP.
**Owner of technical decisions:** Opus 5.5 (Game Director). Build scripts were written by Codex gpt-6.1-sol, and the review was a fresh read-only Codex gpt-6-astra session. Round 1 found 3 blockers and 8 majors in the money gate, isolation and evidence freshness, plus a minor in ingest. Round 2 re-checked the fixes and found 1 blocker, 8 majors and 1 minor in recovery paths and edge cases. All were fixed, and `art/pipeline/test_budget.py` covers them with 23 offline checks (§4).
**Status:** nothing is merged and nothing is promoted. No production asset was touched. **0 paid credits spent.**

## 1. Yield

| | Count | Assets |
|---|---|---|
| Planned | 20 | 14 Blender procedural + 6 image→3D (Meshy) |
| Built and G2 PASS | **14 / 14** procedural | every procedural asset |
| Usable as-is (Director review) | **8** | trestle_table, camp_stool, water_cask, hurricane_lantern, instrument_chest, wheelbarrow, ladder, sawhorse |
| Usable after a small fix | **5** | plate_rack (glass too bright), zinc_bucket (no galvanised swatch), cocoa_drying_barcaca (reads as a pavilion), post_rail_fence (rails too new and yellow), coconut_palm (stiff fronds) |
| Rework | **1** | laterite_steps (reads as soft pillows, a toy read) |
| Blocked: paid route | **6** | cocoa_sack_pile, laterite_boulder, cocoa_pod_basket, felled_stump, tarp_bundle, firewood_stack. Concepts are ready; the run waits on Owner approval and `MESHY_API_KEY`. |

Usable yield is **13 / 20 (65 %)** including small fixes, or 8 / 20 strictly. On the route that could run, it is 13 / 14 (93 %).

Per-asset verdicts and notes are in [review.toml](review.toml), machine-readable status in [STATUS.json](STATUS.json), and the licence map in [LICENCES.md](LICENCES.md).

## 2. Visual quality (in-game evidence)

- [contact-ingame.jpg](contact-ingame.jpg) shows each asset at player eye height in the real scene, with game lighting, grade, SSAO and weathering. [contact-ingame-detail.jpg](contact-ingame-detail.jpg) shows the same eye point with a 30° lens.
- [contact-views.jpg](contact-views.jpg) shows four dressed views (camp in day, roça west, camp at totality, darkroom at night), each **with vs without** the candidates.
- [contact-g3.jpg](contact-g3.jpg) shows the neutral lookdev against the 1.75 m figure and the palette chips.

**Read:**
- The dressed camp reads as lived-in and period, and it keeps the cinematic, non-toy tone.
- The totality and darkroom states still put evidence first.
- Two assets break a BIBLE rule:
  - The plate rack's glass competes with the evidence under the safelight (S1).
  - The laterite steps read as toy-like (§3a).
- In-game QA caught one **spec error** that G2 could not. The steps were specified at 0.54 m, but the house veranda is 0.30 m. The spec was fixed and the steps rebuilt.

**Performance (indicative, one run per state, not a G4 claim; the machine had load average 14–16 from other projects):**
- All 14 candidates together add **+87 draw calls (+19 %)** in `camp_day`, against the G4 limit of +20 %, and +0.20 ms forced draw.
- `darkroom_night`: +9 draw calls.
- A real dressing pass should therefore instance the repeated kit pieces (fence, palm, cask) and share materials.
- The palm kit is a single 508-triangle mesh. That makes the planned palm instancing possible: palms are 125 of 153 draw calls in `totality_sky`. It still needs an A/B G4 run with three repetitions.

## 3. Cost

| Item | Spend |
|---|---|
| Paid 3D generation (Meshy / Tripo) | **0 credits, $0.** Neither key is present on this machine, and no approval exists. |
| Concept images (GPT via Codex, existing route) | 6 images, 57–79 s each, ≈3 min wall-clock at 3 in parallel; subscription, no metered API |
| Codex build agents (gpt-6.1-sol) | 4 jobs, ≈479k tokens in total. A and C took 8–9 min. B and D finished their work quickly, then **blocked for ≈4 h in Codex's own "Oracle" sub-review** before exiting. Next time, cap Codex jobs with a timeout. |
| Machine time per full free pass | build 15.6 s + G2 16 s + G3 ≈30 s + in-game QA ≈20 s for 14 assets |

**Proposed paid budget** (`batch.toml` → `[batch]`):
- **200 Meshy credits**, with an **Owner-facing ceiling of $10**.
- One attempt for each of the 6 assets is 90 credits (`meshy-t2.5` smart-topology, textured, 15 each). The rest allows one retry each.
- The gate enforces the cap. The account's actual credit price must come from the Owner's Meshy plan; the API pricing page lists credits, not dollars.

## 4. Reproducibility

- **Procedural route:** two full rebuilds produced **byte-identical GLBs (14/14, sha256)**. The source of truth is the build script, the palette and `batch.toml`.
- **Concepts:** every prompt, as the tool received it, is in `art/runs/af01-concepts/manifest.jsonl` (gen.py). Images are not bit-reproducible, so the committed JPEG is the record.
- **Paid route:** each task writes a receipt with options, task id and credits, plus a ledger row *before* polling, so a crash still shows the spend. The raw GLB stays local and can be re-downloaded by task id. A regenerated task gives a different mesh, so the receipt and ingest settings are the record.
- **Paid gate:** `test_budget.py` runs 23 offline checks. They cover:
  - no approval, NaN credits, an over-cap approval, `assets = []` or a string
  - a missing or under-priced estimate
  - a production or symlinked `candidates_dir`
  - a 6-way concurrent reserve (exactly one admitted)
  - a lost POST response that stays reserved and blocks the asset, and `resolve` refusing an attempt that may still send
  - negative, NaN or unknown charges, which keep the estimate committed
  - the approval snapshot taken at reservation (licence)
  - a direct `meshy.py --approved` call, and the Tripo refusal
- **Evidence binding:** G2, G3 and in-game QA each write a receipt keyed by the candidate's sha256, and the Director's verdicts in `review.toml` are bound to the same hash. If a GLB changes, its evidence stops counting and its verdict shows as `stale_review`.
- **Ingest** was proven offline. A mesh 37× too large, turned 90° and 4× over budget came out scaled, turned, decimated to 538/600 triangles and cleaned of 29 slivers.

## 5. Meshy MCP evaluation

| Question | Finding |
|---|---|
| Available? | The server connects and exposes about 30 tools (text/image→3D, remesh, retexture, convert, balance, usage). **Every call fails without `MESHY_API_KEY`** in the MCP server's env, including the free `check_balance`. |
| Fit for this game | `meshy-t2.5` smart-topology makes clean, part-separated triangle meshes at a target polycount. That is the best match for our triangle budgets: 600 for kit props, 2,000 for set props. |
| Gap | `remove_lighting` (de-light) works only on `meshy-6` (30 credits textured). On t2.5 we rely on flat-lit concept prompts and the G3 value check. BIBLE §6 requires de-lit albedo. |
| MCP vs script | The MCP is good for interactive single-asset work (retexture, remesh, checking a task). Its cost-confirmation rule matches our gate, but it is conversational, not auditable. Batch generation therefore goes through `art/pipeline/meshy.py`: same endpoint and options, plus approval file, ledger and receipts. The MCP's default download folder (`meshy_output/`) is git-ignored. |
| Licence | Meshy states that **paid plans: output is user-owned, no attribution; free plan: CC BY 4.0, credit Meshy required.** Generated assets are only promotable once the Owner confirms which plan the key belongs to. |
| Tripo | Same niche, about 30 credits per textured image→3D (vendor docs). `tripo.py` is still unexercised (no key). Not recommended as a second paid vendor until Meshy is measured. |

Sources: [Meshy API pricing](https://docs.meshy.ai/en/api/pricing) · [Meshy image-to-3D API](https://docs.meshy.ai/en/api/image-to-3d) · [Meshy commercial use](https://intercom.help/meshy/en/articles/16102098-can-i-use-meshy-assets-commercially) · [Tripo v3.1 model page](https://developers.tripo3d.com/en/models/v3-1)

## 6. Next steps

1. **Owner decisions:**
   - Approve the paid run by committing `art/factory/af01/APPROVAL.toml` (`approved_by`, `credits ≤ 200`, `meshy_plan = "paid"|"free"`, optional `assets`).
   - Put `MESHY_API_KEY` in the environment and in the Meshy MCP server's env.
   - Say which Meshy plan the key is on (this decides the licence).
   Then run: `factory.py gen af01` → `ingest` → `validate` → `preview` → `qa` → `report`.
2. **Fix round:** steps rework, zinc swatch, dimmed rack glass, longer and lower barcaça, weathered rails, palm frond droop. These are spec, palette or script changes, one Codex job.
3. **Palm A/B:** swap the 15 primitive palms for the instanced `coconut_palm` and run G4 with three repetitions (`baseline.sh` + `perf_summary.py`).
4. **Promotion:** for each Owner-accepted candidate, copy its entry into `art/assets.toml` and its GLB into `assets/models/`, place it in `world_builder.gd` with box colliders, run G4, and log it in `LOG.md`.
