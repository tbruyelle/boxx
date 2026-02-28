# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**Boxx** — a Godot 4.6 game (GDScript). 3D isometric grid-based shooter where a player auto-fires at targets (walls, monsters) while navigating a destructible grid with bonus/malus cells.

## Engine & Runtime

- **Godot 4.6.1** (Steam install): `"$HOME/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64"`
- Renderer: `gl_compatibility`
- Resolution: 720x1280 (portrait), stretch mode `canvas_items`

## Key Commands

```bash
GODOT="$HOME/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64"

# Run the game
"$GODOT" --path /home/tom/src/boxx

# Open in editor
"$GODOT" --editor --path /home/tom/src/boxx

# Validate project (headless, check for errors)
"$GODOT" --headless --path /home/tom/src/boxx --check-only 2>&1
```

Always kill the running game process before relaunching:
```bash
ps aux | grep godot | grep -v grep | awk '{print $2}' | xargs kill 2>/dev/null
```

## Architecture

### Game States (State enum in game_level.gd)

```
SPLASH → (any key) → INTRO → PLAYING → GAME_OVER → (any key) → SPLASH
                                  ↓ (target destroyed)
                                INTRO (next level)
```

- **SPLASH**: Grid visible, no player/target, animated "BoXX" title floating, "Appuyez sur une touche"
- **INTRO**: Player drops from sky (bounce tween), then target slides in from top (back tween)
- **PLAYING**: Auto-fire, movement, timer countdown, bonuses active
- **GAME_OVER**: Game frozen, "GAME OVER" panel, any key returns to splash

### Scene Tree (main.tscn)

```
GameLevel (Node3D)           — scripts/game_level.gd — state machine + orchestration
├── GameManager (Node)       — scripts/game_manager.gd — level config, progression
├── Camera3D                 — orthographic (size=30), isometric 45°
├── DirectionalLight3D
├── TitleLabel (Node3D)      — 4 child Label3D (B=gray, o=green, X=red, X=blue), billboard mode
├── Grid (Node3D)            — scripts/grid.gd — generates/manages 8x10 cell grid
├── Player (Node3D)          — scripts/player.gd — movement + auto-fire
│   ├── FireTimer (Timer)
│   └── Model/Body (MeshInstance3D)
├── Target (Node3D)          — scripts/target.gd — wall/monster HP + hit flash
│   └── MeshInstance3D
└── UI (Control)
    ├── HPBar (ProgressBar)
    ├── LevelLabel (Label)
    ├── FireRateLabel (Label) — "X.XX tir/sec"
    ├── TimerLabel (Label)    — "M:SS" countdown
    ├── PressKeyLabel (Label) — splash/game over prompt
    └── GameOverPanel (PanelContainer)
```

### Signal Flow

1. **Player.moved(old_pos, new_pos)** → GameLevel destroys old cell, applies new cell's bonus
2. **Player.fired(bullet_count)** → GameLevel spawns Bullet instances
3. **Bullet reaches target** → calls `GameLevel.on_bullet_hit(damage)` via group lookup (`"game_level"`)
4. **Target.hp_changed** → UI HPBar update
5. **Target.destroyed** → GameManager advances level → GameLevel plays intro for next level

### Grid System

- `Grid` uses a `Dictionary[Vector2i, CellData]` to track cell state and bonus type
- `grid_to_world()` converts grid coordinates to 3D positions (centered on origin)
- Grid size: 8 columns x 10 rows, `cell_size = 2.0`
- Player starts at `(grid_size.x/2, grid_size.y-1)` — bottom center
- Target sits one row above row 0

### Cell Bonuses (CellBonus enum in grid.gd)

| Value | Label | Color | Effect |
|-------|-------|-------|--------|
| 0 | NONE | Gray | No effect |
| 1 | FIRE_RATE_X2 | Green | Halve fire interval (min 0.25s) |
| 2 | FIRE_RATE_HALF | Red | Double fire interval |
| 3 | BULLETS_PLUS_10 | Blue | +10 burst bullets |

### Level Config

`game_manager.gd` stores `level_data` array. Each entry: `target_type` (wall/monster), `target_hp`, `time_limit` (seconds). Add new levels by appending to this array.

### Instanced Scenes

- `scenes/cell.tscn` — grid cell (BoxMesh + Label3D with bonus text)
- `scenes/bullet.tscn` — projectile (SphereMesh, emissive yellow)
- `scenes/main.tscn` — full game level

## Input Actions

| Action | Keys |
|--------|------|
| move_up | W / Arrow Up |
| move_down | S / Arrow Down |
| move_left | A / Arrow Left |
| move_right | D / Arrow Right |
| Any key | Splash → start, Game Over → restart |

## Conventions

- All game scripts in `scripts/`, all scenes in `scenes/`
- Use typed GDScript (type hints on function signatures and variables)
- Signals for inter-node communication — avoid direct node references where possible
- Bullets find the game level via `get_tree().get_first_node_in_group("game_level")`
- UI visibility is toggled per state in `game_level.gd` — don't set `visible` in .tscn defaults for state-dependent nodes
