# Fieldwork 4.8 — Choices & Consequences (native Godot 4)

This document describes **implemented source behaviour**, its limits, and verification requirements. It is not an in-engine test report. The 4.7 native agriculture, sprite assets, 24 plots and fixed terrain are retained.

## Game-design intent

An important decision now has three layers:

1. **Immediate action:** A choice changes actual cash, irrigation, goods, field properties, pests, livestock condition, reputation and/or neighbour trust.
2. **Timed effects:** Existing farming multipliers can change for a stated number of simulated hours. These are capped and expire without an external clock.
3. **Consequences later:** Some of the existing events begin an authored village storyline. An NPC may return after game hours with a follow-up decision, and again for a final result.

An NPC doesn't rewrite existing farm history. The game records what the player did and uses that choice to initialize a future branch. Once started, a storyline is not restarted by repeated instances of the same original event.

## Content

- The **29 original random event types / 87 choices** remain in `data/decisions.json`.
- **6 storylines, 12 follow-up chapters, 36 additional choices** are in `data/event_chains_48.json`. This means 41 distinct event chapters and 123 authored choice options across both catalogs.
- Each storyline has a root event from the 4.7 content followed by two new chapters:

| Storyline | Initial event | NPC | Later chapters |
|---|---|---|---|
| The water agreement | `irrigation_cooperative` | Mateo | Water committee / Water-use audit |
| Living soil | `soil_research` | Inés | Soil trial / Results |
| A balanced orchard | `pest_hotspot` | Lila | Pest survey / Second pest wave |
| Tools for the valley | `machinery_breakdown` | Bruno | Workshop / Harvest window |
| The herd and its keeper | `livestock_inspection` | Rosa | Shelter plan / Herd review |
| The village fair | `tourism_invite` | Clara | Fair planning / Visitor feedback |

Root events still arise under the original time/difficulty conditions. To make the stories easier to discover, the **Village stories / Historias del pueblo** screen also offers a voluntary meeting for **€20**, provided no urgent event is open and at least **72 simulated hours** have passed since the previous invitation. You can invite each storyline only once. The livestock storyline requires that you already own animals. The meeting opens the **original event**, rather than awarding its benefit automatically.

### Timing and deterministic replay

- The first follow-up is scheduled 48–96 simulated hours after the original event, depending on the story. Second follow-ups are scheduled 96–120 hours after the first.
- Only the farm simulation advances the clock. Rendering and opening the story board never advance simulation time or draw from the simulation RNG.
- Due follow-ups take priority over unrelated random events when no event is currently active. Other due follow-ups remain in the queue until the active event is resolved.
- A risky option has a fixed authored probability and consumes **one RNG draw only upon commitment**. The selected outcome is stored in the event history.
- A player may pay **€18** to request advice during a follow-up. The advice is available once per stage, does not itself draw RNG, reveals the actual success estimate, and adds ten percentage points to a risky option's success probability, capped at 95%. It is not a guarantee.
- Choosing an option and its random outcome is one atomic simulation action. Insufficient funds or goods means the whole action fails without keeping partial modifications or RNG changes.

### Effects linked to actual farming rules

The follow-ups use existing model effects such as `water_saver`, `pest_suppression`, `nutrient_shield`, `work_efficiency`, `labor_slowdown`, `animal_welfare`, `pollinator_bonus`, and `market_trust`. They also act directly on real water stocks, first-field nutrients and aphids, animal condition, produce inventory and reputation. These are fictional, explicitly authored game-balance parameters, **not agronomic predictions**.

### Village trust and NPC memory

- Trust ranges from **-10 to +10** per character and persists across saves.
- Key original decisions and the two subsequent decisions can increase or decrease trust; paid neighbour help also increases trust with a 24-hour per-NPC cooldown.
- Talking about **Our relationship / Nuestra relación** is free and shows the actual saved trust level.
- With at least **4 trust points**, Mateo improves water saving slightly; Clara improves selling terms; Lila improves pest suppression; Rosa adds a small welfare bonus. Other neighbours retain trust and story records without undocumented bonuses.
- Trust changes are recorded in `decisions.relationship_history` and shown in the journal.

### UI

- A **Village stories / Historias del pueblo** tab appears in Community navigation, with quick access from the world guide and farm dashboard.
- It displays started storylines, upcoming timed visits, neighbour trust, and available €20 meeting invitations. Unavailable invitations explain their restrictions.
- Decision cards show bilingual descriptions, immediate effects, risks, and action cost. An advice button is shown for unresearched follow-up stages. Chance percentages appear after advice is bought.
- The journal combines legacy and follow-up decisions, including actual cash, water, reputation and trust deltas, success/setback outcomes, and dated relationship changes.
- English and Spanish remain selectable from the initial screen.

## Save migration and player safety

- New saves have **schema 5** and format `FW_NATIVE_4_8`, written to `user://fieldwork_native_4_8.json`.
- Existing 4.7 saves remain at `user://fieldwork_native_4_5.json`, a separate original file. The new loader checks this original and its two rolling backups if no valid 4.8 save exists.
- Schema 4 is copied into schema 5 by **adding empty story branches, a follow-up queue, relationship values, and research flags**, without altering the original fields, markets, animals, buildings, cash, XP, RNG or elapsed time. Earlier supported native migrations remain available.
- Three manual save slots continue to work; old slots are upgraded in memory before validation. A new 4.8 write updates the slot and maintains its two recovery backups.
- A 4.8 save is **not backward-readable by the 4.7 game**. For backwards use, keep the original 4.7 save or export.
- Browser game JSON uses a different protocol and is not automatically migrated.

## Tests and remaining limits

Static checks do not prove that Godot can launch the scripts. Run in the extracted project directory with Godot 4.4+:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/story_48_smoke.gd
godot --headless --path . --script res://tests/ui_story_48_smoke.gd
```

Then run `RUN_NATIVE_TESTS.sh` or `RUN_NATIVE_TESTS.bat` to exercise inherited test scripts. Test the screen at desktop and narrower window sizes, including event-choice cards and the Spanish variant. A future Godot interpreter/compiler run is **required** before release approval; the source-only audit in this package is not an engine verification.

No Godot 4.8 executable or Android package is included. No network synchronization is deployed. World art and simulation balancing from 4.7 were deliberately not redesigned in this event-focused release.
