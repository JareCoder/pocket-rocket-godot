extends Node

## upgrades.gd — Autoload "Upgrades"
##
## Single source of truth for the Flyons upgrade system.
##
## ADDING A NEW UPGRADE
## ────────────────────
## Append one Dictionary to the UPGRADES constant below. No other files need
## to change — the shop UI auto-generates cards from this array at runtime.
##
## BACKEND INTEGRATION
## ───────────────────
## All persistence goes through save() and load_data(). When attaching a remote
## backend or user-management system, only those two methods need to grow.
## All callers (game_over.gd, upgrade_shop.gd) remain unchanged.

# ── Upgrade Registry ──────────────────────────────────────────────────────────
#
# Each entry is a Dictionary with these keys:
#   id          String  — unique key used in code (e.g. Upgrades.get_level("ship_speed"))
#   label       String  — display name shown in the shop UI
#   description String  — one-line effect description shown per level in the shop
#   icon        String  — res:// path to a texture, or "" for a default icon
#   base_cost   int     — Flyons cost to buy level 0 → 1
#   cost_scale  float   — multiplier applied each level: cost = base_cost * cost_scale^current_level
#   max_level   int     — hard cap (1–N). Set to -1 for uncapped (not recommended).

const UPGRADES: Array[Dictionary] = [
	{
		"id":          "starting_health",
		"label":       "Starting Health",
		"description": "+1 HP at the start of each run",
		"icon":        "res://Assets/PNG/UI/playerLife1_blue.png",
		"base_cost":   250,
		"cost_scale":  1.5,
		"max_level":   3,
	},
	{
		"id":          "starting_shield",
		"label":       "Starting Shield",
		"description": "+1 Shield at the start of each run",
		"icon":        "res://Assets/PNG/Power-ups/shield_gold.png",
		"base_cost":   300,
		"cost_scale":  1.5,
		"max_level":   3,
	},
	{
		"id":          "bullet_amount",
		"label":       "Bullet Amount",
		"description": "More lasers, less problems",
		"icon":        "",
		"base_cost":   400,
		"cost_scale":  1.5,
		"max_level":   3,
	},
	{
		"id":          "fire_rate",
		"label":       "Fire Rate",
		"description": "Shoot cooldown +10% per level (stacks)",
		"icon":        "",
		"base_cost":   350,
		"cost_scale":  1.5,
		"max_level":   3,
	},
	{
		"id":          "item_drop_rate",
		"label":       "Item Drop Rate",
		"description": "Increases bonus item spawn frequency",
		"icon":        "",
		"base_cost":   200,
		"cost_scale":  1.5,
		"max_level":   3,
	},
	{
		"id":          "ship_speed",
		"label":       "Ship Speed",
		"description": "+50 movement speed per level",
		"icon":        "res://Assets/PNG/playerShip1_blue.png",
		"base_cost":   300,
		"cost_scale":  1.5,
		"max_level":   3,
	},
	{
		"id":          "flyons_rate",
		"label":       "Flyons Rate",
		"description": "Earn more Flyons per run (divisor −2 per level)",
		"icon":        "",
		"base_cost":   500,
		"cost_scale":  1.5,
		"max_level":   3,
	},
]

# ── Internal State ────────────────────────────────────────────────────────────

var _flyons: int = 0
var _levels: Dictionary = {}  # { upgrade_id: int }

const _SAVE_PATH := "user://settings.cfg"
const _SECTION := "upgrades"

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Initialise all upgrade levels to 0
	for upg: Dictionary in UPGRADES:
		_levels[upg.id] = 0
	load_data()

# ── Public API — Flyons ───────────────────────────────────────────────────────

## Returns the current Flyons balance.
func get_flyons() -> int:
	return _flyons

## Adds Flyons to the balance (always non-negative).
func add_flyons(amount: int) -> void:
	_flyons = max(0, _flyons + amount)

# ── Public API — Upgrades ─────────────────────────────────────────────────────

## Returns the current owned level of an upgrade (0 = not purchased).
func get_level(id: String) -> int:
	return _levels.get(id, 0)

## Returns the full upgrade Dictionary for a given id, or an empty dict if not found.
func get_upgrade(id: String) -> Dictionary:
	for upg: Dictionary in UPGRADES:
		if upg.id == id:
			return upg
	return {}

## Returns the Flyons cost to buy the *next* level of an upgrade.
## Returns -1 if the upgrade is already at max level or not found.
func get_cost(id: String) -> int:
	var upg := get_upgrade(id)
	if upg.is_empty():
		return -1
	var current := get_level(id)
	if upg.max_level >= 0 and current >= upg.max_level:
		return -1
	return int(upg.base_cost * pow(upg.cost_scale, current))

## Returns true if the player can afford and is below max level for this upgrade.
func can_buy(id: String) -> bool:
	var cost := get_cost(id)
	return cost >= 0 and _flyons >= cost

## Attempts to purchase the next level of an upgrade.
## Returns true on success, false if the player can't afford it or it's maxed.
func try_buy(id: String) -> bool:
	if not can_buy(id):
		return false
	var cost := get_cost(id)
	_flyons -= cost
	_levels[id] += 1
	return true

## DEBUG — resets all upgrade levels and Flyons to zero and saves.
## Remove calls to this before shipping.
func debug_reset() -> void:
	_flyons = 0
	for upg: Dictionary in UPGRADES:
		_levels[upg.id] = 0
	save()

# ── Persistence — Public Surface ──────────────────────────────────────────────
## These are the only two methods callers should ever use.
## To attach a remote backend: add an await _remote_save() call inside save(),
## and an await _remote_load() call inside load_data(). Nothing else changes.

## Persists all upgrade data. Call after any purchase or Flyons change.
func save() -> void:
	_local_save()
	# TODO: await _remote_save() — attach remote user-management here

## Loads all upgrade data. Called automatically in _ready().
func load_data() -> void:
	_local_load()
	# TODO: await _remote_load() — attach remote user-management here

# ── Persistence — Local Implementation ───────────────────────────────────────

func _local_save() -> void:
	var cfg := ConfigFile.new()
	# Load existing file first so we don't wipe other sections (e.g. [audio])
	cfg.load(_SAVE_PATH)
	cfg.set_value(_SECTION, "flyons", _flyons)
	for id: String in _levels:
		cfg.set_value(_SECTION, id, _levels[id])
	cfg.save(_SAVE_PATH)

func _local_load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) != OK:
		return  # No save file yet — keep defaults
	_flyons = cfg.get_value(_SECTION, "flyons", 0)
	for upg: Dictionary in UPGRADES:
		_levels[upg.id] = cfg.get_value(_SECTION, upg.id, 0)
