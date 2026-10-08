# Changelog

## 2.0 – Build 42 support

### Build 42
- **Crafting** moved to Build 42 craft recipes. Cleaning syringes and boiling zombie cells now need very hot water.
- **Inject action** – vaccines are injected (right-click → Inject) with a custom animation, instead of being eaten. Boiled zombie cells are still eaten.
- **DNA extraction** – custom kneeling animation, works with any sharp knife (or a scalpel), one extraction per corpse (the body is kept).
- **Models & icons** – new 3D syringes (empty, dirty, three vaccine colours) and petri dishes, in hand and on the ground; new 32×32 icons; mod-list icon.
- **Crafting animations** – scrubbing (clean syringe), stirring (boil cells), mixing fluids (vaccines), each with matching props.
- **Feedback** – floating text when a dose is taken and when a vaccine cures an infection.
- **Loot** – syringes in Build 42 medical containers and on doctor, nurse, paramedic and pharmacist zombies.
- **Sandbox options** – immunity build-up and fade days, DNA extraction chance and per-level bonus, one extraction per corpse.
- **Multiplayer** – the server owns immunity and cures; cures are synced to the client (body parts, damage, infection/fever stats).
- **Cure** also clears Build 42's zombie infection and fever stats and the infection growth rate.
- **Moodle Framework** is optional and guarded; if it errors, the moodle is turned off and the mod keeps working.
- **API** for other mods: `FAVUtils.getImmunity`, `FAVUtils.isImmunityRising`, `FAVUtils.cureListeners`.
- Recipe renamed to "Create Perfect Zombie Vaccine" to match the item.

### Both builds
- **Languages** – English, Spanish, Russian, Simplified Chinese, Brazilian Portuguese, German, French, Polish, Korean, Japanese.
- Spanish tooltips no longer show fixed percentages (they're sandbox options).
- Build 41: vaccines are detected by item type instead of English display name (fixes translated games).
- Smaller download (unused model removed, posters resized).

## 1.x – Build 41
- Vaccine power sandbox options, Spanish translation, reduced XP gain, updated loot tables, moodle support.
