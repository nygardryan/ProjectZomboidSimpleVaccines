# Simple Vaccines – animation & model tools

Python + Blender (`pip install bpy`) scripts used to make the mod's custom animations and models.
Nothing here ships to the Workshop; the generated files live in `First Aid Vaccines/common/media/`.

| Script | Makes |
|---|---|
| `make_inject.py` | `Bob_FAV_Inject.X` – right hand injects a syringe into the left upper arm (3.0 s) |
| `make_extract.py` | `Bob_FAV_ExtractDNA.X` – kneel at a corpse and cut with a knife (2.67 s loop) |
| `build_models.py` | `FAVSyringe.X`, `FAVSyringe_World.X`, `FAVPetriDish.X` + textures, and `FAVModels.blend` |
| `show.py`, `render_models.py` | preview renders (contact sheets) to check clips and models |
| `xanim.py`, `ik.py`, `preview.py` | DirectX .X reader/writer, IK solver, Blender preview renderer |

## Setup
1. `pip install bpy numpy scipy pillow`
2. Copy these game files (from `ProjectZomboid/media/`) into `src/`:
   - `anims_X/Bob/Bob_IdleTakePills.X, Bob_IdleSlicingFood.X, Bob_BandageLeftArm.X, Bob_IdleMakingLow.X` → `src/anims/`
   - `models_X/weapons/1handed/Scalpel.X` → `src/models/`
3. `mkdir out models_out`, then run e.g. `python make_inject.py` and `python show.py out/Bob_FAV_Inject.X out/inject.png 9`.
4. Copy results into `First Aid Vaccines/common/media/anims_X/Bob/`, `models_X/`, `textures/`.

## Notes
- Clips are written by replacing only the AnimationSet of a game clip, so the skeleton and format are exactly the game's.
- Quaternions in the game's .X files use the transposed convention; `xanim.quat_to_mat` is verified against them.
- Hand props (`Bip01_Prop1` right, `Bip01_Prop2` left) are children of `Bip01`, not the hands, so clips key them to follow the hand.
- Held models point along +Y from the grip (same as the game's knives); the syringe's needle is +Y.
