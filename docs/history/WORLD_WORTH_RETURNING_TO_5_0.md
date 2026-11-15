# Fieldwork 5.0 — A World Worth Returning To

This update follows the provided Fieldwork roadmap for 5.0: more villagers, advanced progression, festivals, environmental detail, accessibility, and improved Spanish support. It is implemented directly in the supplied 4.9 **Godot 2D** project and does not replace the earlier farming mechanics.

## Village story progression

- Each of the **10 existing NPCs** has **three ordered authored chapters** in `data/world_worth_50.json` (30 chapters total).
- Chapter requirements specify a valid item in the existing goods catalog and an exact inventory quantity. Deliveries are consumed, logged, and cannot be repeated once completed.
- Choose **Share** to receive 65% of the default monetary return plus an additional trust point; choose **Trade** for the full payment and normal trust points. Both grant experience.
- Chapters are gated by a 24-hour cooldown. Completing the third chapter also gives a reputation increase.
- Older linked events from Fieldwork 4.8 and their follow-up decisions remain in the previous event system. These new delivery chapters supplement them.

## Six professional certificates

| Certificate | In-game modifier |
|---|---|
| Soil Specialist | Reduces paid pest scouting cost |
| Water Engineer | Reduces irrigation water use |
| Animal Carer | Reduces veterinary visit expense |
| Master Mechanic | Reduces machinery servicing costs |
| Market Mentor | Adds a sale price premium |
| Artisan Master | Increases some processing yields |

Certification requires all requirements from its catalog entry: an existing course, enough mastery XP in the named track, enough recorded work activity, and sufficient cash. Payment, ownership and benefit are persisted in schema 7.

## Seasonal festivals and achievements

Four authored festivals correspond to spring, summer, autumn and winter. The seasons cycle every 12 in-game days. Registrations open only on **days 9–12** of each season. Each festival allows three types of exhibit: produce, artisan, or community. These require goods already stored on the farm; exhibiting consumes those goods and charges EUR 25.

Only one entry is permitted in each season, regardless of category. An outcome score depends on inventory quality, current neighbour trust, current reputation and seeded randomness. Gold, silver and participation receive different prizes and reputation. History records the score, category and season, and persists across saves. The game does not promise a deterministic high-value prize.

Each season also has a distinct optional objective linked to recorded activity counters. Goal progress is measured against the season's starting snapshot; when the next season begins, a single summary is logged and any earned reward is granted. Reports are accessible in the Festivals menu.

## Native user interface

New management tabs in `scripts/Main.gd`:

- **Community50 / Historias vecinales:** chapter status, item requirements, available inventory and Share/Trade actions.
- **Festivals50 / Fiestas:** registration, progress toward this season's objective, festival history and season reports.
- **Certifications50 / Acreditaciones:** course/mastery/work requirements, current certificate and fee, and active qualification effects.

The **Character** screen includes a wardrobe; **Settings** offers reduced motion, explicit dry/wet/normal soil labels, and an optional seasonal soundtrack with volume control. Original sound files are in `assets/audio/` and are generated for the project, not copied from third-party songs. There is no voice acting or dialogue audio.

2D village bunting and lighting render during festival registration days. This does not change simulation outcomes. The 4.9 machinery, soil, livestock and business panels remain.

## State, saves and compatibility

- `scripts/WorldWorth50.gd` reads `data/world_worth_50.json`, computes seasonal key/goal progress and evaluates certificate criteria.
- `scripts/NativeFarm.gd` owns transactional actions `completeNpcChapter`, `earnCertificate`, `festivalEnter` and `setFarmerLook`, and a per-day season finalization hook.
- New schema `7` stores `world50` progress; auto-save path `fieldwork_native_5_0.json`, manual slots directory `fieldwork_slots_50`.
- Migrated 4.9/schema-6 farms gain clean 5.0 progress without wiping their old resources or NPC relationship histories. 4.8/schema-5 upgrades through existing 4.9 conversion first. Old save paths stay distinct.
- The game continues to reject invalid actions instead of granting free resources; inputs and costs are validated before commit.

## Compilers fixes from the reported 4.9 build

1. Duplicate `kind` local in animal breeding was changed to `animal_definition`.
2. `selected_build_slot` now names **only the signal** in `World.gd`; the property is `active_build_slot` and all callers use the new name.
3. Both scripts and every local `preload("res://...")` target are checked by the Python source audit. **This is not a Godot engine parse check.**

## Verification / limitations

Python release gate: `python3 tests/qa_50.py`; it checks data completeness, referenced assets, 5.0 script wiring, many duplicate-name cases and balanced delimiters. Native engine tests `tests/world_worth_50_smoke.gd` and `tests/ui_world_50_smoke.gd` target transactions, saves, migration, UI and settings, with inherited tests runnable using `RUN_NATIVE_TESTS.sh` (or `.bat`).

**Godot could not be executed in the packaging environment.** Native parse, test assertions, runtime performance, layout and sound must be verified on a local Godot 4.4+ installation before calling 5.0 engine-tested. This release does not add 3D, multiplayer, mobile APK packaging, online sync or cloud saves. Some legacy technical messages may remain in English; 5.0 authored content and menus are bilingual.
