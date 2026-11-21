# Loupe and workbook provenance

Original procedural geometry, authored for Eddington 1919, 2026-11-22 JST.
No downloaded meshes, textures or other third-party assets.
`build_loupe_workbook.py` uses the same `kit.py`, palette materials, metre
units, bottom-centre origin and GLB export as #344's darkroom kit.

Build: `blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/build_loupe_workbook.py`
(run inside the required tachi-run heavy job).

`mentor_loupe.glb`: brass folding stand magnifier, 0.266 m lens-ring diameter,
open optical aperture and handle. The lens is clear air rather than an opaque
insert; the engraving reads the physical brass rim.
`field_workbook.glb`: open bound field ledger, paired cream page blocks,
raised binding, ruled pages and margins. Used only on the Príncipe bench;
Cambridge's cover animation and narrative labels retain their existing path.
