# AGENTS.md — space-shooty/game

Guidance for AI agents working in this directory.

## What this is

A 2D top-down space shooter built with **Godot 4.6**.
The player survives as long as possible while dodging meteors.
Score = seconds survived (incremented by a timer in `ui.gd`).
The game is built for **web export** (HTML5) and connects to a Node.js leaderboard backend.

## Engine & project settings

| Setting | Value |
|---|---|
| Godot version | 4.6 |
| Renderer | GL Compatibility (mobile-friendly) |
| Physics | Jolt Physics (3D), default 2D |
| Language | GDScript |

Project config is in `project.godot`. **Do not edit it by hand** — use the Godot editor for project settings, except for adding autoloads which can be done by editing the `[autoload]` section directly.

## Directory layout

```
game/
├── Assets/          ← Sprites, UI textures, power-up icons
├── Audio/           ← Sound effects and music tracks
├── Global/
│   ├── global.gd    ← Autoload "Global": game state + username persistence
│   ├── api.gd       ← Autoload "Api": HTTP wrapper for the backend
│   ├── settings.gd  ← Autoload "Settings": volume settings + track loader/saver
│   └── game_music.gd← Autoload "GameMusic": shuffled track player + song_started emitter
├── Scenes/          ← .tscn scene files (one per game object/screen)
├── Scripts/         ← .gd scripts attached to scenes
│   ├── level.gd         ← Main game loop: spawning, health, shield
│   ├── ui.gd            ← HUD: HP/shield icons, score timer, song popup
│   ├── player.gd        ← Movement (WASD/arrows) and shooting (Space/LMB)
│   ├── meteor.gd        ← Meteor spawn, movement, collision, destroy anim
│   ├── laser.gd         ← Laser projectile behaviour
│   ├── bonus_item.gd    ← Base for collectible items
│   ├── destroy_offscreen.gd ← Frees nodes that leave the viewport
│   ├── start_menu.gd    ← Main menu buttons (Play → game_start, How to Play, Leaderboard, Options, Credits)
│   ├── game_start.gd    ← Username entry + /game/start call; shared by first-play and restart
│   ├── game_over.gd     ← Score display + /game/end call + rank display
│   ├── leaderboard.gd   ← Paginated leaderboard screen
│   ├── options.gd       ← Audio options (volume & tracks) menu controller
│   ├── credits.gd       ← Credits screen with expandable sections
│   ├── how_to_play.gd   ← How to Play screen (WASD/arrows/shoot/leaderboard description)
│   └── ui.gd            ← HUD logic (including Now Playing popup)
├── default_bus_layout.tres ← Master, SFX, LobbyMusic, GameMusic audio buses
└── project.godot
```

## Autoloads (singletons)

Six autoloads are registered in `project.godot` and accessible from any script:

### `Settings` (`Global/settings.gd`)

Manages player options, loaded and saved automatically using `ConfigFile` at `user://settings.cfg`.
- `sfx_volume` (0.0 to 1.0)
- `lobby_music_volume` (0.0 to 1.0)
- `game_music_volume` (0.0 to 1.0)
- `enabled_tracks` (Array of resource paths for active in-game music tracks)

It applies these settings dynamically to the corresponding Godot AudioBuses on startup and whenever a setting changes.

### `GameMusic` (`Global/game_music.gd`)

Plays background music during gameplay. Routes through the `GameMusic` bus.
- Loads the enabled tracks from `Settings.enabled_tracks`.
- Shuffles them to play in random sequence.
- Emits `song_started(title: String)` when a new track starts.

### `LobbyMusic` (`Global/lobby_music.gd`)

Plays the start menu, credits, and game-over screens background music. Routes through the `LobbyMusic` bus.

### `Global` (`Global/global.gd`)

Holds shared game state across scenes.

```gdscript
var score: int = 0           # total points; written by ui.gd on ticks and item pops
var session_token: String = ""  # JWT from /game/start; cleared after /game/end
var username: String = ""    # set by the player in the start menu
var game_env: String = "production" # "dev" or "production"
```

On startup (`_ready`), `Global` reads the `GAME_ENV` environment variable (`OS.get_environment("GAME_ENV")`). If set to `"dev"` or `"development"`, it sets `game_env = "dev"`. If not set, it falls back to `OS.is_debug_build()`, making local editor runs default to `"dev"` and production exports default to `"production"`.

Helper functions:
- `Global.save_username(name)` — writes to `localStorage` on web; no-op on desktop
- `Global.load_username()` — reads from `localStorage` on web; returns `""` if none saved

**Do not add Flyons or upgrade state here** — that lives in `Upgrades`.

### `Upgrades` (`Global/upgrades.gd`)

Manages the Flyons currency system and all persistent upgrade levels.

#### Flyons

Flyons are the in-game currency earned at the end of each run:
`earned = floor(score / divisor)` where `divisor = max(1, 10 - flyons_rate_level * 2)`.

Flyons are displayed on the **Game Over** and **Shop** screens only (not the HUD).

#### Upgrade Registry

All upgrades are defined in the `UPGRADES` constant — an `Array[Dictionary]` at the top of `upgrades.gd`. Each entry has these balance-tunable fields:

```gdscript
{
    "id":          "ship_speed",       # unique key used in code
    "label":       "Ship Speed",       # display name in shop
    "description": "+75 speed/level",  # shown per-level in shop
    "icon":        "res://...",        # texture path, or "" for emoji default
    "base_cost":   30,                 # Flyons cost at level 0 → 1
    "cost_scale":  1.5,                # multiplier per level: cost = base * scale^level
    "max_level":   3,                  # hard cap
}
```

**Adding a new upgrade**: append one Dictionary to `UPGRADES`. The shop UI auto-generates cards from this array — no other files need to change.

#### Public API

```gdscript
Upgrades.get_flyons()          # → int: current balance
Upgrades.add_flyons(amount)    # add Flyons (call at game over)
Upgrades.get_level(id)         # → int: current level (0 = not purchased)
Upgrades.get_cost(id)          # → int: cost for next level (-1 if maxed)
Upgrades.can_buy(id)           # → bool: affordable and below max
Upgrades.try_buy(id)           # → bool: deduct + increment; false if can't
Upgrades.save()                # persist all data (call after purchases)
Upgrades.load_data()           # load data (called automatically in _ready)
```

#### Backend-Ready Abstraction

`save()` and `load_data()` are the only persistence entry points. They currently delegate to local `ConfigFile` (`user://settings.cfg`, section `[upgrades]`). When attaching a remote backend:

```gdscript
func save() -> void:
    _local_save()
    await _remote_save()  # ← add here; callers are unchanged
```

### `Api` (`Global/api.gd`)

Central HTTP helper. All backend calls go through here — do not use `HTTPRequest` nodes directly in scenes.

```gdscript
var result = await Api.start_game(username)   # POST /game/start
var result = await Api.end_game(token, score) # POST /game/end
var result = await Api.get_leaderboard(page)  # GET  /leaderboard?page=N&limit=20
```

All functions return a `Dictionary` with an `"ok"` key:
- `{ "ok": true, ... }` — success, other keys mirror the backend response
- `{ "ok": false, "error": "..." }` — any network, timeout, or server error

All requests have a 5.0-second timeout to prevent the client from hanging if the backend is offline.

The backend URL is `const BASE_URL := "http://localhost:3000"` in `api.gd`.
Change this if the port differs. Game and backend run on the same server behind Nginx.

## Scoring system

Score is tracked in `ui.gd` via a `ScoreTimer` node (5-second interval):

```gdscript
func _on_score_timer_timeout() -> void:
	_total_score += POINTS_PER_TICK
	$ScoreMargin/Label.text = str(_total_score)
	Global.score = _total_score
```

**Score = points accumulated during survival + Point Orb bonuses.**
- Players earn 50 points every 5 seconds.
- Players can shoot moving Neon Point Orbs 4 times to pop them and earn 50–200 bonus points.
- The HUD updates the score immediately and synchronizes it to `Global.score` which is sent to the backend on game over.
The leaderboard sorts by `score DESC` and displays both `score` (raw integer) and `time_played` (formatted as `m:ss`, e.g. 312 → `5:12`) as separate columns.

`time_played` is **not sent by the client** — the backend computes it from `startedAt` (in the session JWT) and the server clock when `/game/end` is called. Future changes to the scoring formula will only need to update the score value; `time_played` remains an authoritative measure of session duration.

## Physics layers

| Layer | Name |
|---|---|
| 1 | Player |
| 2 | Meteor |
| 3 | Walls |
| 4 | Laser |
| 5 | Bonus Items |

The laser-meteor collision relies on lasers (`Area2D`) only interacting with meteors — do not add the laser layer to other collision masks without careful testing.

## Audio & Music System

The project uses Godot's AudioServer bus system. Four buses are defined:
- `Master`: Parent of all buses.
- `SFX`: Sound effects (lasers, damage, explosions, game over sound). Nodes must have `bus = "SFX"`.
- `LobbyMusic`: Menu music track player (`LobbyMusic` autoload).
- `GameMusic`: In-game music track player (`GameMusic` autoload).

### "Now Playing" Song Popup
When a new song begins playing during level gameplay, `GameMusic` emits `song_started`. The HUD UI (`ui.gd`) listens for this and displays a semi-transparent, neon-bordered popup panel in the bottom-right corner. It animates using a Tween:
- Fades in over 0.4s.
- Remains visible for 5.0 seconds.
- Fades out over 0.4s.
- Tween animation is safely queued and reset when new tracks play immediately.

## Input actions

Defined in `project.godot`:

| Action | Keys / Buttons |
|---|---|
| `left` | A, ← |
| `right` | D, → |
| `up` | W, ↑ |
| `down` | S, ↓ |
| `shoot` | Space, Left Mouse Button |

## Game flow

```
start_menu.tscn
    │  (Play)
    ▼
game_start.tscn  (username entry if none saved → /game/start)
    │
    ▼
level.tscn
    │  (health reaches 0)
    ▼
game_over.tscn   (submits score via /game/end, shows rank)
    │  (Space/Enter)
    ▼
game_start.tscn  (skips UI — reuses saved username → /game/start)
    │
    ▼
level.tscn  (restart)

start_menu.tscn → how_to_play.tscn   (How to Play button)
start_menu.tscn → leaderboard.tscn   (Leaderboard button)
start_menu.tscn → options.tscn       (Options button)
start_menu.tscn → credits.tscn       (Credits button)
start_menu.tscn → upgrade_shop.tscn  (Upgrades button)
game_over.tscn  → upgrade_shop.tscn  (Go to Shop button)
```

- **`start_menu.gd`**: Play button navigates to `game_start.tscn`. No session logic here.
- **`game_start.gd`**: Owns all session-start logic. On `_ready`, if a saved username exists (restart path) it calls `Api.start_game()` immediately and skips the UI; otherwise it shows the username panel, validates input, and then calls `Api.start_game()`. On backend failure it shows a 1.5 s warning then proceeds (graceful degradation). After the token is stored in `Global.session_token` the scene transitions to `level.tscn`.
- **`level.gd`**: spawns meteors and bonus items, handles health and shield state. Reads upgrade values from `Upgrades` in `_ready()` (health, shield, bullet pattern, drop rate).
- **`game_over.gd`**: calls `Api.end_game()` on `_ready`, shows "Submitting score..." while waiting, then displays rank on success or an offline warning if the token is empty or the call fails. Clears `Global.session_token` after the call to prevent double submission. Awards Flyons via `Upgrades.add_flyons()` then calls `Upgrades.save()`. On Space/Enter navigates to `game_start.tscn` (not directly to `level.tscn`).
- **`upgrade_shop.gd`**: generates upgrade cards procedurally from `Upgrades.UPGRADES`. Each card has a buy button that calls `Upgrades.try_buy()`; on success, calls `Upgrades.save()` and refreshes all cards.
- **`leaderboard.gd`**: loads page 1 on `_ready`, renders rows with gold/silver/bronze for the top 3, supports Prev/Next pagination. Each row shows `score` as a plain integer and `time_played` formatted as `m:ss`.
- **`credits.gd`**: Manages the Credits screen containing expandable buttons for "Graphics & Sound" and "Music". Toggles display container visibility and updates arrow indicators dynamically. Handles clicking RichTextLabel URLs via `OS.shell_open`.
- **`how_to_play.gd`**: Manages the How to Play screen showing controls and leaderboard information.

## Conventions

- One `.gd` script per scene node where possible. Scripts live in `Scripts/`, scenes in `Scenes/`.
- Use **signals** for cross-node communication (e.g. `meteor.collision`, `player.laser`). Do not call parent node methods directly from child scripts.
- Use `get_tree().call_group('ui', 'method_name', arg)` to broadcast to all UI nodes (the `ui` group is set in the scene).
- Prefer `@export` variables for tunable values (speeds, counts) so they're editable in the Godot inspector without code changes.
- Do not put game logic in `.tscn` files — keep it in the corresponding `.gd` script.
- The `.godot/` directory is auto-generated by the editor. Do not commit changes to it except `project.godot`.
- **All backend calls must go through `Api`** — never instantiate `HTTPRequest` nodes manually in scene scripts.
- **Null-guard `Api` results**: always check `result.ok` before accessing other keys. Network failures and timeouts (5.0s limit) are normal when the player or backend is offline.

## Flyons Upgrade System

### Bullet spread patterns (`level.gd` — `_on_player_laser`)

The `bullet_amount` upgrade changes the firing pattern each run:

| Level | Pattern |
|---|---|
| 0 | 1 laser, straight up |
| 1 | 2 lasers, straight up |
| 2 | 3 lasers: forward + 45° left & right |
| 3 | 6 lasers: the level-2 pattern doubled |

Angles are set via `laser.rotation_degrees` before adding to the scene tree.

### Rotation-based laser movement (`laser.gd`)

`laser.gd` uses direction-vector movement derived from the node's rotation:
```gdscript
position += Vector2(sin(rotation), -cos(rotation)) * speed * delta
```
`rotation = 0` = straight up (backward compatible). Angled spread lasers travel at their rotation angle and are correctly freed by `destroy_offscreen.gd` when they leave the viewport.

## Known gotchas

### `JavaScriptBridge` — never reference directly by class name

`JavaScriptBridge` is a web-only class. Referencing it directly in GDScript causes a **compile failure on desktop/editor builds**, which silently makes the entire autoload `Nil` — every call to `Global.anything()` then fails with `"Nonexistent function '...' in base 'Nil'"`.

Always access it via the Engine reflection API:
```gdscript
if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
    var js = Engine.get_singleton("JavaScriptBridge")
    js.eval("...")
```

### `js.eval()` can return a Variant null

On a first web run with an empty `localStorage`, `js.eval("localStorage.getItem(...) || ''")` may return a Godot `null` variant (not an empty String). Always guard:
```gdscript
if result != null and result is String and result.length() > 0:
    # safe to use result
```

### `"in base 'Nil'"` errors

If you see `"Invalid call. Nonexistent function 'foo' in base 'Nil'"` when calling `Global.foo()` or `Api.foo()`, the autoload itself is `Nil`. The most common cause is a **compile error in the autoload's script** (e.g. a missing class reference). Check the autoload script for errors first.

## Running the game

Open the `game/` folder as a project in **Godot 4.6**. Press **F5** or the Play button to run.
There is no build step — GDScript is interpreted at runtime.

For leaderboard features to work, the backend must be running:
```bash
cd ../backend
npm run dev        # development
# or
docker compose up  # production
```
