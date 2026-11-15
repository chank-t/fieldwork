# NativeFarm action index (source-derived)

The authoritative mutation API is `farm.act(kind: String, args: Dictionary = {}) -> Dictionary`. All actions below are top-level `kind` cases in `NativeFarm._apply()` as packaged. This is a navigation reference, **not** a replacement for the validation, costs and availability conditions in the implementation. To preview financial effects use `farm.quote(kind, args)` where appropriate.

On failure `act()` restores the preceding farm state. UI changes must not bypass the action engine. The index is generated from the 6.0 source; it does not guarantee that every action is available at every point in play.

## Land and crops

| `kind` | Argument keys referenced in case |
| --- | --- |
| `configurePlot` | `plotType` |
| `coverCrop` | No direct `args` access in this case |
| `aerateSoil` | No direct `args` access in this case |
| `plantHedgerow` | No direct `args` access in this case |
| `scoutField` | No direct `args` access in this case |
| `plant` | `cropId`, `variety` |
| `harvest` | No direct `args` access in this case |
| `irrigate` | `mm` |
| `fertilize` | `element`, `kg` |
| `useManure` | No direct `args` access in this case |
| `compost` | No direct `args` access in this case |
| `mulch` | No direct `args` access in this case |
| `treat` | `method` |
| `release` | `species` |
| `spreadCompost` | No direct `args` access in this case |
| `buyField` | No direct `args` access in this case |

## Animals

| `kind` | Argument keys referenced in case |
| --- | --- |
| `feedingPlan` | `animalId`, `mode` |
| `vetVisit` | `animalId` |
| `breedAnimal` | `animalId` |
| `buyAnimal` | `animalId`, `count` |
| `animalCare` | `animalId` |

## Construction and resources

| `kind` | Argument keys referenced in case |
| --- | --- |
| `buyMachine` | `machineId` |
| `serviceMachine` | `machineId` |
| `relocateBuilding` | `buildingId`, `slot` |
| `gatherMaterials` | `regionId` |
| `makeCompost` | No direct `args` access in this case |
| `relocateDecoration` | `decorationId`, `slot` |
| `craftDecoration` | `decorationId`, `slot` |
| `build` | `buildingId`, `slot` |
| `upgrade` | `buildingId` |
| `buySupply` | `goodId`, `kg` |
| `buyWater` | `m3` |
| `process` | `recipeId`, `kg` |
| `automation` | `enabled` |

## Economy and contracts

| `kind` | Argument keys referenced in case |
| --- | --- |
| `choosePath` | `path` |
| `sell` | `goodId`, `kg` |
| `offer` | `offerId`, `accept` |
| `contractAccept` | `contractId` |
| `contractDeliver` | `contractId` |

## Learning, travel and community

| `kind` | Argument keys referenced in case |
| --- | --- |
| `enrollCourse` | `courseId` |
| `learnTalent` | `talentId` |
| `tutorial` | `skip` |
| `visit` | No direct `args` access in this case |
| `buyGear` | No direct `args` access in this case |
| `explore` | `regionId` |
| `rest` | No direct `args` access in this case |
| `helpNeighbour` | `npcId` |
| `eventChoice` | `choice` |
| `eventResearch` | No direct `args` access in this case |
| `inviteStory` | `arcId` |
| `festivalEnter` | `category` |
| `completeNpcChapter` | `npcId`, `approach` |
| `earnCertificate` | `certificateId` |
| `discoverSite54` | `siteId` |
| `countrysideActivity54` | `activityId` |
| `chooseProfession58` | `profession` |
| `advanceProject58` | `regionId`, `approach` |
| `meetNeighbour54` | `npcId` |
| `claimQuest` | `questId` |

## Player, clock and wardrobe

| `kind` | Argument keys referenced in case |
| --- | --- |
| `move` | `x`, `y` |
| `inspect` | No direct `args` access in this case |
| `tick` | `hours` |
| `setFarmerLook` | No direct `args` access in this case |
| `saveOutfitPreset` | No direct `args` access in this case |
| `applyOutfitPreset` | No direct `args` access in this case |
| `clearOutfitPreset` | No direct `args` access in this case |


**Before extending an action:** inspect the case in `scripts/NativeFarm.gd`, add negative transaction tests and confirm the save invariants. Argument keys shown may not all be required; check the original defaults and conditions.
