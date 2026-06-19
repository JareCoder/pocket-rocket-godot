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
│   └── api.gd       ← Autoload "Api": HTTP wrapper for the backend
├── Scenes/          ← .tscn scene files (one per game object/screen)
├── Scripts/         ← .gd scripts attached to scenes
│   ├── level.gd         ← Main game loop: spawning, health, shield
│   ├── ui.gd            ← HUD: HP/shield icons, score timer
│   ├── player.gd        ← Movement (WASD/arrows) and shooting (Space/LMB)
│   ├── meteor.gd        ← Meteor spawn, movement, collision, destroy anim
│   ├── laser.gd         ← Laser projectile behaviour
│   ├── bonus_item.gd    ← Base for collectible items
│   ├── destroy_offscreen.gd ← Frees nodes that leave the viewport
│   ├── start_menu.gd    ← Main menu + username entry + /game/start call
│   ├── game_over.gd     ← Score display + /game/end call + rank display
│   ├── leaderboard.gd   ← Paginated leaderboard screen
│   ├── music_player.gd  ← Background music looping
│   └── ui.gd            ← HUD logic
└── project.godot
```

## Autoloads (singletons)

Two autoloads are registered in `project.godot` and accessible from any script:

### `Global` (`Global/global.gd`)

Holds shared game state across scenes.

```gdscript
var score: int = 0           # seconds survived; written by ui.gd every second
var session_token: String = ""  # JWT from /game/start; cleared after /game/end
var username: String = ""    # set by the player in the start menu
```

Helper functions:
- `Global.save_username(name)` — writes to `localStorage` on web; no-op on desktop
- `Global.load_username()` — reads from `localStorage` on web; returns `""` if none saved

### `Api` (`Global/api.gd`)

Central HTTP helper. All backend calls go through here — do not use `HTTPRequest` nodes directly in scenes.

```gdscript
var result = await Api.start_game(username)   # POST /game/start
var result = await Api.end_game(token, score) # POST /game/end
var result = await Api.get_leaderboard(page)  # GET  /leaderboard?page=N&limit=20
```

All functions return a `Dictionary` with an `"ok"` key:
- `{ "ok": true, ... }` — success, other keys mirror the backend response
- `{ "ok": false, "error": "..." }` — any network or server error

The backend URL is `const BASE_URL := "http://localhost:3000"` in `api.gd`.
Change this if the port differs. Game and backend run on the same server behind Nginx.

## Scoring system

Score is tracked in `ui.gd` via a `ScoreTimer` node (1-second interval):

```gdscript
func _on_score_timer_timeout() -> void:
    seconds_elapsed += 1
    $ScoreMargin/Label.text = str(seconds_elapsed)
    Global.score = seconds_elapsed
```

**Score = integer seconds survived.** This is the value sent to the backend on game over.
The leaderboard displays it formatted as `m:ss` (e.g. 312 → `5:12`).

## Physics layers

| Layer | Name |
|---|---|
| 1 | Player |
| 2 | Meteor |
| 3 | Walls |
| 4 | Laser |
| 5 | Bonus Items |

The laser-meteor collision relies on lasers (`Area2D`) only interacting with meteors — do not add the laser layer to other collision masks without careful testing.

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
    │  (Play → username panel → /game/start)
    ▼
level.tscn
    │  (health reaches 0)
    ▼
game_over.tscn   (submits score via /game/end, shows rank)
    │  (Space/Enter)
    ▼
level.tscn  (restart)

start_menu.tscn → leaderboard.tscn  (Leaderboard button)
```

- **`start_menu.gd`**: Play button shows a `UsernamePanel` overlay. On confirm, validates the name, calls `Api.start_game()`, stores the returned JWT in `Global.session_token`, then transitions to `level.tscn`. If the backend is unreachable, an inline warning is shown and the game starts anyway (graceful degradation — no score will be submitted).
- **`level.gd`**: spawns meteors and bonus items, handles health and shield state.
- **`game_over.gd`**: calls `Api.end_game()` on `_ready`, shows "Submitting score..." while waiting, then displays rank on success or an offline warning if the token is empty or the call fails. Clears `Global.session_token` after the call to prevent double submission on restart.
- **`leaderboard.gd`**: loads page 1 on `_ready`, renders rows with gold/silver/bronze for the top 3, supports Prev/Next pagination.

## Conventions

- One `.gd` script per scene node where possible. Scripts live in `Scripts/`, scenes in `Scenes/`.
- Use **signals** for cross-node communication (e.g. `meteor.collision`, `player.laser`). Do not call parent node methods directly from child scripts.
- Use `get_tree().call_group('ui', 'method_name', arg)` to broadcast to all UI nodes (the `ui` group is set in the scene).
- Prefer `@export` variables for tunable values (speeds, counts) so they're editable in the Godot inspector without code changes.
- Do not put game logic in `.tscn` files — keep it in the corresponding `.gd` script.
- The `.godot/` directory is auto-generated by the editor. Do not commit changes to it except `project.godot`.
- **All backend calls must go through `Api`** — never instantiate `HTTPRequest` nodes manually in scene scripts.
- **Null-guard `Api` results**: always check `result.ok` before accessing other keys. Network failures are normal (player may be offline).

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
