# Step 0: character shot list (measured from code, 2026-10-27 20:25 JST)

Viewport 1600x900 (project.godot). First-person camera at 1.62 m (scripts/player.gd).
Godot `fov` is vertical. Face height = chin to hairline, about 0.19 m.
Face px = 0.19 / (2 d tan(fov/2)) x 900.

| Shot | Source | fov | Distance d | Face px |
|---|---|---|---|---|
| Walking past | player.gd `fov = 72` | 72 | 3 m / 6 m | 39 / 20 |
| Talking, near | director.gd `_speak` lens | 55 | 1.5 m | 109 |
| Talking, typical | same | 55 | 2.0 m | 82 |
| Talking, edge of reach | same, REACH 3.2 m | ~51 | 3.0 m | ~60 |
| Far speaker | same | 40 | 4.5 m | 52 |
| Dialogue portrait | dialogue_portrait.gd, 2D image | - | - | 204 px box |

Conclusions:
- In-game 3D faces are 20-110 px. At that size the read comes from silhouette,
  hair mass, brow/eye-socket shadow, collar and value contrast with the room,
  not from sculpted likeness or skin pores.
- The only face shown above ~110 px today is the 2D dialogue portrait.
- A Tell Me Why-style close-up (face 180-250 px) does not exist. Adding one is
  a game-design decision for the Owner at step 2 (target frame); only then is
  hero-face sculpting worth its cost.
