"""Build the plain pine ladder used to rig the shelter canvas."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit


def main():
    kit.reset()
    parts = []
    # Full-height rails define the 0.48 m width; the rungs meet their inner faces.
    for x in (-0.21, 0.21):
        parts.append(kit.box("ladder_rail", (0.06, 0.04, 3.0),
                             (x, 0, 1.5), "pine", bevel=0.006))
    for index in range(10):
        # The rung ends enter the rails by 20 mm, hiding their flat end caps.
        # The end caps are buried. A tiny variation in mortise direction keeps
        # the repeated rungs hand-fitted without changing their 280 mm spacing.
        skew = (0.20, -0.15, 0.10, -0.25, 0.12)[index % 5]
        parts.append(kit.cyl("ladder_rung", 0.015, 0.40,
                             (0, 0, 0.28 * (index + 1)), "teak_dark",
                             rot=(skew, 90, 0), verts=8, bevel=0))
    # Two substantial repair cleats pin opposite rung-to-rail joints. Their
    # faces sit on the front and back and give the rails a practical handhold
    # depth at the joints while preserving the specified 40 mm rail sections.
    for x, z, y in ((-0.21, 0.28, -0.025), (0.21, 2.80, 0.025)):
        parts.append(kit.box("ladder_joint_cleat", (0.06, 0.02, 0.06),
                             (x, y, z), "pine", bevel=0.004))
    ladder = kit.join("ladder", parts)
    kit.set_origin(ladder, kit.bottom_centre([ladder]))
    ladder.location = (0, 0, 0)
    kit.export("assets/candidates/af01/ladder.glb", [ladder])


if __name__ == "__main__":
    main()
