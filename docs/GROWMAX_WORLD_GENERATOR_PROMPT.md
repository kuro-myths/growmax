# Growmax — Master Prompt: Procedural World & Geology Generator

## Role
Act as a senior gameplay engineer specializing in Three.js, procedural generation, deterministic simulation, and browser performance. Work directly in the existing Growmax codebase. Do not replace the game with a new demo or remove existing features.

## Project constraints
- Repository: `kuro-myths/growmax`
- Production branch: `main`
- Active client: `web/index.html` (HTML, CSS, JavaScript, Three.js)
- Deployment target: Vercel only. Do not introduce Railway, VPS, or a separate backend service.
- Preserve the existing Growmax gameplay: player movement, keyboard controls, world switching, seeded world names, planting, harvesting, inventory, hotbar, store, building blocks, world locks, local save migration, and existing UI.
- Existing save data must remain backward-compatible. Never clear localStorage or reset player progress as part of an upgrade.

## Objective
Upgrade the existing 3D tile world generator by combining:
1. Growtopia-inspired readable 2D tile layers and simple world identity.
2. Minecraft-inspired procedural geology, biome variation, caves, ores, underground fluids, and depth-based material distribution.
3. Growmax-specific configurable and inspectable generation, with deterministic output from the world seed.

## World model
- Keep the current playable surface grid at 24 × 24 tiles for compatibility with existing movement, farming, planting, and building systems.
- Keep surface gameplay coordinates and the existing player spawn/collision model stable.
- Generate a complete underground geology column for every surface coordinate.
- Current target strata:
  - Y=3: surface grass or beach sand.
  - Y=2..1: dirt/topsoil.
  - Y=0..-2: stone and stone variants.
  - Y=-3..-4: deepslate and deeper mineral-bearing strata.
  - Y=-5: bedrock floor, with deterministic irregular extra bedrock where appropriate.
- The bedrock floor must remain continuous enough to prevent a world with an open bottom.
- The underground model should include cave voids, ore veins, gravel, granite, diorite, andesite, lava pockets, and underground water.
- Keep all generated data associated with the active world; changing world names must produce a different world, while re-entering the same world must reproduce its generated terrain.

## Deterministic generation
- Use a stable string hash and seeded PRNG. Do not use Math.random() for world generation.
- Separate generation streams or derive stable sub-seeds for biome, surface, geology, caves, ores, and decorations so adding a tree does not reshuffle ore distribution.
- Same seed + same generator version + same settings must produce the same world.
- Store generator version and world seed metadata for future migrations.
- Do not overwrite player-created tile edits when switching between worlds or regenerating an existing world.

## Materials and depth rules
Include at minimum:
- Surface: grass, dirt, sand, water.
- Underground: stone, deepslate, gravel, granite, diorite, andesite.
- Ores: coal, iron, copper, gold, diamond, and emerald where biome/height rules permit.
- Fluids and cavities: cave air, lava, underground water.
- Foundation: bedrock.

Use depth-dependent ore rules. Rare ores must be substantially less common than common stone and dirt. Keep exact probability values configurable and documented; avoid presenting illustrative probabilities as official Minecraft or Growtopia values.

## Biomes
Implement deterministic biome selection, initially including:
- Plains / meadow
- Forest
- Jungle
- Savanna
- Desert / beach
- Snow or cold biome

Biome choice should affect surface palette, vegetation density, and suitable surface materials. It should not change the world seed or break old saves.

## Cave and fluid generation
- Use coherent noise or deterministic cellular/vein approaches rather than independent random holes only.
- Caves must form connected pockets or tunnels where practical.
- Lava should be biased toward deeper levels; water should be more common in higher underground aquifers.
- Prevent fluids from replacing the bedrock floor.
- Keep cave and fluid counts inspectable for debugging.

## Performance and rendering
- Avoid creating thousands of independent Three.js Mesh objects if an InstancedMesh or chunk-based approach is practical.
- Keep shadows and pixel ratio within existing performance limits.
- Render only visible/exposed underground faces or a deliberate world-edge cutaway; do not render every hidden voxel as a separate object.
- Preserve the existing surface tile objects and raycast metadata used by farming, planting, harvesting, and building.
- Dispose of generated geometries/materials or reuse shared materials when worlds are switched to avoid GPU memory leaks.
- Do not let underground collision or mesh objects interfere with the player's surface controls.

## Generator inspection UI
Provide an in-game geology inspector reachable from the world menu. It should show:
- Active world seed and biome.
- World dimensions and generator version.
- Y-level layer legend.
- Counts for bedrock, stone, deepslate, dirt, stone variants, each ore, caves, lava, and underground water.
- A clear note that counts are generated values for this world, not fixed game-wide constants.
- Responsive layout suitable for desktop and smaller screens.

## Persistence and safety
- Preserve the current localStorage key and save structure.
- Add new metadata without deleting or renaming existing fields.
- Migrate old worlds lazily and safely.
- Player edits, placed blocks, crops, and inventory must survive world switching and refresh.
- Never commit API keys, credentials, private URLs, or user data.

## Required verification
1. Check JavaScript syntax and browser console errors.
2. Confirm the page still initializes Three.js and renders a playable world.
3. Confirm WASD, arrow keys, jump, and typing into chat/input fields do not conflict.
4. Confirm existing world switching and localStorage saves still work.
5. Confirm planting, watering, harvesting, inventory, store, and block placement remain functional.
6. Generate two different seeds and confirm their terrain/biomes differ.
7. Generate the same seed twice and confirm identical biome, layer data, and ore/cave counts.
8. Confirm bedrock exists at the bottom and lava never appears below it.
9. Confirm the geology inspector displays accurate counts and does not crash on an old save.
10. Test the Vercel production build and inspect deployment logs before declaring deployment successful.

## Definition of done
The existing Growmax game remains playable, world generation is deterministic, underground strata and material distributions are generated and inspectable, legacy saves remain intact, and the Vercel deployment is verified. Report exactly what was changed, tests that passed, tests that could not be run, and any remaining limitations. Never claim a deployment or test succeeded without evidence.
