extends Control

## upgrade_shop.gd
##
## Procedurally generates one upgrade card per entry in Upgrades.UPGRADES.
## To add a new upgrade, append a Dictionary to the UPGRADES constant in
## Global/upgrades.gd — no changes needed here.

var start_menu_scene: PackedScene = load("res://Scenes/start_menu.tscn")

# Card node references, keyed by upgrade id
var _card_nodes: Dictionary = {}

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	_build_cards()
	_refresh_ui()
	
	var is_dev := Global.game_env == "dev"
	$MarginContainer/VBoxOuter/Footer/GiveFlyonsButton.visible = is_dev
	$MarginContainer/VBoxOuter/Footer/ClearUpgradesButton.visible = is_dev

# ── Card Generation ───────────────────────────────────────────────────────────

func _build_cards() -> void:
	for upg: Dictionary in Upgrades.UPGRADES:
		var card := _make_card(upg)
		_card_nodes[upg.id] = card
		%UpgradeGrid.add_child(card)

func _make_card(upg: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(210, 240)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2, 0.92)
	style.border_color = Color(0.4, 0.3, 0.6, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Add margin inside the panel
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	margin.add_child(inner)

	# Icon
	if upg.icon != "":
		var icon_rect := TextureRect.new()
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(0, 48)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if ResourceLoader.exists(upg.icon):
			icon_rect.texture = load(upg.icon)
		inner.add_child(icon_rect)
	else:
		# Emoji placeholder label when no icon is set
		var emoji := Label.new()
		emoji.text = _default_emoji(upg.id)
		emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji.add_theme_font_size_override("font_size", 32)
		inner.add_child(emoji)

	# Label (upgrade name)
	var name_label := Label.new()
	name_label.text = upg.label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.name = "Desc"
	desc_label.text = upg.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.75))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(desc_label)

	# Level pips
	var pips_container := HBoxContainer.new()
	pips_container.name = "Pips"
	pips_container.alignment = BoxContainer.ALIGNMENT_CENTER
	pips_container.add_theme_constant_override("separation", 4)
	inner.add_child(pips_container)

	# Cost label
	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	inner.add_child(cost_label)

	# Buy button
	var buy_btn := Button.new()
	buy_btn.name = "BuyButton"
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.add_theme_font_size_override("font_size", 14)
	buy_btn.pressed.connect(_on_buy_pressed.bind(upg.id))
	inner.add_child(buy_btn)

	_update_card(upg.id)
	return panel

func _default_emoji(id: String) -> String:
	match id:
		"bullet_amount": return "🔫"
		"fire_rate":     return "⚡"
		"item_drop_rate":return "🎁"
		"flyons_rate":   return "🥮"
		_:               return "⭐"

# ── UI Refresh ────────────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	%FloyonsBalanceLabel.text = str(Upgrades.get_flyons()) + " Flyons"
	for upg: Dictionary in Upgrades.UPGRADES:
		_update_card(upg.id)

func _update_card(id: String) -> void:
	var card: PanelContainer = _card_nodes.get(id)
	if not card:
		return

	var upg := Upgrades.get_upgrade(id)
	var current_level := Upgrades.get_level(id)
	var max_level: int = upg.max_level
	var cost := Upgrades.get_cost(id)

	# Rebuild pip row
	var pips: HBoxContainer = card.find_child("Pips", true, false)
	if pips:
		for child in pips.get_children():
			child.queue_free()
		for i in max_level:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(18, 10)
			pip.color = Color(0.3, 0.9, 0.5) if i < current_level else Color(0.25, 0.2, 0.35)
			var pip_style := StyleBoxFlat.new()
			pip_style.set_corner_radius_all(3)
			pip.add_theme_stylebox_override("panel", pip_style)
			pips.add_child(pip)

	# Update cost label
	var cost_label: Label = card.find_child("CostLabel", true, false)
	if cost_label:
		if current_level >= max_level:
			cost_label.text = "MAX"
			cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			cost_label.text = str(cost) + " Flyons"
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	# Update buy button
	var buy_btn: Button = card.find_child("BuyButton", true, false)
	if buy_btn:
		if current_level >= max_level:
			buy_btn.text = "MAX"
			buy_btn.disabled = true
		elif Upgrades.can_buy(id):
			buy_btn.text = "Buy"
			buy_btn.disabled = false
		else:
			buy_btn.text = "Can't afford"
			buy_btn.disabled = true

# ── Signals ───────────────────────────────────────────────────────────────────

func _on_buy_pressed(id: String) -> void:
	if Upgrades.try_buy(id):
		Upgrades.save()
		_refresh_ui()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_packed(start_menu_scene)

# ── Debug helpers (remove before shipping) ────────────────────────────────────

func _on_give_flyons_pressed() -> void:
	Upgrades.add_flyons(100)
	Upgrades.save()
	_refresh_ui()

func _on_clear_upgrades_pressed() -> void:
	Upgrades.debug_reset()
	_refresh_ui()

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	if has_node("MarginContainer"):
		var margin_container = $MarginContainer
		var h_margin = 15 if size.x < 600 else 40
		var v_margin = 15 if size.y < 500 else 30
		margin_container.add_theme_constant_override("margin_left", h_margin)
		margin_container.add_theme_constant_override("margin_right", h_margin)
		margin_container.add_theme_constant_override("margin_top", v_margin)
		margin_container.add_theme_constant_override("margin_bottom", v_margin)
		
	if has_node("MarginContainer/VBoxOuter/Footer"):
		$MarginContainer/VBoxOuter/Footer.vertical = size.x < 600
