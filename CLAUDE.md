# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**Boxx** — a Godot 4.4+ game (GDScript). 3D isometric grid-based shooter where a player auto-fires at targets (walls, monsters) while navigating a destructible grid with bonus/malus cells.

## Engine & Runtime

- **Godot 4.6.1** (Steam install): `"$HOME/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64"`
- Renderer: `gl_compatibility`
- Resolution: 1280x720, stretch mode `canvas_items`

## Key Commands

```bash
GODOT="$HOME/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64"

# Run the game
"$GODOT" --path /home/tom/src/boxx

# Run a specific scene
"$GODOT" --path /home/tom/src/boxx scenes/main.tscn

# Open in editor
"$GODOT" --editor --path /home/tom/src/boxx

# Validate project (headless, check for errors)
"$GODOT" --headless --path /home/tom/src/boxx --check-only 2>&1
```

## Architecture

### Scene Tree (main.tscn)

```
GameLevel (Node3D)           — scripts/game_level.gd — orchestrates everything
├── GameManager (Node)       — scripts/game_manager.gd — level config, progression
├── Camera3D                 — orthographic, isometric angle
├── DirectionalLight3D
├── Grid (Node3D)            — scripts/grid.gd — generates/manages cell grid
├── Player (Node3D)          — scripts/player.gd — movement + auto-fire
│   ├── FireTimer (Timer)
│   └── Model/Body (MeshInstance3D)
├── Target (Node3D)          — scripts/target.gd — wall/monster HP
│   └── MeshInstance3D
└── UI (Control)
    ├── HPBar (ProgressBar)
    └── LevelLabel (Label)
```

### Signal Flow

1. **Player.moved(old_pos, new_pos)** → GameLevel destroys old cell, applies new cell's bonus
2. **Player.fired(bullet_count)** → GameLevel spawns Bullet instances
3. **Bullet reaches target** → calls `GameLevel.on_bullet_hit(damage)` via group lookup
4. **Target.hp_changed** → UI HPBar update
5. **Target.destroyed** → GameManager advances level → GameLevel resets

### Grid System

- `Grid` uses a `Dictionary[Vector2i, CellData]` to track cell state and bonus type
- `grid_to_world()` converts grid coordinates to 3D positions (centered on origin)
- Player starts at `(grid_size.x/2, grid_size.y-1)` — bottom center
- Target sits one row above row 0

### Cell Bonuses (CellBonus enum in grid.gd)

| Value | Label | Effect |
|-------|-------|--------|
| 0 | NONE | No effect |
| 1 | FIRE_RATE_X2 | Halve fire interval (green cell) |
| 2 | FIRE_RATE_HALF | Double fire interval (red cell) |
| 3 | BULLETS_PLUS_10 | Fire 10 extra bullets (blue cell) |

### Instanced Scenes

- `scenes/cell.tscn` — single grid cell (MeshInstance3D + Label3D)
- `scenes/bullet.tscn` — projectile (SphereMesh, emissive yellow)
- `scenes/main.tscn` — full game level

### Level Config

`game_manager.gd` stores level definitions in `level_data` array. Each entry has `target_type` (wall/monster) and `target_hp`. Add new levels by appending to this array.

## Input Actions

| Action | Keys |
|--------|------|
| move_up | W / Arrow Up |
| move_down | S / Arrow Down |
| move_left | A / Arrow Left |
| move_right | D / Arrow Right |

## Conventions

- All game scripts in `scripts/`, all scenes in `scenes/`
- Use typed GDScript (type hints on function signatures and variables)
- Signals for inter-node communication — avoid direct node references where possible
- Bullets find the game level via `get_tree().get_first_node_in_group("game_level")`
