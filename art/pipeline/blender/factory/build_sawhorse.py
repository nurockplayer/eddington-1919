"""Build a compact pine-topped carpenter's sawhorse with splayed teak legs."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit


def main():
    kit.reset()
    parts = [kit.box("sawhorse_beam", (1.0, 0.09, 0.09),
                     (0, 0, 0.655), "pine", bevel=0.008)]

    # Each end frame splays across Y; its upper ends tuck against the beam.
    # Seat the leg ends 30 mm into the beam; face-only bevel contact otherwise
    # leaves the separate members disconnected in a physical surface check.
    upper_z, foot_z = 0.639, 0.005
    upper_y, foot_y = 0.03, 0.256
    leg_len = math.hypot(upper_z - foot_z, foot_y - upper_y)
    angle = math.degrees(math.atan2(foot_y - upper_y, upper_z - foot_z))
    for x in (-0.34, 0.34):
        for side in (-1, 1):
            lower_y = side * foot_y
            high_y = side * upper_y
            centre_y = (lower_y + high_y) / 2
            # Local +Z points from the feet toward the top of each splayed leg.
            rot_x = side * angle
            parts.append(kit.box("sawhorse_leg", (0.055, 0.045, leg_len),
                                 (x, centre_y, (foot_z + upper_z) / 2),
                                 "teak", rot=(rot_x, 0, 0), bevel=0.006))
        # A substantial cross-brace joins each pair of legs just above mid-height.
        brace_index = 0 if x < 0 else 1
        parts.append(kit.box("sawhorse_end_brace", (0.05, 0.40, 0.055),
                             (x, 0, 0.245 + (0.001 if brace_index == 0 else -0.001)),
                             "teak", rot=((0.3 if brace_index == 0 else -0.2), 0, 0),
                             bevel=0.006))

    sawhorse = kit.join("sawhorse", parts)
    # Level the bevelled trestles at ground height without raising the exact
    # 0.70 m pine beam along with the sub-millimetre sole envelope.
    sole = min(v.co.z + sawhorse.location.z for v in sawhorse.data.vertices)
    trestle_verts = {i for face in sawhorse.data.polygons
                    if sawhorse.data.materials[face.material_index].name == "E1919_teak"
                    for i in face.vertices}
    for index in trestle_verts:
        sawhorse.data.vertices[index].co.z -= sole
    kit.set_origin(sawhorse, kit.bottom_centre([sawhorse]))
    sawhorse.location = (0, 0, 0)
    kit.export("assets/candidates/af01/sawhorse.glb", [sawhorse])


if __name__ == "__main__":
    main()
