# Simple Vaccines (Project Zomboid mod)

Craftable zombie vaccines that give the First Aid skill a real purpose. Supports **Build 42** and **Build 41**.

- Steam Workshop: [Simple Vaccines](https://steamcommunity.com/sharedfiles/filedetails/?id=2954167467) (item `2954167467`)
- Mod ID: `FAVACCINE` · Author: BlueBerry Gravy

## Gameplay

1. Right-click a dead zombie with a sharp knife or scalpel → **Attempt to Extract DNA** (one try per corpse).
2. Boil the zombie cells in very hot water.
3. Craft a vaccine (First Aid 3 / 5 / 8) from boiled cells, an empty syringe, painkillers and water.
4. Right-click the vaccine → **Inject**. Immunity builds over 7 days, then fades over 24.
5. If you're infected while immune, you get one roll to fight it off; the chance is your current immunity.

| Vaccine | Protection at peak | First Aid |
|---|---|---|
| Boiled Zombie Cells | 15% | 0 |
| Crude Zombie Vaccine | 35% | 3 |
| Simple Zombie Vaccine | 60% | 5 |
| Perfect Zombie Vaccine | 95% | 8 |

All values are sandbox options (Build 42 adds build-up/fade days, extraction chance and one-extraction-per-corpse).

## Repository layout

```
First Aid Vaccines/          the mod folder (what goes into the Workshop upload)
  mod.info, media/, poster.png   Build 41 version (B41 only reads the mod root)
  42/                            Build 42: mod.info, icon.png, poster.png, media/ (scripts, Lua, translations, AnimSets)
  common/                        Build 42 shared assets: models_X, anims_X, textures, ui
tools/animation/             Python + Blender scripts that made the custom animations, models and icons
Mod_Description.txt          Workshop description (Steam BBCode)
CHANGELOG.md
```

Build 42 loads `common/` + `42/` and ignores the root; Build 41 loads the root and ignores `42/` and `common/`.

### Build 42 code map (`42/media/`)

| File | What it does |
|---|---|
| `lua/shared/FAVACCINEUtils.lua` | Vaccine state, hourly update, cure roll, public API |
| `lua/shared/TimedActions/FAVInjectAction.lua` | Inject action (custom `FAVInject` animation) |
| `lua/shared/TimedActions/FAVExtractTimedAction.lua` | DNA extraction (custom `FAVExtractDNA` animation) |
| `lua/client/FAVACCINEContextMenu.lua` | Right-click menus (corpse, vaccine) |
| `lua/client/FAVACCINEMoodle.lua` | Optional Moodle Framework moodle, dose/cure messages, MP state sync |
| `lua/server/FAVACCINEServer.lua` | MP client commands |
| `lua/server/items/*Distributions.lua` | Loot tables |
| `scripts/` | Items, models, craft recipes, timed-action animations |
| `AnimSets/player/actions/` | Links the actions to the custom clips |
| `lua/shared/Translate/<LANG>/*.json` | Translations (10 languages, UTF-8) |

Build 41 translations live in `media/lua/shared/Translate/<LANG>/*_<LANG>.txt` and use Build 41's per-language encodings (RU cp1251, PL cp1250, KO UTF-16, CN/JP UTF-8, others cp1252).

## Testing locally

Copy `First Aid Vaccines/` to `%UserProfile%\Zomboid\Workshop\Simple Vaccines\Contents\mods\` (or `Zomboid\mods\`), enable **Simple Vaccines** in the mod list, and check `%UserProfile%\Zomboid\console.txt` for lines mentioning `FAVACCINE`. If you're subscribed to the Workshop version, unsubscribe while testing so the local copy is used.

## Uploading to the Workshop

`%UserProfile%\Zomboid\Workshop\Simple Vaccines\` must contain:

```
workshop.txt        id=2954167467 (keeps it an update, not a new item), title, description=..., tags
preview.png         256x256
Contents/mods/First Aid Vaccines/
```

In game: **Workshop → Create and update items → Simple Vaccines → Update**. The upload replaces the Steam description with the one in `workshop.txt`.

## API for other mods (Build 42)

```lua
FAVUtils.getImmunity(player)       -- current chance (0-100) that the next infection is stopped
FAVUtils.isImmunityRising(player)  -- true while a dose is still building up
table.insert(FAVUtils.cureListeners, function(player) end)  -- called when a vaccine cures someone (SP / MP server)
```

## Animation & model tools

`tools/animation/` rebuilds the custom clips (`Bob_FAV_Inject`, `Bob_FAV_ExtractDNA`), the syringe and petri dish models, and the icons. See [`tools/animation/README.md`](tools/animation/README.md); it needs Python with `bpy`, `numpy`, `scipy` and `pillow`, plus a few clips copied from the game.
