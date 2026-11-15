# Fieldwork 5.8 — Beyond the Farm: implementation notes

## Design

The 5.8 release extends existing native Godot 5.7, rather than adding a separate UI or overwriting the simulation. The entire update is built from four connected components:

1. `scripts/BeyondFarm58.gd`: eight projects with three chapters each, profession definitions, localized text, defaults and save validation.
2. `scripts/NativeFarm.gd`: transactional actions `chooseProfession58` and `advanceProject58`; travel, energy, money, supplies, XP and neighbour trust are all actual gameplay state changes.
3. `scripts/Overworld.gd`: two new destinations and progress badges on the valley map. Map selections still use native Godot signals.
4. `scripts/Main.gd`: regional projects screen accessible from desktop, mobile screen picker, the Explorer screen, countryside activities, and the Valley screen.

## How projects work

Each region has a three-stage project: survey, contribution, conclusion. Stages can be completed at most once in the same region per simulated day. The player must actually travel to the region. Stage two consumes the listed goods. The final stage grants a one-time supply reward, reputation and a partner relationship benefit.

The final project stage offers two approaches:

- **Stewardship:** +3 reputation and +2 partner trust, plus profession bonuses.
- **Trade:** +EUR 65 and +1 reputation/trust, plus profession bonuses.

Both outcomes preserve the same completed project and prevent repeat claims. The amounts are game design values, not real-world prices.

## Specializations

- **Pathfinder:** 15% lower expedition fees and 20% lower expedition energy cost.
- **Naturalist:** 30% additional project XP and 1 extra reputation when finishing a project.
- **Community Artisan:** two additional goods upon project completion, subject to full warehouse capacity verification.

The first profession selection is free. To change profession, the player needs EUR 90 and at least 12 in-game days since the previous selection.

## New travel regions

- **Bluewater Lake:** 4-hour travel, herb foraging, renewable reeds, a jetty discovery and a lakeside habitat activity.
- **Old Stone Quarry:** 5-hour travel, stone foraging, renewable stone, a heritage gate discovery and a quarry survey activity.

Existing region and activity mechanics apply unchanged: funds, energy, storage capacity, once-a-day site limits and weather/event rules.

## Save policy

Current writes go only to `user://fieldwork_native_5_8.json` and `user://fieldwork_slots_58/`. 5.7 and older files remain fallbacks. Schema 10, the preexisting checksum envelope, and all previous simulation fields remain unchanged. Older saves receive a default `countryside54.beyond58` extension **in memory** when loaded. New saves validate chapter bounds, journal entries, profession IDs and completion count.

## Testing

- Offline: `python3 tests/qa_58.py`.
- Actual engine parser and all native tests: `RUN_NATIVE_TESTS.bat` or `RUN_NATIVE_TESTS.sh` using Godot 4.4+.
- New engine smoke test: `tests/beyond_farm_58_smoke.gd`.

The offline audit verifies structure and resource integrity but is **not** equivalent to a Godot parser run or a playable export.
