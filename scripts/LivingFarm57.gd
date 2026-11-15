extends RefCounted
## Fieldwork 5.7: presentation-only anchor rules for machines and garden slots.
## Kept outside the simulation: this file does not create resources or mutate saves.

const MACHINE_ORDER: Array = ["cultivator", "pump", "harvester", "mixer"]
const GARDEN_SLOTS: int = 24
const MOVE_CASH: float = 18.0
const MOVE_ENERGY: float = 4.0

static func garden_anchor(slot: int) -> Vector2:
    # Uses the same positions as the pre-5.7 farm, preserving saved layouts.
    return Vector2(12.2 + float(slot % 12) * 4.0, 9.9 if slot < 12 else 49.0)

static func machine_anchor(index: int) -> Vector2:
    # A compact yard in the village band, clear of the 24 fields.
    return Vector2(20.0 + float(index) * 8.5, 5.6)

static func decoration_at(decorations: Array, slot: int) -> Dictionary:
    for item in decorations:
        if int(item.get("slot", -1)) == slot:
            return item
    return {}

static func open_slots(decorations: Array) -> Array:
    var slots: Array = []
    for slot in range(GARDEN_SLOTS):
        if decoration_at(decorations, slot).is_empty():
            slots.append(slot)
    return slots

static func machine_broken(machine: Dictionary, current_hour: int) -> bool:
    return not machine.is_empty() and int(machine.get("broken_until", 0)) > current_hour
