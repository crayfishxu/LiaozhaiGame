extends Control

## ==================================================================
## 聊斋美人 · 卡牌肉鸽战斗原型（Godot 4.4）
##
## 核心机制：
##   每张卡牌有「显相」与「本相」两面，打出后翻面。
##   显相偏防御/稳定，本相偏爆发/自损 —— 同一张牌，两套用法。
##
## 结构分层：
##   CardDB / EnemyDB  → 纯数据（改数值只动这里）
##   AssetLoader       → 资源接入（美术放图即生效）
##   CardView / EnemyView → 视图（只负责画，不含规则）
##   Battle            → 规则与流程（本文件）
##
## 本文件不含任何美术资源引用，全部通过 AssetLoader 取。
## ==================================================================

# ---------------- 配色 ----------------
const C_MOON := Color("#EAE6DC")
const C_LOTUS := Color("#C9A8B4")
const C_ROUGE := Color("#A83E4C")
const C_CINNABAR := Color("#B23A30")
const C_DAI := Color("#2E3D45")
const C_CROW := Color("#1A2229")
const C_INK := Color("#12181C")
const C_GOLD := Color("#B08D3F")
const C_MOSS := Color("#5A6B52")
const C_BLOCK := Color("#A9BEC7")

# ---------------- 规则常量 ----------------
const START_HP := 50
const ENERGY_PER_TURN := 3
const DRAW_PER_TURN := 5

# ---------------- 移动端 UI 缩放 ----------------
## 设计基准 1024x672（见 project.godot），所有字号按此系数放大，
## 使手机横屏（1080p）下的实际字高达到可读水平。
const UI_S := 1.3

# ---------------- 运行时状态 ----------------
var player_hp: int = START_HP
var player_max_hp: int = START_HP
var player_block: int = 0
var energy: int = ENERGY_PER_TURN
var max_energy: int = ENERGY_PER_TURN
var grudge: int = 0
var player_poison: int = 0
var thorns: int = 0

# ---- 一局与地图 ----
var relics: RelicEngine = RelicEngine.new()
var encounter: Dictionary = {}
var node: Dictionary = {}
var grievance: int = 0          # 委屈层数（仅玩家）
var player_weak: int = 0
var exhaust_pile: Array = []
var _next_energy: int = 0
var _no_attack: bool = false
var _free_play: bool = false
var _turn_damage: int = 0
var _grievance_awarded: bool = false
var _curse_tax_paid: bool = false
var _map_view: MapView = null
var _panel: PanelContainer = null
var _oc: CenterContainer = null
var _victory_kind: String = ""
var _victory_gold: int = 0
var _victory_heal: int = 0
var _relic_pending: String = ""
var _remove_cb: Callable = Callable()
var _view_origin: String = ""
var _prev_mode: String = ""

var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []

var enemies: Array = []
var wave: int = 0
var powers: Dictionary = {}
var first_card_played: bool = false
var busy: bool = false
var selected_index: int = -1
var game_active: bool = false

# ---------------- UI 引用 ----------------
var ui_theme: Theme
var layer_label: Label
var chapter_label: Label
var bg_tex: TextureRect
var hp_fill: ColorRect
var hp_label: Label
var grudge_label: Label
var draw_label: Label
var discard_label: Label
var block_label: Label
var energy_box: HBoxContainer
var energy_label: Label
var field_box: HBoxContainer
var hand_box: HBoxContainer
var end_turn_btn: Button
var overlay: Control
var panel_vb: VBoxContainer
var menu_btn: Button
var target_hint: Label
var grievance_label: Label
var relic_btn: Button
var _pause_open: bool = false
## 当前弹窗种类：intro / reward / pause / lang / win / lose / ""
## 切换语言要重建整个 UI，靠这个把玩家送回到原来的那一屏
var _panel_mode: String = ""
## 战后三选一的候选项要留住，否则切语言重开面板会重新摇一次
var _reward_picks: Array = []
var _reward_sides: Array = []


func _ready() -> void:
	I18N.load_saved()
	_build_theme()
	_build_ui()
	start_game()


# ==================================================================
# 系统返回键（Android）
# ==================================================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_requested()


## 返回键语义：暂停菜单开着就回到原来那一屏，否则呼出暂停菜单
func _on_back_requested() -> void:
	if overlay.visible and _pause_open:
		_resume()
		return
	_show_pause()


# ==================================================================
# 主题（中文字体：走系统字体，避免打包字体文件）
# ==================================================================
func _build_theme() -> void:
	var f := SystemFont.new()
	f.font_names = I18N.font_names()
	ui_theme = Theme.new()
	ui_theme.default_font = f
	ui_theme.default_font_size = int(14 * UI_S)


# ==================================================================
# UI 构建
# ==================================================================
func _build_ui() -> void:
	# 底色
	var bg := ColorRect.new()
	bg.color = C_INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# [ART] 战斗背景：res://art/bg/battle_bg_{层数}.png，缺失时回退 battle_bg.png
	bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bgimg := AssetLoader.battle_bg()
	if bgimg != null:
		bg_tex.texture = bgimg
	else:
		bg_tex.visible = false
	add_child(bg_tex)

	# [ART] 背景压暗层：保证 UI 在任意背景图上的可读性
	var bg_dim := ColorRect.new()
	bg_dim.color = Color(C_INK.r, C_INK.g, C_INK.b, 0.44)
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.theme = ui_theme
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	margin.add_child(root)

	_build_topbar(root)
	_build_field(root)
	_build_midbar(root)
	_build_handzone(root)
	_build_botbar(root)
	_build_overlay()


func _mk_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(round(size * UI_S)))
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _build_topbar(root: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 44)
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)

	# 左上角给悬浮的菜单按钮留出空间（按钮本体在 _build_overlay 之后创建，
	# 保证它永远压在弹窗之上，任何界面状态下都能点到）
	var menu_gap := Control.new()
	menu_gap.custom_minimum_size = Vector2(46, 1)
	top.add_child(menu_gap)

	layer_label = _mk_label(I18N.t("ui.layer1"), 12, Color("#D46B60"))
	top.add_child(layer_label)

	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.15)
	sep.custom_minimum_size = Vector2(1, 14)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(sep)

	chapter_label = _mk_label(I18N.t("ui.chapter1"), 12, Color(0.92, 0.90, 0.86, 0.62))
	top.add_child(chapter_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	var hp_wrap := HBoxContainer.new()
	hp_wrap.add_theme_constant_override("separation", 10)
	hp_wrap.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(hp_wrap)

	hp_wrap.add_child(_mk_label(I18N.t("w.hp"), 11, Color(0.92, 0.90, 0.86, 0.58)))

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(160, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_wrap.add_child(bar)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.12)
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(bar_bg)

	hp_fill = ColorRect.new()
	hp_fill.color = C_CINNABAR
	hp_fill.size = Vector2(160, 8)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(hp_fill)

	hp_label = _mk_label("50 / 50", 13, C_MOON)
	hp_label.custom_minimum_size = Vector2(70, 0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_wrap.add_child(hp_label)


func _build_field(root: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)

	field_box = HBoxContainer.new()
	field_box.add_theme_constant_override("separation", 64)
	field_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(field_box)


func _build_midbar(root: VBoxContainer) -> void:
	var mid := HBoxContainer.new()
	mid.custom_minimum_size = Vector2(0, 26)
	root.add_child(mid)

	var gw := HBoxContainer.new()
	gw.add_theme_constant_override("separation", 9)
	mid.add_child(gw)
	gw.add_child(_mk_label(I18N.t("w.grudge"), 12, Color(0.92, 0.90, 0.86, 0.42)))
	grudge_label = _mk_label("0", 16, C_CINNABAR)
	gw.add_child(grudge_label)
	block_label = _mk_label("", 12, C_BLOCK)
	gw.add_child(block_label)

	grievance_label = _mk_label("", 12, C_LOTUS)
	gw.add_child(grievance_label)

	relic_btn = Button.new()
	relic_btn.text = I18N.t("ui.relics") + " 0"
	relic_btn.focus_mode = Control.FOCUS_NONE
	relic_btn.custom_minimum_size = Vector2(66, 24)
	relic_btn.add_theme_font_size_override("font_size", int(11 * UI_S))
	relic_btn.add_theme_color_override("font_color", Color("#C9A8B4"))
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(0.92, 0.90, 0.86, 0.06)
	rsb.border_color = Color(0.92, 0.90, 0.86, 0.20)
	rsb.set_border_width_all(1)
	rsb.set_corner_radius_all(2)
	relic_btn.add_theme_stylebox_override("normal", rsb)
	relic_btn.add_theme_stylebox_override("hover", rsb)
	relic_btn.add_theme_stylebox_override("pressed", rsb)
	relic_btn.pressed.connect(_show_relics)
	gw.add_child(relic_btn)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(sp)

	# 选中需要指定目标的卡时，这里会亮起来告诉玩家下一步做什么
	target_hint = _mk_label(I18N.t("ui.target_hint"), 12, Color("#E39A8E"))
	target_hint.visible = false
	mid.add_child(target_hint)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(18, 1)
	mid.add_child(sp2)

	var piles := HBoxContainer.new()
	piles.add_theme_constant_override("separation", 20)
	mid.add_child(piles)
	piles.add_child(_mk_label(I18N.t("ui.pile_draw"), 11, Color(0.92, 0.90, 0.86, 0.3)))
	draw_label = _mk_label("0", 11, Color(0.92, 0.90, 0.86, 0.62))
	piles.add_child(draw_label)
	piles.add_child(_mk_label(I18N.t("ui.pile_discard"), 11, Color(0.92, 0.90, 0.86, 0.3)))
	discard_label = _mk_label("0", 11, Color(0.92, 0.90, 0.86, 0.62))
	piles.add_child(discard_label)


func _build_handzone(root: VBoxContainer) -> void:
	var wrap := CenterContainer.new()
	wrap.custom_minimum_size = Vector2(0, 232)
	root.add_child(wrap)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	wrap.add_child(vb)

	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 14)
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hand_box)

	var er := HBoxContainer.new()
	er.alignment = BoxContainer.ALIGNMENT_CENTER
	er.add_theme_constant_override("separation", 8)
	vb.add_child(er)

	energy_box = HBoxContainer.new()
	energy_box.add_theme_constant_override("separation", 6)
	er.add_child(energy_box)

	energy_label = _mk_label("3 / 3", 12, Color(0.92, 0.90, 0.86, 0.45))
	er.add_child(energy_label)


func _build_botbar(root: VBoxContainer) -> void:
	var bot := CenterContainer.new()
	bot.custom_minimum_size = Vector2(0, 52)
	root.add_child(bot)

	end_turn_btn = Button.new()
	end_turn_btn.text = I18N.t("ui.end_turn")
	end_turn_btn.custom_minimum_size = Vector2(240, 48)
	end_turn_btn.focus_mode = Control.FOCUS_NONE
	end_turn_btn.add_theme_font_size_override("font_size", int(15 * UI_S))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.92, 0.90, 0.86, 0.06)
	normal.border_color = Color(0.92, 0.90, 0.86, 0.28)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.92, 0.90, 0.86, 0.14)
	hover.border_color = Color(0.92, 0.90, 0.86, 0.5)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.70, 0.23, 0.19, 0.28)

	end_turn_btn.add_theme_stylebox_override("normal", normal)
	end_turn_btn.add_theme_stylebox_override("hover", hover)
	end_turn_btn.add_theme_stylebox_override("pressed", pressed)
	end_turn_btn.add_theme_stylebox_override("disabled", normal)
	end_turn_btn.add_theme_color_override("font_color", C_MOON)
	end_turn_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	end_turn_btn.add_theme_color_override("font_disabled_color", Color(0.92, 0.90, 0.86, 0.3))
	end_turn_btn.pressed.connect(_on_end_turn)
	bot.add_child(end_turn_btn)


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = ui_theme
	add_child(overlay)

	var ob := ColorRect.new()
	ob.color = Color(0.031, 0.043, 0.055, 0.76)
	ob.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(ob)

	var oc := CenterContainer.new()
	oc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(oc)
	_oc = oc

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.10, 0.13, 0.15, 1.0)
	psb.border_color = Color(0.92, 0.90, 0.86, 0.16)
	psb.set_border_width_all(1)
	psb.content_margin_left = 40
	psb.content_margin_right = 40
	psb.content_margin_top = 34
	psb.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", psb)
	oc.add_child(panel)
	_panel = panel

	panel_vb = VBoxContainer.new()
	panel_vb.add_theme_constant_override("separation", 14)
	panel.add_child(panel_vb)

	# ---- 悬浮菜单按钮（在 overlay 之后入树 → 永远可点）----
	menu_btn = Button.new()
	menu_btn.text = "≡"
	menu_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu_btn.position = Vector2(16, 10)
	menu_btn.custom_minimum_size = Vector2(44, 44)
	menu_btn.size = Vector2(44, 44)
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.z_index = 200
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.07, 0.09, 0.11, 0.62)
	msb.border_color = Color(0.92, 0.90, 0.86, 0.30)
	msb.set_border_width_all(1)
	msb.set_corner_radius_all(4)
	var msb_h := msb.duplicate() as StyleBoxFlat
	msb_h.bg_color = Color(0.70, 0.23, 0.19, 0.55)
	msb_h.border_color = C_CINNABAR
	msb_h.set_border_width_all(1)
	menu_btn.add_theme_stylebox_override("normal", msb)
	menu_btn.add_theme_stylebox_override("hover", msb_h)
	menu_btn.add_theme_stylebox_override("pressed", msb_h)
	menu_btn.add_theme_font_size_override("font_size", int(26 * UI_S))
	menu_btn.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.86))
	menu_btn.pressed.connect(_show_pause)
	add_child(menu_btn)


# ==================================================================
# 游戏流程
# ==================================================================
func start_game() -> void:
	Run.new_run()
	_sync_from_run()
	game_active = false
	busy = false
	_hide_overlay()
	_clear_field()
	_show_intro()


## 把 Run 的长期状态灌进战斗
func _sync_from_run() -> void:
	player_hp = Run.hp
	player_max_hp = Run.max_hp
	grudge = 0
	player_block = 0
	player_poison = 0
	thorns = 0
	grievance = 0
	player_weak = 0
	powers.clear()
	relics.setup(Run.relics, self)
	_refresh_all()


func _clear_field() -> void:
	for c in field_box.get_children():
		field_box.remove_child(c)
		c.queue_free()
	enemies.clear()


func _enter_run() -> void:
	_hide_overlay()
	_show_map()


func start_encounter(enc: Dictionary, node_data: Dictionary = {}) -> void:
	encounter = enc
	node = node_data
	game_active = true
	busy = false
	selected_index = -1
	player_block = 0
	player_poison = 0
	thorns = 0
	grievance = 0
	player_weak = 0
	powers.clear()
	exhaust_pile.clear()
	hand.clear()
	discard_pile.clear()
	_turn_damage = 0
	_grievance_awarded = false
	_curse_tax_paid = false
	_no_attack = false
	_free_play = Run.free_play_next
	Run.free_play_next = false
	_next_energy = 0

	relics.setup(Run.relics, self)
	max_energy = ENERGY_PER_TURN + relics.max_energy_bonus()
	energy = max_energy

	draw_pile = Run.deck.duplicate(true)
	draw_pile.shuffle()

	var cfg: Dictionary = EnemyDB.LAYERS[Run.layer]
	layer_label.text = I18N.t(str(cfg["name"]))
	chapter_label.text = I18N.t(str(cfg["chapter"]))
	if bg_tex != null:
		var bgimg := AssetLoader.battle_bg(Run.layer)
		if bgimg != null:
			bg_tex.texture = bgimg
			bg_tex.visible = true

	_clear_field()
	var keys: Array = enc.get("enemies", [])
	var scale := float(enc.get("scale", 1.0))
	for i in keys.size():
		_spawn_enemy(str(keys[i]), i, scale)

	relics.on_battle_start()
	_refresh_all()
	begin_player_turn(true)


func _spawn_enemy(key: String, idx: int, scale: float = 1.0) -> void:
	if not EnemyDB.ENEMIES.has(key):
		return
	var data: Dictionary = (EnemyDB.ENEMIES[key] as Dictionary).duplicate(true)
	data["key"] = key
	if scale != 1.0:
		data["hp"] = int(round(float(data["hp"]) * scale))
	var ev := EnemyView.new()
	field_box.add_child(ev)
	ev.setup(data, idx)
	ev.clicked.connect(_on_enemy_clicked)
	enemies.append({
		"key": key,
		"seed": data,
		"hp": int(data["hp"]),
		"max_hp": int(data["hp"]),
		"block": 0,
		"poison": 0,
		"weak": 0,
		"bind": 0,
		"weaken": 0,
		"atk_bonus": 0,
		"move_idx": 0,
		"moves": data["moves"],
		"intent": {},
		"dead": false,
		"view": ev,
	})


func _add_grudge(n: int) -> void:
	if n == 0:
		return
	grudge += n
	Run.grudge_peak = maxi(Run.grudge_peak, grudge)
	relics.on_grudge_changed()


func _add_block(n: int) -> void:
	if n <= 0:
		return
	player_block += n
	Run.block_total += n
	Audio.play_sfx("block", 0.10)


## 手牌里是否有某张祟
func _has_curse(key: String) -> bool:
	for inst in hand:
		if str(inst["key"]) == key:
			return true
	return false


func begin_player_turn(first: bool = false) -> void:
	Audio.play_sfx("turn", 0.04)
	if player_hp * 3 < Run.max_hp:
		Audio.play_sfx("low_hp", 0.0)
	busy = false
	selected_index = -1
	player_block = 0
	thorns = 0
	_turn_damage = 0
	_grievance_awarded = false
	_curse_tax_paid = false
	_no_attack = false
	energy = max_energy + _next_energy
	_next_energy = 0
	first_card_played = false

	Run.rounds += 1

	if player_weak > 0:
		player_weak -= 1

	if player_poison > 0:
		var pd := player_poison
		player_hp -= pd
		player_poison -= 1
		_float_at(_player_anchor(), "-%d" % pd, C_ROUGE)

	# 酱板鸭：留在手里就每回合回 1 点魂火
	var ducks := 0
	for inst in hand:
		if str(inst["key"]) == "jiangbanya":
			ducks += 1
	if ducks > 0:
		player_hp = mini(player_max_hp, player_hp + ducks)
		_float_at(_player_anchor(), "+%d" % ducks, C_MOSS)

	if bool(powers.get("grudge_turn", false)):
		_add_grudge(2)

	relics.on_turn_start()

	_draw_cards(relics.draw_per_turn() + (relics.first_turn_draw() if first else 0))
	if first:
		relics.on_first_hand_ready()

	_schedule_intents()
	_refresh_all()


func _schedule_intents() -> void:
	for e in enemies:
		if bool(e["dead"]):
			continue
		if int(e["bind"]) > 0:
			e["intent"] = {"kind": "sleep"}
			continue
		var moves: Array = e["moves"]
		var m: Dictionary = moves[int(e["move_idx"]) % moves.size()]
		e["intent"] = m
		e["move_idx"] = int(e["move_idx"]) + 1


func _draw_cards(n: int) -> void:
	var limit := _hand_limit()
	var got := 0
	for i in n:
		if hand.size() >= limit:
			break
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			draw_pile.shuffle()
			discard_pile.clear()
		hand.append(draw_pile.pop_back())
		got += 1
	if got > 0:
		Audio.play_sfx("draw", 0.06)


## 手牌上限（阴气 -1，蚀心蛊 +2）
func _hand_limit() -> int:
	var limit := relics.hand_limit()
	for inst in hand:
		if str(inst["key"]) == "yinqi":
			limit -= 1
	return maxi(1, limit)


func _on_end_turn() -> void:
	if busy or not game_active:
		return
	busy = true
	selected_index = -1

	if hand.size() >= 3:
		Run.skipped += 1

	# 祟：邪祟扣血 / 妄念弃牌
	var lose := 0
	var discard_n := 0
	for inst in hand:
		var ck := str(inst["key"])
		if ck == "xiesui":
			lose += 2
		elif ck == "wangnian":
			discard_n += 1
	if lose > 0:
		player_hp -= lose
		_float_at(_player_anchor(), "-%d" % lose, C_ROUGE)
	for i in discard_n:
		var pool: Array = []
		for j in hand.size():
			if str(hand[j]["key"]) != "wangnian" and str(hand[j]["key"]) != "yezhang":
				pool.append(j)
		if pool.is_empty():
			break
		var j: int = pool[randi() % pool.size()]
		discard_pile.append(hand[j])
		hand.remove_at(j)
		Run.discards += 1

	# 委屈：回合结束按层数给障
	if grievance > 0:
		_add_block(grievance * 3)
		_float_at(_player_anchor(), "+%d" % (grievance * 3), C_BLOCK)

	relics.on_turn_end()

	for e in enemies:
		if not bool(e["dead"]) and int(e["hp"]) <= 0:
			_kill_enemy(e)

	for c in hand:
		discard_pile.append(c)
	hand.clear()
	_refresh_hand()
	_refresh_all()
	await get_tree().create_timer(0.26).timeout
	await _enemy_turn()


func _enemy_turn() -> void:
	for e in enemies:
		if bool(e["dead"]):
			continue

		if int(e["bind"]) > 0:
			e["bind"] = int(e["bind"]) - 1
			_float_at(_enemy_anchor(e), I18N.t("ui.bound"), C_DAI)
			_refresh_all()
			await get_tree().create_timer(0.34).timeout
			continue

		var it: Dictionary = e["intent"]
		var kind := str(it.get("kind", "attack"))
		var val := int(it.get("val", 0)) + int(e.get("atk_bonus", 0))

		if kind == "attack":
			var hits := int(it.get("hits", 1))
			var total := 0
			for h in hits:
				var dmg := val
				if int(e["weaken"]) > 0:
					dmg -= int(e["weaken"])
				if int(e["weak"]) > 0:
					dmg = int(floor(float(dmg) * 0.75))
				dmg = max(0, dmg)
				total += _damage_player(dmg)
			_float_at(_player_anchor(), "-%d" % total, C_ROUGE)
			if thorns > 0 and total > 0:
				_hit_enemy(e, thorns)
				_float_at(_enemy_anchor(e), "-%d" % thorns, C_ROUGE)
				(e["view"] as EnemyView).play_hit_fx()
			if int(it.get("poison", 0)) > 0:
				var add := relics.poison_taken(int(it["poison"]))
				player_poison += add
				_float_at(_player_anchor(), "%s +%d" % [I18N.t("w.poison"), add], C_MOSS)
			if int(it.get("self", 0)) > 0:
				_hit_enemy(e, int(it["self"]))
				_float_at(_enemy_anchor(e), "-%d" % int(it["self"]), C_ROUGE)
		elif kind == "defend":
			e["block"] = int(e["block"]) + val
			_float_at(_enemy_anchor(e), "+%d" % val, C_BLOCK)
		elif kind == "debuff":
			var add := relics.poison_taken(val)
			player_poison += add
			_float_at(_player_anchor(), "%s +%d" % [I18N.t("w.poison"), add], C_MOSS)
		elif kind == "weak":
			player_weak += val
			_float_at(_player_anchor(), "%s %d" % [I18N.t("w.weak"), val], C_LOTUS)
		elif kind == "buff":
			e["atk_bonus"] = int(e.get("atk_bonus", 0)) + val
			_float_at(_enemy_anchor(e), "+%d" % val, C_GOLD)
		elif kind == "summon":
			for i in val:
				_spawn_enemy("youhun", enemies.size(), 0.6)
			_float_at(_enemy_anchor(e), I18N.t("i.summon"), C_LOTUS)

		if int(e["poison"]) > 0:
			var pd := int(e["poison"])
			e["hp"] = int(e["hp"]) - pd
			e["poison"] = int(e["poison"]) - 1
			_float_at(_enemy_anchor(e), "-%d" % pd, C_MOSS)

		if int(e["weak"]) > 0:
			e["weak"] = int(e["weak"]) - 1
		if int(e["weaken"]) > 0:
			e["weaken"] = int(e["weaken"]) - 1
		if int(e["hp"]) <= 0:
			_kill_enemy(e)

		_refresh_all()
		await get_tree().create_timer(0.44).timeout

	if player_hp <= 0:
		_game_over(false)
		return
	if _all_dead():
		_battle_victory()
		return
	begin_player_turn()


func _damage_player(dmg: int) -> int:
	var d := dmg

	# 委屈：消耗 1 层减免 3 点（先于障结算）
	if grievance > 0 and d > 0:
		grievance -= 1
		d = max(0, d - 3)
		_float_at(_player_anchor(), "%s -1" % I18N.t("w.grievance"), C_LOTUS)

	d = relics.damage_taken(d)
	d += _curse_count("yuannianchanshen")

	if player_block > 0:
		var absorbed: int = mini(player_block, d)
		player_block -= absorbed
		d -= absorbed
	if d > 0:
		Audio.play_sfx("hurt")
		player_hp -= d
		_turn_damage += d
		Run.max_hit = maxi(Run.max_hit, d)
		_add_grudge(2 + (2 if bool(powers.get("grudge_hurt", false)) else 0))
		relics.on_hurt(d)
		if not _grievance_awarded and _turn_damage >= 10:
			_grievance_awarded = true
			if grievance < 3:
				grievance += 1
				_float_at(_player_anchor(), "%s +1" % I18N.t("w.grievance"), C_LOTUS)
		if player_hp <= 0 and relics.try_survive():
			player_hp = 1
			_float_at(_player_anchor(), I18N.t("relic.D07.trigger"), C_GOLD)
	return d


## 全牌堆里某张祟的数量（怨念缠身）
func _curse_count(key: String) -> int:
	var n := 0
	for arr in [draw_pile, hand, discard_pile]:
		for inst in arr:
			if str(inst["key"]) == key:
				n += 1
	return n


func _hit_enemy(e: Dictionary, dmg: int) -> void:
	if bool(e["dead"]):
		return
	var d := dmg
	if int(e["block"]) > 0:
		var absorbed: int = mini(int(e["block"]), d)
		e["block"] = int(e["block"]) - absorbed
		d -= absorbed
	if d > 0:
		e["hp"] = int(e["hp"]) - d


func _kill_enemy(e: Dictionary) -> void:
	Audio.play_sfx("enemy_die", 0.12)
	e["dead"] = true
	var v = e.get("view", null)
	if v != null and is_instance_valid(v):
		(v as EnemyView).set_dead(true)


func _all_dead() -> bool:
	for e in enemies:
		if not bool(e["dead"]):
			return false
	return true


func _alive_enemies() -> Array:
	var out: Array = []
	for e in enemies:
		if not bool(e["dead"]):
			out.append(e)
	return out


func _battle_victory() -> void:
	Audio.play_sfx("victory")
	if busy and not game_active:
		return
	busy = true
	game_active = false

	var kind := str(encounter.get("kind", "battle"))
	var base_gold := 0
	var insight := 0
	match kind:
		"elite":
			base_gold = Run.rng.randi_range(28, 40)
			insight = 12
			Run.elites += 1
		"boss":
			base_gold = Run.rng.randi_range(50, 70)
			insight = 25
			Run.bosses += 1
		_:
			base_gold = Run.rng.randi_range(10, 18)
			insight = 5
			Run.battles += 1

	var res := relics.on_battle_end(kind)
	var gold := base_gold + int(res["gold"])
	Run.gain_gold(gold)
	Run.insight += insight + int(res["insight"])
	Run.hp = max(1, player_hp)
	Run.heal(int(res["heal"]))
	player_hp = Run.hp

	if int(res["cards"]) > 0:
		for k in CardDB.roll_rewards(Run.rng, int(res["cards"])):
			Run.add_card(str(k), "xian")

	if str(node.get("id", "")) != "":
		Run.finish_node(str(node["id"]))

	if bool(encounter.get("no_reward", false)):
		_toast(I18N.t("ui.gain_gold", [gold]), C_GOLD)
		_after_node()
		return

	_show_victory(kind, gold, int(res["heal"]))


# ==================================================================
# 出牌
# ==================================================================
func _on_card_clicked(idx: int) -> void:
	if busy:
		_toast(I18N.t("ui.toast_busy"), Color(0.80, 0.76, 0.70, 0.92))
		return
	if not game_active:
		return
	if idx < 0 or idx >= hand.size():
		return
	var inst: Dictionary = hand[idx]
	var key := str(inst["key"])
	if not CardDB.CARDS.has(key):
		return
	var def: Dictionary = CardDB.CARDS[key]
	var cost := card_cost(key, str(inst["side"]))
	if str(def["type"]) == "curse":
		_toast(I18N.t("ui.toast_curse"), Color("#B69AC0"))
		return
	if _no_attack and str(def["type"]) == "attack":
		_toast(I18N.t("ui.toast_no_attack"), Color("#B69AC0"))
		return
	if cost > energy:
		_toast(I18N.t("ui.toast_no_energy", [cost]), Color("#E39A8E"))
		return

	if bool(def["target"]):
		var was_same := selected_index == idx
		selected_index = -1 if was_same else idx
		if was_same:
			_toast(I18N.t("ui.toast_deselect"), Color(0.80, 0.76, 0.70, 0.92))
		_refresh_hand()
		_refresh_highlight()
	else:
		play_card(idx, -1)


## 一张牌当前的实际费用（旧物折扣 / 首张本相免费 / 心魔加价 / 檐下听雨）
func card_cost(key: String, side: String) -> int:
	if not CardDB.CARDS.has(key):
		return 0
	var def: Dictionary = CardDB.CARDS[key]
	var tax := 0
	if _has_curse("xinmo") and not _curse_tax_paid:
		tax = 1
	var c := relics.cost_of(int(def["cost"]), side, tax)
	if _free_play:
		c = 0
	return c


func _on_enemy_clicked(idx: int) -> void:
	if busy:
		return
	if selected_index < 0:
		_toast(I18N.t("ui.toast_pick_first"), Color(0.80, 0.76, 0.70, 0.92))
		return
	if idx < 0 or idx >= enemies.size():
		return
	if bool(enemies[idx]["dead"]):
		return
	play_card(selected_index, idx)


func play_card(h_idx: int, t_idx: int) -> void:
	if busy or not game_active:
		return
	if h_idx < 0 or h_idx >= hand.size():
		return

	var inst: Dictionary = hand[h_idx]
	var key := str(inst["key"])
	if not CardDB.CARDS.has(key):
		return
	var def: Dictionary = CardDB.CARDS[key]
	if str(def["type"]) == "curse":
		return

	var cur_side := str(inst["side"])
	var cost := card_cost(key, cur_side)
	if cost > energy:
		return

	energy -= cost
	Audio.play_sfx("card_play", 0.06)
	if _has_curse("xinmo"):
		_curse_tax_paid = true
	if _free_play:
		_free_play = false

	var fx: Dictionary = def[cur_side]
	var first := not first_card_played

	# 能力牌
	if fx.has("power"):
		powers[str(fx["power"])] = true

	# 每回合首次出牌的被动
	if first:
		if bool(powers.get("block_first", false)):
			_add_block(2)
			_float_at(_player_anchor(), "+2", C_BLOCK)
		if bool(powers.get("dmg_first", false)):
			var alive := _alive_enemies()
			if alive.size() > 0:
				var t: Dictionary = alive[randi() % alive.size()]
				_deal(t, 4, def, cur_side)
		if bool(powers.get("poison_first", false)):
			var alive2 := _alive_enemies()
			if alive2.size() > 0:
				var t2: Dictionary = alive2[randi() % alive2.size()]
				t2["poison"] = int(t2["poison"]) + 1
				_float_at(_enemy_anchor(t2), "+1", C_MOSS)
		if bool(powers.get("aoe_first", false)):
			for e in _alive_enemies():
				_deal(e, 3, def, cur_side)
	first_card_played = true
	relics.on_card_played(key, def, cur_side, first)

	# 自损
	if fx.has("self_hp"):
		var sh := int(fx["self_hp"])
		player_hp -= sh
		Run.self_damage += sh
		_float_at(_player_anchor(), "-%d" % sh, C_ROUGE)
		if bool(powers.get("grudge_hurt", false)):
			_add_grudge(2)

	# 护盾
	if fx.has("block"):
		var bv := relics.mod_block(int(fx["block"]), cur_side)
		_add_block(bv)
		_float_at(_player_anchor(), "+%d" % bv, C_BLOCK)

	if fx.has("heal"):
		player_hp = mini(player_max_hp, player_hp + int(fx["heal"]))
		_float_at(_player_anchor(), "+%d" % int(fx["heal"]), C_MOSS)

	if fx.has("thorns"):
		thorns += int(fx["thorns"])

	if fx.has("energy"):
		energy += int(fx["energy"])

	if fx.has("energy_next"):
		_next_energy += int(fx["energy_next"])

	# 弃牌（先于抽牌）
	if fx.has("discard"):
		var need := int(fx["discard"])
		for i in need:
			if hand.size() <= 1:
				break
			var di := -1
			for j in hand.size():
				if j == h_idx:
					continue
				var tkey := str(hand[j]["key"])
				if str(CardDB.CARDS[tkey]["type"]) != "curse":
					di = j
					break
			if di < 0:
				break
			discard_pile.append(hand[di])
			hand.remove_at(di)
			Run.discards += 1
			Audio.play_sfx("discard", 0.08)
			if di < h_idx:
				h_idx -= 1

	if fx.has("draw"):
		_draw_cards(int(fx["draw"]))

	var tgt: Dictionary = {}
	if t_idx >= 0 and t_idx < enemies.size() and not bool(enemies[t_idx]["dead"]):
		tgt = enemies[t_idx]
	if tgt.is_empty():
		var alive := _alive_enemies()
		if alive.size() > 0:
			tgt = alive[0]

	var sp := str(fx.get("special", ""))

	# ---- 伤害 ----
	if sp == "poison_strike":
		_deal(tgt, int(tgt.get("poison", 0)) * 2, def, cur_side)
	elif sp == "poison_scale":
		var base := int(tgt.get("poison", 0)) * int(fx.get("mult", 3))
		_deal(tgt, base, def, cur_side)
		if fx.has("extra_poison"):
			tgt["poison"] = int(tgt["poison"]) + int(fx["extra_poison"])
	elif sp == "poison_consume":
		var stacks := int(tgt.get("poison", 0))
		tgt["poison"] = 0
		_deal(tgt, stacks * int(fx.get("mult", 5)), def, cur_side)
	elif sp == "grudge_bonus":
		var raw := int(fx.get("dmg", 0)) + int(floor(float(grudge) / 5.0)) * int(fx.get("mult", 2))
		_deal(tgt, raw, def, cur_side)
	elif sp == "grudge_burn":
		var raw2 := grudge * int(fx.get("mult", 2))
		grudge = 0
		_deal(tgt, raw2, def, cur_side)
	elif sp == "block_strike":
		_deal(tgt, player_block, def, cur_side)
	elif sp == "block_burn":
		var raw3 := int(floor(float(player_block) * 1.5))
		player_block = 0
		_deal(tgt, raw3, def, cur_side)
	elif sp == "random_dmg":
		var alive3 := _alive_enemies()
		if alive3.size() > 0:
			_deal(alive3[randi() % alive3.size()], int(fx.get("random_dmg", 0)), def, cur_side)
	elif fx.has("dmg_if_bound"):
		if not tgt.is_empty() and int(tgt.get("bind", 0)) > 0:
			_deal(tgt, int(fx["dmg_if_bound"]), def, cur_side)
	elif fx.has("dmg"):
		var raw4 := int(fx["dmg"])
		if fx.has("dmg_if_poison") and not tgt.is_empty() and int(tgt.get("poison", 0)) > 0:
			raw4 += int(fx["dmg_if_poison"])
		for h in int(fx.get("hits", 1)):
			_deal(tgt, raw4, def, cur_side)

	if fx.has("aoe_dmg"):
		for e in _alive_enemies():
			_deal(e, int(fx["aoe_dmg"]), def, cur_side)

	# ---- 状态 ----
	if fx.has("poison") and not tgt.is_empty():
		Audio.play_sfx("poison", 0.08)
		tgt["poison"] = int(tgt["poison"]) + int(fx["poison"])
		_float_at(_enemy_anchor(tgt), "%s +%d" % [I18N.t("w.poison"), int(fx["poison"])], C_MOSS)
	if fx.has("aoe_poison"):
		for e in _alive_enemies():
			e["poison"] = int(e["poison"]) + int(fx["aoe_poison"])
	if sp == "double_poison" and not tgt.is_empty():
		tgt["poison"] = int(tgt["poison"]) * 2
	if fx.has("aoe_weak"):
		for e in _alive_enemies():
			e["weak"] = int(e["weak"]) + int(fx["aoe_weak"])
	if fx.has("bind") and not tgt.is_empty():
		Audio.play_sfx("bind", 0.10)
		tgt["bind"] = int(tgt["bind"]) + int(fx["bind"]) + relics.bind_bonus()
	if fx.has("aoe_bind"):
		for e in _alive_enemies():
			e["bind"] = int(e["bind"]) + int(fx["aoe_bind"]) + relics.bind_bonus()
	if sp == "random_bind":
		var alive4 := _alive_enemies()
		if alive4.size() > 0:
			var t4: Dictionary = alive4[randi() % alive4.size()]
			t4["bind"] = int(t4["bind"]) + int(fx.get("random_bind", 1)) + relics.bind_bonus()
			_float_at(_enemy_anchor(t4), I18N.t("ui.bound"), C_DAI)
	if fx.has("weaken_enemy") and not tgt.is_empty():
		tgt["weaken"] = int(tgt["weaken"]) + int(fx["weaken_enemy"])
	if sp == "poison_splash":
		for e in _alive_enemies():
			if int(e["poison"]) > 0:
				_deal(e, int(fx.get("poison_splash", 0)), def, cur_side)

	# ---- 牌与资源 ----
	if sp == "draw_per_poison" and not tgt.is_empty():
		_draw_cards(mini(int(tgt.get("poison", 0)), int(fx.get("max", 3))))
	if sp == "draw_if_bound":
		for e in _alive_enemies():
			if int(e["bind"]) > 0:
				_draw_cards(int(fx.get("extra", 1)))
				break
	if fx.has("return_discard"):
		for i in int(fx["return_discard"]):
			if discard_pile.is_empty():
				break
			var pick: int = randi() % discard_pile.size()
			hand.append(discard_pile[pick])
			discard_pile.remove_at(pick)
	if fx.has("add_curse"):
		discard_pile.append({"key": str(fx["add_curse"]), "side": "xian"})
	if fx.has("cleanse"):
		player_poison = 0
		player_weak = 0
		grievance = 0
	if fx.has("no_attack"):
		_no_attack = true

	# 清理死亡
	for e in enemies:
		if not bool(e["dead"]) and int(e["hp"]) <= 0:
			_kill_enemy(e)

	# 翻面 + 入弃牌堆（消耗牌 / 能力牌 / 临时副本 直接移出本场）
	Audio.play_sfx("card_flip", 0.05)
	inst["side"] = "ben" if cur_side == "xian" else "xian"
	var temp := bool(inst.get("temp", false))
	hand.remove_at(h_idx)
	if temp or bool(fx.get("exhaust", false)) or str(def["type"]) == "power":
		exhaust_pile.append(inst)
	else:
		discard_pile.append(inst)
	Run.played += 1

	selected_index = -1
	_refresh_all()

	if player_hp <= 0:
		await get_tree().create_timer(0.35).timeout
		_game_over(false)
		return
	if _all_dead():
		await get_tree().create_timer(0.45).timeout
		_battle_victory()


## 对单个敌人结算一次伤害（含旧物加成、玩家祟弱、飘字、受击动效）
func _deal(e: Dictionary, raw: int, def: Dictionary, side: String) -> int:
	if e.is_empty() or bool(e.get("dead", false)):
		return 0
	var amount := raw
	if player_weak > 0:
		amount = int(floor(float(amount) * 0.75))
	amount = relics.mod_damage(amount, def, side, e)
	_hit_enemy(e, amount)
	Audio.play_sfx("hit_heavy" if amount >= 15 else "hit")
	_float_at(_enemy_anchor(e), "-%d" % amount, C_ROUGE)
	var v = e.get("view", null)
	if v != null and is_instance_valid(v):
		(v as EnemyView).play_hit_fx()
	return amount


# ==================================================================
# 刷新
# ==================================================================
func _refresh_all() -> void:
	if hp_fill == null:
		return
	_refresh_hp()
	_refresh_energy()
	_refresh_piles()
	_refresh_enemies()
	_refresh_hand()
	_refresh_highlight()
	end_turn_btn.disabled = busy


func _refresh_hp() -> void:
	var ratio := clampf(float(player_hp) / float(player_max_hp), 0.0, 1.0)
	hp_fill.size = Vector2(160.0 * ratio, 8.0)
	hp_label.text = "%d / %d" % [max(0, player_hp), player_max_hp]
	grudge_label.text = str(grudge)
	block_label.text = ("%s %d" % [I18N.t("w.block"), player_block]) if player_block > 0 else ""
	block_label.add_theme_color_override("font_color", C_BLOCK)
	if grievance_label != null:
		grievance_label.text = ("%s %d" % [I18N.t("w.grievance"), grievance]) if grievance > 0 else ""
	if relic_btn != null:
		relic_btn.text = "%s %d" % [I18N.t("ui.relics"), Run.relic_count()]


func _refresh_energy() -> void:
	for c in energy_box.get_children():
		energy_box.remove_child(c)
		c.queue_free()

	for i in max_energy:
		var o := PanelContainer.new()
		o.custom_minimum_size = Vector2(17, 17)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(9)
		sb.set_border_width_all(1)
		if i < energy:
			sb.bg_color = Color(0.69, 0.55, 0.25, 0.5)
			sb.border_color = Color(0.69, 0.55, 0.25, 0.9)
		else:
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = Color(1, 1, 1, 0.14)
		o.add_theme_stylebox_override("panel", sb)
		energy_box.add_child(o)

	energy_label.text = "%d / %d" % [energy, max_energy]


func _refresh_piles() -> void:
	draw_label.text = str(draw_pile.size())
	discard_label.text = str(discard_pile.size())


func _refresh_enemies() -> void:
	for e in enemies:
		var v = e.get("view", null)
		if v != null and is_instance_valid(v):
			(v as EnemyView).refresh_from(e)


func _refresh_hand() -> void:
	for c in hand_box.get_children():
		hand_box.remove_child(c)
		c.queue_free()

	var n := hand.size()
	# 手牌多时重叠，避免溢出
	var sep := 9
	if n > 6:
		sep = max(-26, 9 - (n - 6) * 8)
	hand_box.add_theme_constant_override("separation", sep)

	for i in n:
		var inst: Dictionary = hand[i]
		var key := str(inst["key"])
		var cv := CardView.new()
		hand_box.add_child(cv)
		var def: Dictionary = CardDB.CARDS[key]
		var cost := card_cost(key, str(inst["side"]))
		cv.setup(key, str(inst["side"]), i, cost)
		var dis := cost > energy or str(def["type"]) == "curse"
		cv.set_disabled(dis)
		if i == selected_index:
			cv.set_selected(true)
		cv.clicked.connect(_on_card_clicked)


func _refresh_highlight() -> void:
	var on := selected_index >= 0
	if target_hint != null and is_instance_valid(target_hint):
		target_hint.visible = on
	for e in enemies:
		var v = e.get("view", null)
		if v != null and is_instance_valid(v):
			(v as EnemyView).set_targetable(on and not bool(e["dead"]))


# ==================================================================
# 弹窗
# ==================================================================
func _clear_panel() -> void:
	_pause_open = false
	_clear_map()
	if _oc != null:
		_oc.visible = true
	if _panel != null:
		_panel.visible = true
	for c in panel_vb.get_children():
		panel_vb.remove_child(c)
		c.queue_free()


func _show_overlay() -> void:
	overlay.visible = true


func _hide_overlay() -> void:
	overlay.visible = false
	_pause_open = false
	_panel_mode = ""
	_clear_map()
	if _oc != null:
		_oc.visible = true
	if _panel != null:
		_panel.visible = true


func _clear_map() -> void:
	if _map_view != null and is_instance_valid(_map_view):
		_map_view.queue_free()
		_map_view = null


func _panel_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(26 * UI_S))
	l.add_theme_color_override("font_color", C_MOON)
	return l


func _panel_sub(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(13 * UI_S))
	l.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.48))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _mk_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(196, 46)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(15 * UI_S))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.70, 0.23, 0.19, 0.20)
	n.border_color = C_CINNABAR
	n.set_border_width_all(1)
	n.set_corner_radius_all(2)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.70, 0.23, 0.19, 0.36)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", C_MOON)
	b.pressed.connect(func(): Audio.play_sfx("click", 0.02))
	return b


func _show_intro() -> void:
	Audio.play_bgm("layer1")
	_clear_panel()
	_show_overlay()
	_panel_mode = "intro"

	# 左立绘 + 右文案。缺图时整栏自动省略，退回原来的纯文字版式。
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	panel_vb.add_child(row)

	var art := AssetLoader.character_art("nvzhu")
	if art != null:
		var frame := PanelContainer.new()
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Color(0.06, 0.08, 0.10, 1.0)
		fsb.border_color = Color(0.92, 0.90, 0.86, 0.14)
		fsb.set_border_width_all(1)
		frame.add_theme_stylebox_override("panel", fsb)
		frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(frame)

		var tr := TextureRect.new()
		tr.texture = art
		tr.custom_minimum_size = Vector2(252, 378)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tr)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)

	col.add_child(_panel_title(I18N.t("ui.title")))
	col.add_child(_panel_sub(I18N.t("ui.subtitle")))

	var tip := Label.new()
	tip.text = I18N.t("ui.intro")
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", int(13 * UI_S))
	tip.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.62))
	tip.add_theme_constant_override("line_spacing", 8)
	col.add_child(tip)

	var brow := CenterContainer.new()
	col.add_child(brow)
	var b := _mk_button(I18N.t("ui.enter"))
	b.pressed.connect(_enter_run)
	brow.add_child(b)


func _show_victory(kind: String, gold: int, heal: int) -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "victory"
	_victory_kind = kind
	_victory_gold = gold
	_victory_heal = heal
	_relic_pending = kind if (kind == "elite" or kind == "boss") else ""

	panel_vb.add_child(_panel_title(I18N.t("ui.victory_title")))
	var bits: Array = [I18N.t("ui.gain_gold", [gold])]
	if heal > 0:
		bits.append(I18N.t("ui.gain_hp", [heal]))
	panel_vb.add_child(_panel_sub("  ·  ".join(bits)))
	panel_vb.add_child(_panel_sub(I18N.t("ui.reward_sub")))

	if _reward_picks.is_empty():
		_reward_picks = CardDB.roll_rewards(Run.rng, relics.reward_choices())
		_reward_sides.clear()
		for i in _reward_picks.size():
			_reward_sides.append("xian" if Run.rng.randf() < 0.5 else "ben")

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	panel_vb.add_child(row)

	for i in _reward_picks.size():
		var kk := str(_reward_picks[i])
		var side := str(_reward_sides[i])
		var cv := CardView.new()
		row.add_child(cv)
		cv.setup(kk, side, -1)
		cv.clicked.connect(func(_i: int):
			Run.add_card(kk, side)
			_reward_picks.clear()
			_reward_sides.clear()
			_post_reward()
		)

	var brow := CenterContainer.new()
	panel_vb.add_child(brow)
	var skip := _mk_button(I18N.t("ui.reward_skip"))
	skip.pressed.connect(func():
		_reward_picks.clear()
		_reward_sides.clear()
		_post_reward()
	)
	brow.add_child(skip)


func _post_reward() -> void:
	if _relic_pending != "":
		var src := _relic_pending
		_relic_pending = ""
		_show_relic_choice(src)
		return
	_hide_overlay()
	_after_node()


func _show_relic_choice(source: String) -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "relic_choice"

	panel_vb.add_child(_panel_title(I18N.t("ui.relic_title")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.relic_sub")))

	var picks := RelicDB.roll(Run.rng, source, 3, Run.relics)
	if picks.is_empty():
		_after_node()
		return

	for id in picks:
		var b := _wide_button("%s  ·  %s\n%s" % [
			RelicDB.name(str(id)), _rarity_name(RelicDB.rarity_of(str(id))), RelicDB.desc(str(id))
		], RelicDB.rarity_of(str(id)))
		b.pressed.connect(func(): _relic_take(str(id)))
		panel_vb.add_child(b)

	var brow := CenterContainer.new()
	panel_vb.add_child(brow)
	var skip := _mk_button(I18N.t("ui.relic_skip"))
	skip.pressed.connect(func(): _after_node())
	brow.add_child(skip)


func _relic_take(id: String) -> void:
	if Run.relic_count() >= 8:
		_show_relic_replace(id)
		return
	Audio.play_sfx("relic")
	Run.add_relic(id)
	relics.setup(Run.relics, self)
	_refresh_all()
	_after_node()


func _show_relic_replace(new_id: String) -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "relic_replace"

	panel_vb.add_child(_panel_title(I18N.t("ui.relic_full")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.relic_full_sub", [RelicDB.name(new_id)])))

	for old in Run.relics.duplicate():
		var b := _wide_button("%s  ·  %s" % [RelicDB.name(str(old)), RelicDB.desc(str(old))], "common")
		b.pressed.connect(func():
			Run.relics.erase(old)
			Run.add_relic(new_id)
			relics.setup(Run.relics, self)
			_refresh_all()
			_after_node()
		)
		panel_vb.add_child(b)

	var brow := CenterContainer.new()
	panel_vb.add_child(brow)
	var skip := _mk_button(I18N.t("ui.relic_skip"))
	skip.pressed.connect(func(): _after_node())
	brow.add_child(skip)


func _game_over(win: bool) -> void:
	if not win:
		Audio.play_sfx("defeat")
	game_active = false
	busy = false
	Run.outcome = "win" if win else "lose"
	Run.hp = max(0, player_hp)
	Run.diagnosis = Run.evaluate_diagnosis()

	_clear_panel()
	_show_overlay()
	_panel_mode = "win" if win else "lose"
	_pause_open = false

	if win:
		panel_vb.add_child(_panel_title(I18N.t("ui.win_title")))
		panel_vb.add_child(_panel_sub(I18N.t("ui.win_sub")))
	else:
		panel_vb.add_child(_panel_title(I18N.t("ui.lose_title")))
		panel_vb.add_child(_panel_sub(I18N.t("ui.lose_sub")))

	# 确诊标签：只展示，不加任何属性
	var tag := I18N.t("diag." + Run.diagnosis)
	var note := I18N.t("diag.%s.c" % Run.diagnosis)
	var dline := Label.new()
	dline.text = I18N.t("ui.diagnosis_line", [tag])
	dline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dline.add_theme_font_size_override("font_size", int(20 * UI_S))
	dline.add_theme_color_override("font_color", C_LOTUS)
	panel_vb.add_child(dline)

	var dnote := Label.new()
	dnote.text = note
	dnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dnote.add_theme_font_size_override("font_size", int(13 * UI_S))
	dnote.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.55))
	dnote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vb.add_child(dnote)

	var stat := Label.new()
	stat.text = I18N.t("share.stats", [Run.rounds, Run.played, Run.self_damage, Run.grudge_peak])
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", int(11 * UI_S))
	stat.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.34))
	panel_vb.add_child(stat)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	panel_vb.add_child(row)

	var bs := _mk_button(I18N.t("ui.share"))
	bs.pressed.connect(_show_share)
	row.add_child(bs)

	var b := _mk_button(I18N.t("ui.again"))
	b.pressed.connect(func():
		_hide_overlay()
		start_game()
	)
	row.add_child(b)

	var bq := _mk_button(I18N.t("ui.exit"))
	bq.pressed.connect(_quit_to_desktop)
	row.add_child(bq)


# ==================================================================
# 暂停菜单 / 退出
# ==================================================================
func _show_pause() -> void:
	if _panel_mode != "pause" and _panel_mode != "lang":
		_prev_mode = _panel_mode
	_clear_panel()
	_show_overlay()
	_panel_mode = "pause"
	_pause_open = true

	panel_vb.add_child(_panel_title(I18N.t("ui.pause_title")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.pause_sub")))

	# 结算之后没有"继续"可言，只留重开与退出
	if game_active:
		var r1 := CenterContainer.new()
		panel_vb.add_child(r1)
		var b1 := _mk_button(I18N.t("ui.resume"))
		b1.pressed.connect(func(): _hide_overlay())
		r1.add_child(b1)

	var rd := HBoxContainer.new()
	rd.alignment = BoxContainer.ALIGNMENT_CENTER
	rd.add_theme_constant_override("separation", 12)
	panel_vb.add_child(rd)
	var bd := _mk_button(I18N.t("ui.deck"))
	bd.add_theme_font_size_override("font_size", int(13 * UI_S))
	bd.custom_minimum_size = Vector2(150, 42)
	bd.pressed.connect(func(): _show_deck(false))
	rd.add_child(bd)
	var bc := _mk_button(I18N.t("ui.codex"))
	bc.add_theme_font_size_override("font_size", int(13 * UI_S))
	bc.custom_minimum_size = Vector2(150, 42)
	bc.pressed.connect(_show_codex)
	rd.add_child(bc)

	var r2 := CenterContainer.new()
	panel_vb.add_child(r2)
	var b2 := _mk_button(I18N.t("ui.restart"))
	b2.pressed.connect(func():
		_hide_overlay()
		start_game()
	)
	r2.add_child(b2)

	# ---- 声音：三格一组，点一下循环一档 ----
	var ra := HBoxContainer.new()
	ra.alignment = BoxContainer.ALIGNMENT_CENTER
	ra.add_theme_constant_override("separation", 10)
	panel_vb.add_child(ra)
	for kind in ["music", "sfx", "mute"]:
		var ba := _mk_button(_audio_label(str(kind)))
		ba.add_theme_font_size_override("font_size", int(13 * UI_S))
		ba.custom_minimum_size = Vector2(190, 42)
		ba.pressed.connect(func():
			match str(kind):
				"music": Audio.cycle_music()
				"sfx": Audio.cycle_sfx()
				"mute": Audio.toggle_mute()
			_show_pause()
		)
		ra.add_child(ba)

	var rl := CenterContainer.new()
	panel_vb.add_child(rl)
	var bl := _mk_button(I18N.t("ui.language") + " · " + I18N.lang_name(I18N.code))
	bl.add_theme_font_size_override("font_size", int(13 * UI_S))
	bl.pressed.connect(_show_language)
	rl.add_child(bl)

	var r3 := CenterContainer.new()
	panel_vb.add_child(r3)
	var b3 := _mk_button(I18N.t("ui.quit_desktop"))
	b3.pressed.connect(_quit_to_desktop)
	r3.add_child(b3)

	var hint := Label.new()
	hint.text = I18N.t("ui.pause_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", int(11 * UI_S))
	hint.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.30))
	panel_vb.add_child(hint)


## 声音按钮上的文字：音乐 60% / 音效 80% / 静音
func _audio_label(kind: String) -> String:
	match kind:
		"music":
			return "%s %s" % [I18N.t("ui.music"), Audio.music_text()]
		"sfx":
			return "%s %s" % [I18N.t("ui.sfx"), Audio.sfx_text()]
		_:
			return I18N.t("ui.unmute") if Audio.muted else I18N.t("ui.mute")


func _quit_to_desktop() -> void:
	_hide_overlay()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()


# ==================================================================
# 飘字与位置
# ==================================================================
func _player_anchor() -> Vector2:
	if hp_fill != null and is_instance_valid(hp_fill):
		return hp_fill.global_position + Vector2(64, 18)
	return Vector2(1000, 40)


func _enemy_anchor(e: Dictionary) -> Vector2:
	var v = e.get("view", null)
	if v != null and is_instance_valid(v):
		return (v as EnemyView).global_position + Vector2(76, 124)
	return Vector2(640, 320)


## [FX] 伤害飘字：后期可替换为美术设计的数字特效
func _float_at(pos: Vector2, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.theme = ui_theme
	l.add_theme_font_size_override("font_size", int(24 * UI_S))
	l.add_theme_color_override("font_color", color)
	l.position = pos - Vector2(28, 14)
	l.z_index = 100
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 62.0, 0.85)
	tw.tween_property(l, "modulate:a", 0.0, 0.85)
	tw.set_parallel(false)
	tw.tween_callback(l.queue_free)


## 屏幕上方居中的短暂提示 —— 专门用来解释「这一下为什么没反应」
## 位置落在顶栏中段（层名与魂火之间的空白处），不遮挡敌人和手牌
func _toast(text: String, color: Color = C_MOON) -> void:
	var vw := get_viewport_rect().size.x
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.09, 0.92)
	sb.border_color = Color(color.r, color.g, color.b, 0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", sb)
	box.size = Vector2(460, 40)
	box.position = Vector2(vw * 0.5 - 230, 378)
	box.z_index = 150
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.0

	var l := Label.new()
	l.theme = ui_theme
	l.text = text
	l.add_theme_font_size_override("font_size", int(15 * UI_S))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	add_child(box)

	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.10)
	tw.tween_interval(0.95)
	tw.tween_property(box, "modulate:a", 0.0, 0.22)
	tw.tween_callback(box.queue_free)


# ==================================================================
# 语言切换
# ==================================================================
func _show_language() -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "lang"

	panel_vb.add_child(_panel_title(I18N.t("ui.lang_title")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.lang_sub")))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_vb.add_child(grid)

	for l in I18N.LANGS:
		var c := str(l["code"])
		var b := _mk_button(str(l["name"]))
		b.custom_minimum_size = Vector2(190, 42)
		b.add_theme_font_size_override("font_size", int(13 * UI_S))
		if c == I18N.code:
			# 当前语言：朱砂底 + 亮字，一眼能看出选的是哪个
			b.add_theme_color_override("font_color", Color("#F2BDB2"))
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.70, 0.23, 0.19, 0.46)
			sb.border_color = C_CINNABAR
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(2)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", sb)
		b.pressed.connect(func(): _apply_language(c))
		grid.add_child(b)

	var row := CenterContainer.new()
	panel_vb.add_child(row)
	var back := _mk_button(I18N.t("ui.lang_back"))
	back.pressed.connect(_show_pause)
	row.add_child(back)


## 切换语言：存盘 → 重建 UI → 回到原来那一屏
## 用 call_deferred 是因为调用方正是即将被销毁的按钮
func _apply_language(c: String) -> void:
	if c == I18N.code:
		_show_language()
		return
	I18N.set_lang(c)
	call_deferred("_rebuild_ui")


## 整棵 UI 重来一遍，但局面数据（手牌 / 敌人 / 血量 / 波次）一律不动
func _rebuild_ui() -> void:
	var mode := _panel_mode
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()

	_build_theme()
	_build_ui()
	_map_view = null

	if not enemies.is_empty():
		_restore_field()
		_refresh_all()

	overlay.visible = false
	_panel_mode = ""
	match mode:
		"intro": _show_intro()
		"map": _show_map()
		"victory": _show_victory(_victory_kind, _victory_gold, _victory_heal)
		"relic_choice": _show_relic_choice("elite")
		"pause": _show_pause()
		"lang": _show_language()
		"shop": _show_shop(node)
		"rest": _show_rest(node)
		"treasure": _show_treasure(node)
		"event": _show_event(node)
		"codex": _show_codex()
		"relics": _show_relics()
		"deck": _show_deck(false)
		"share": _show_share()
		"win": _game_over(true)
		"lose": _game_over(false)


## 按现有 enemies 数据重建敌人视图（不重置血量与行动序列）
func _restore_field() -> void:
	Audio.play_bgm("layer%d" % (Run.layer + 1))
	var cfg: Dictionary = EnemyDB.LAYERS[Run.layer]
	layer_label.text = I18N.t(str(cfg["name"]))
	chapter_label.text = I18N.t(str(cfg["chapter"]))

	if bg_tex != null:
		var bgimg := AssetLoader.battle_bg(Run.layer)
		if bgimg != null:
			bg_tex.texture = bgimg
			bg_tex.visible = true

	for i in enemies.size():
		var e: Dictionary = enemies[i]
		var ev := EnemyView.new()
		field_box.add_child(ev)
		ev.setup(e["seed"], i)
		ev.clicked.connect(_on_enemy_clicked)
		e["view"] = ev

# ==================================================================
# 地图
# ==================================================================
func _show_map() -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "map"
	if _oc != null:
		_oc.visible = false
	if _panel != null:
		_panel.visible = false

	var ids: Array = []
	for n in Run.available():
		ids.append(str(n["id"]))

	var cfg: Dictionary = EnemyDB.LAYERS[Run.layer]
	var mv := MapView.new()
	mv.setup(Run.map, Run.node_id, ids, ui_theme,
		I18N.t(str(cfg["name"])), I18N.t(str(cfg["chapter"])))
	mv.node_chosen.connect(_on_node_chosen)
	mv.open_deck.connect(func(): _show_deck(false))
	mv.open_relics.connect(_show_relics)
	mv.open_codex.connect(_show_codex)
	overlay.add_child(mv)
	_map_view = mv


func _on_node_chosen(id: String) -> void:
	var n := Run.enter(id)
	if n.is_empty():
		return
	match str(n["type"]):
		"battle", "elite", "boss":
			_hide_overlay()
			var enc: Dictionary = {
				"kind": str(n["type"]),
				"enemies": (n["payload"] as Dictionary).get("enemies", []),
			}
			start_encounter(enc, n)
		"event":
			_show_event(n)
		"shop":
			_show_shop(n)
		"rest":
			_show_rest(n)
		_:
			_show_treasure(n)


## 一个节点结算完，回到地图；Boss 则进入下一层或通关
func _after_node() -> void:
	_hide_overlay()
	var t := str(node.get("type", ""))
	if t == "boss":
		if Run.layer >= EnemyDB.LAYERS.size() - 1:
			_game_over(true)
			return
		Run.layer += 1
		Run.start_layer(Run.layer)
		grudge = 0
		if Run.has_relic("C06"):
			for k in CardDB.roll_rewards(Run.rng, 1):
				Run.add_card(str(k), "ben")
	_refresh_all()
	_show_map()


# ==================================================================
# 商店
# ==================================================================
func _shop_stock(n: Dictionary) -> Dictionary:
	var p: Dictionary = n.get("payload", {})
	if not p.has("stock"):
		p["stock"] = {
			"cards": CardDB.roll_rewards(Run.rng, 5),
			"relics": RelicDB.roll(Run.rng, "shop", 2, Run.relics),
			"bought_cards": [],
			"bought_relics": [],
			"removed": 0,
		}
		n["payload"] = p
	return p["stock"]


func _shop_price(base: int) -> int:
	return int(round(float(base) * (1.0 - relics.shop_discount())))


func _show_shop(n: Dictionary) -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "shop"
	node = n
	var st := _shop_stock(n)

	panel_vb.add_child(_panel_title(I18N.t("ui.shop_title")))
	panel_vb.add_child(_panel_sub("%s %d" % [I18N.t("w.gold"), Run.gold]))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 360)
	panel_vb.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)

	for k in st["cards"]:
		var key := str(k)
		var sold: bool = st["bought_cards"].has(key)
		var price := _shop_price(int(CardDB.PRICE[CardDB.rarity_of(key)]))
		var label := "%s  ·  %s  ·  %s %d" % [
			I18N.card_name(key), _rarity_name(CardDB.rarity_of(key)), I18N.t("w.gold"), price]
		if sold:
			label = I18N.t("ui.sold") + "  ·  " + I18N.card_name(key)
		var b := _wide_button(label, CardDB.rarity_of(key))
		b.disabled = sold or Run.gold < price
		b.pressed.connect(func():
			if Run.spend(price):
				Audio.play_sfx("coin")
				Run.add_card(key, "xian")
				st["bought_cards"].append(key)
				_show_shop(n)
		)
		vb.add_child(b)

	for r in st["relics"]:
		var rid := str(r)
		var sold2: bool = st["bought_relics"].has(rid)
		var price2 := _shop_price(int(RelicDB.PRICE[RelicDB.rarity_of(rid)]))
		var label2 := "%s  ·  %s  ·  %s %d\n%s" % [
			RelicDB.name(rid), _rarity_name(RelicDB.rarity_of(rid)),
			I18N.t("w.gold"), price2, RelicDB.desc(rid)]
		if sold2:
			label2 = I18N.t("ui.sold") + "  ·  " + RelicDB.name(rid)
		var b2 := _wide_button(label2, RelicDB.rarity_of(rid))
		b2.disabled = sold2 or Run.gold < price2
		b2.pressed.connect(func():
			if Run.spend(price2):
				Audio.play_sfx("coin")
				Run.add_relic(rid)
				relics.setup(Run.relics, self)
				st["bought_relics"].append(rid)
				_show_shop(n)
		)
		vb.add_child(b2)

	# 删牌服务（每次 +25，上限 150）
	var rm_price := _shop_price(mini(150, 75 + int(st["removed"]) * 25))
	var rb := _wide_button("%s  ·  %s %d" % [
		I18N.t("ui.shop_remove"), I18N.t("w.gold"), rm_price], "rare")
	rb.disabled = Run.gold < rm_price
	rb.pressed.connect(func():
		if Run.spend(rm_price):
			_show_deck(true, func():
				st["removed"] = int(st["removed"]) + 1
				_show_shop(n)
			)
	)
	vb.add_child(rb)

	var row := CenterContainer.new()
	panel_vb.add_child(row)
	var back := _mk_button(I18N.t("ui.leave"))
	back.pressed.connect(func(): _after_node())
	row.add_child(back)


# ==================================================================
# 休息
# ==================================================================
func _show_rest(n: Dictionary) -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "rest"
	node = n

	panel_vb.add_child(_panel_title(I18N.t("ui.rest_title")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.rest_sub")))
	panel_vb.add_child(_panel_sub("%s %d / %d" % [I18N.t("w.hp"), Run.hp, Run.max_hp]))

	var b1 := _mk_button(I18N.t("ui.rest_heal"))
	b1.disabled = not relics.can_rest_heal()
	b1.pressed.connect(func():
		Run.heal(15)
		_after_node()
	)
	panel_vb.add_child(b1)

	var b2 := _mk_button(I18N.t("ui.rest_remove"))
	b2.pressed.connect(func():
		_show_deck(true, _after_node)
	)
	panel_vb.add_child(b2)

	var b3 := _mk_button(I18N.t("ui.rest_rain"))
	b3.pressed.connect(func():
		Run.heal(8)
		Run.free_play_next = true
		_after_node()
	)
	panel_vb.add_child(b3)


# ==================================================================
# 宝箱
# ==================================================================
func _show_treasure(n: Dictionary) -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "treasure"
	node = n

	panel_vb.add_child(_panel_title(I18N.t("ui.treasure_title")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.treasure_sub")))

	var p: Dictionary = n.get("payload", {})
	if p.has("opened"):
		panel_vb.add_child(_panel_sub(str(p["opened"])))
		var bw := _mk_button(I18N.t("ui.back"))
		bw.pressed.connect(func(): _after_node())
		panel_vb.add_child(bw)
		return

	var b := _mk_button(I18N.t("ui.treasure_open"))
	b.pressed.connect(func():
		var text := ""
		var roll := Run.rng.randf()
		if roll < 0.15:
			var picks := RelicDB.roll(Run.rng, "treasure", 1, Run.relics, true)
			if picks.is_empty():
				picks = RelicDB.roll(Run.rng, "treasure", 1, Run.relics)
			if not picks.is_empty():
				var rid := str(picks[0])
				Run.add_relic(rid)
				text = I18N.t("ui.got_relic", [RelicDB.name(rid)])
		elif roll < 0.85:
			var gold := Run.rng.randi_range(40, 60)
			Run.gain_gold(gold)
			text = I18N.t("ui.gain_gold", [gold])
		else:
			var gold2 := Run.rng.randi_range(40, 60)
			Run.gain_gold(gold2)
			text = I18N.t("ui.gain_gold", [gold2])
		p["opened"] = text
		n["payload"] = p
		_show_treasure(n)
	)
	panel_vb.add_child(b)


# ==================================================================
# 事件
# ==================================================================
func _show_event(n: Dictionary) -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "event"
	node = n

	var id := str(n.get("payload", {}).get("event", ""))
	if id == "" or EventDB.get_event(id).is_empty():
		_after_node()
		return

	panel_vb.add_child(_panel_title(EventDB.title(id)))

	var body := Label.new()
	body.text = EventDB.body(id)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size = Vector2(620, 0)
	body.add_theme_font_size_override("font_size", int(13 * UI_S))
	body.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.72))
	panel_vb.add_child(body)

	var opts: Array = EventDB.get_event(id).get("options", [])
	for i in opts.size():
		var text := EventDB.option_text(id, i)
		var hint := EventDB.option_hint(id, i)
		if hint != "":
			text += "\n" + hint
		var b := _wide_button(text, "rare")
		var fx: Dictionary = opts[i].get("fx", {})
		b.pressed.connect(func(): _choose_option(id, fx))
		panel_vb.add_child(b)


func _choose_option(id: String, fx: Dictionary) -> void:
	if fx.has("battle"):
		_hide_overlay()
		var key := str(fx["battle"])
		var scale := float(fx.get("scale", 1.0))
		start_encounter({"kind": "battle", "enemies": [key], "scale": scale, "no_reward": true}, node)
		return

	var lines := _apply_effect(fx)
	_clear_panel()
	_show_overlay()
	_panel_mode = "event_result"
	panel_vb.add_child(_panel_title(EventDB.title(id)))
	for l in lines:
		panel_vb.add_child(_panel_sub(str(l)))
	var b := _mk_button(I18N.t("ui.back"))
	b.pressed.connect(func(): _after_node())
	panel_vb.add_child(b)


func _apply_effect(fx: Dictionary) -> Array:
	var out: Array = []
	if fx.has("heal"):
		Run.heal(int(fx["heal"]))
		out.append(I18N.t("ui.gain_hp", [int(fx["heal"])]))
	if fx.has("max_hp"):
		var v := int(fx["max_hp"])
		Run.max_hp += v
		if v > 0:
			Run.hp += v
		out.append(I18N.t("ui.gain_max_hp", [v]))
	if fx.has("gold"):
		var g := int(fx["gold"])
		Run.gain_gold(g)
		out.append(I18N.t("ui.gain_gold", [g]) if g >= 0 else I18N.t("ui.lose_gold", [-g]))
	if fx.has("damage"):
		var d := int(fx["damage"])
		Run.hp = max(1, Run.hp - d)
		out.append(I18N.t("ui.lose_hp", [d]))
	if fx.has("relic"):
		var picks := RelicDB.roll(Run.rng, str(fx["relic"]), 1, Run.relics)
		if not picks.is_empty():
			var rid := str(picks[0])
			Run.add_relic(rid)
			out.append(I18N.t("ui.got_relic", [RelicDB.name(rid)]))
	if fx.has("card"):
		var picksc := CardDB.roll_rewards(Run.rng, int(fx["card"]))
		for k in picksc:
			Run.add_card(str(k), "xian")
			out.append(I18N.t("ui.got_card", [I18N.card_name(str(k))]))
	if fx.has("curse"):
		var ck := str(fx["curse"])
		Run.add_card(ck, "xian")
		out.append(I18N.t("ui.got_curse", [I18N.card_name(ck)]))
	if fx.has("insight"):
		Run.insight += int(fx["insight"])
		out.append(I18N.t("ui.gain_insight", [int(fx["insight"])]))
	if fx.has("gamble"):
		var gd: Dictionary = fx["gamble"]
		var cost := int(gd.get("cost", 0))
		var win := int(gd.get("win", 0))
		if Run.gold >= cost and Run.rng.randf() < 0.5:
			Run.gain_gold(win)
			out.append(I18N.t("ui.gamble_win", [win]))
		else:
			Run.gain_gold(-cost)
			out.append(I18N.t("ui.gamble_lose", [cost]))
	if out.is_empty():
		out.append(I18N.t("ui.nothing_happened"))
	return out


# ==================================================================
# 牌组 / 图鉴 / 旧物
# ==================================================================
func _show_deck(remove_mode: bool = false, cb: Callable = Callable()) -> void:
	_view_origin = _panel_mode
	_clear_panel()
	_show_overlay()
	_panel_mode = "deck"
	_remove_cb = cb
	if remove_mode:
		_panel_mode = "deck_remove"

	panel_vb.add_child(_panel_title(I18N.t("ui.deck")))
	panel_vb.add_child(_panel_sub("%d / %d%s" % [
		Run.deck.size(), Run.deck_limit,
		"  ·  " + I18N.t("ui.deck_remove_hint") if remove_mode else ""]))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 384)
	panel_vb.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for i in Run.deck.size():
		var inst: Dictionary = Run.deck[i]
		var cv := CardView.new()
		grid.add_child(cv)
		cv.setup(str(inst["key"]), str(inst["side"]), i)
		if remove_mode:
			cv.clicked.connect(func(idx: int): _do_remove(idx))

	var row := CenterContainer.new()
	panel_vb.add_child(row)
	var back := _mk_button(I18N.t("ui.back"))
	back.pressed.connect(_back_from_view)
	row.add_child(back)


func _do_remove(idx: int) -> void:
	if not Run.remove_card(idx):
		_toast(I18N.t("ui.cannot_remove"), Color("#B69AC0"))
		return
	_toast(I18N.t("ui.removed"), C_MOSS)
	if _remove_cb.is_valid():
		var cb := _remove_cb
		_remove_cb = Callable()
		cb.call()
	else:
		_show_deck(true)


func _back_from_view() -> void:
	match _view_origin:
		"map": _show_map()
		"pause": _show_pause()
		"shop": _show_shop(node)
		"rest": _show_rest(node)
		"win", "lose": _game_over(Run.outcome == "win")
		"": _hide_overlay()
		_: _show_map()


func _show_codex() -> void:
	_view_origin = _panel_mode
	_clear_panel()
	_show_overlay()
	_panel_mode = "codex"

	panel_vb.add_child(_panel_title(I18N.t("ui.codex")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.codex_sub", [CardDB.CARDS.size()])))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 384)
	panel_vb.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	var keys: Array = CardDB.CARDS.keys()
	keys.sort_custom(func(a, b):
		var da: Dictionary = CardDB.CARDS[a]
		var db: Dictionary = CardDB.CARDS[b]
		if str(da["type"]) != str(db["type"]):
			return str(da["type"]) < str(db["type"])
		return int(da["cost"]) < int(db["cost"])
	)
	for k in keys:
		var cv := CardView.new()
		grid.add_child(cv)
		cv.setup(str(k), "xian", -1)

	var row := CenterContainer.new()
	panel_vb.add_child(row)
	var back := _mk_button(I18N.t("ui.back"))
	back.pressed.connect(_back_from_view)
	row.add_child(back)


func _show_relics() -> void:
	_view_origin = _panel_mode
	_clear_panel()
	_show_overlay()
	_panel_mode = "relics"

	panel_vb.add_child(_panel_title(I18N.t("ui.relics")))
	panel_vb.add_child(_panel_sub("%d / 8" % Run.relic_count()))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 380)
	panel_vb.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)

	if Run.relics.is_empty():
		vb.add_child(_panel_sub(I18N.t("ui.no_relics")))
	for id in Run.relics:
		var b := _wide_button("%s  ·  %s\n%s" % [
			RelicDB.name(str(id)), _rarity_name(RelicDB.rarity_of(str(id))), RelicDB.desc(str(id))
		], RelicDB.rarity_of(str(id)))
		b.disabled = true
		vb.add_child(b)

	var row := CenterContainer.new()
	panel_vb.add_child(row)
	var back := _mk_button(I18N.t("ui.back"))
	back.pressed.connect(_back_from_view)
	row.add_child(back)


# ==================================================================
# 结算分享
# ==================================================================
func _show_share() -> void:
	_clear_panel()
	_show_overlay()
	_panel_mode = "share"

	panel_vb.add_child(_panel_title(I18N.t("ui.share")))
	panel_vb.add_child(_panel_sub(I18N.t("ui.share_sub")))

	var img := await _render_share()
	if img != null:
		var tex := ImageTexture.create_from_image(img)
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(300, 400)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame := CenterContainer.new()
		frame.add_child(tr)
		panel_vb.add_child(frame)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	panel_vb.add_child(row)

	var bc := _mk_button(I18N.t("ui.copy_text"))
	bc.pressed.connect(func():
		DisplayServer.clipboard_set(Run.share_text())
		_toast(I18N.t("ui.copied"), C_MOSS)
	)
	row.add_child(bc)

	var bs := _mk_button(I18N.t("ui.save_image"))
	bs.pressed.connect(func():
		var path := await _save_share()
		_toast(I18N.t("ui.saved", [path]), C_MOSS)
	)
	row.add_child(bs)

	var bb := _mk_button(I18N.t("ui.back"))
	bb.pressed.connect(func(): _game_over(Run.outcome == "win"))
	row.add_child(bb)


func _share_card() -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(720, 960)
	root.size = Vector2(720, 960)

	var bg := ColorRect.new()
	bg.color = Color("#12181C")
	bg.size = Vector2(720, 960)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var accent := ColorRect.new()
	accent.color = Color("#B23A30")
	accent.position = Vector2(0, 0)
	accent.size = Vector2(8, 960)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(accent)

	var margin := MarginContainer.new()
	margin.position = Vector2(56, 60)
	margin.size = Vector2(608, 840)
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	root.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	margin.add_child(vb)

	var t := Label.new()
	t.text = I18N.t("ui.title")
	t.add_theme_font_size_override("font_size", 40)
	t.add_theme_color_override("font_color", Color("#EAE6DC"))
	vb.add_child(t)

	var s := Label.new()
	s.text = I18N.t("ui.subtitle")
	s.add_theme_font_size_override("font_size", 18)
	s.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.45))
	vb.add_child(s)

	var line := ColorRect.new()
	line.color = Color(0.70, 0.23, 0.19, 0.5)
	line.custom_minimum_size = Vector2(120, 2)
	vb.add_child(line)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vb.add_child(spacer)

	var tag := Label.new()
	tag.text = I18N.t("diag." + Run.diagnosis)
	tag.add_theme_font_size_override("font_size", 56)
	tag.add_theme_color_override("font_color", Color("#C9A8B4"))
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(tag)

	var note := Label.new()
	note.text = I18N.t("diag.%s.c" % Run.diagnosis)
	note.add_theme_font_size_override("font_size", 22)
	note.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.66))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(note)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vb.add_child(spacer2)

	var stats := Label.new()
	stats.text = I18N.t("share.stats", [Run.rounds, Run.played, Run.self_damage, Run.grudge_peak])
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.42))
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(stats)

	var relic_line := Label.new()
	var names: Array = []
	for id in Run.relics:
		names.append(RelicDB.name(str(id)))
	relic_line.text = I18N.t("ui.relics") + "  " + (" / ".join(names) if not names.is_empty() else "—")
	relic_line.add_theme_font_size_override("font_size", 17)
	relic_line.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.34))
	relic_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_line.custom_minimum_size = Vector2(600, 0)
	vb.add_child(relic_line)

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grow)

	var foot := Label.new()
	foot.text = "%s  ·  SEED %d" % [I18N.t("share.tag"), Run.seed]
	foot.add_theme_font_size_override("font_size", 16)
	foot.add_theme_color_override("font_color", Color(0.70, 0.55, 0.25, 0.7))
	vb.add_child(foot)

	return root


func _render_share() -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(720, 960)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	add_child(vp)
	var card := _share_card()
	card.theme = ui_theme
	vp.add_child(card)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


func _save_share() -> String:
	var img := await _render_share()
	if img == null:
		return ""
	var name := "liaozhai_%d.png" % int(Time.get_unix_time_from_system())
	var path := "user://" + name
	img.save_png(path)
	var dir := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if dir != "":
		var abs := dir + "/" + name
		var err := img.save_png(abs)
		if err == OK:
			return abs
	return ProjectSettings.globalize_path(path)


# ==================================================================
# 小组件
# ==================================================================
func _rarity_color(r: String) -> Color:
	match r:
		"rare": return Color("#7FA8C9")
		"epic": return Color("#B69AC0")
		"legendary": return Color("#D8A54A")
		_: return Color("#A9BEC7")


func _rarity_name(r: String) -> String:
	return I18N.t("rarity." + r)


func _wide_button(text: String, rarity: String) -> Button:
	var b := Button.new()
	b.text = text
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(620, 54)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(13 * UI_S))
	b.add_theme_color_override("font_color", C_MOON)
	var col := _rarity_color(rarity)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.10)
	sb.border_color = Color(col.r, col.g, col.b, 0.50)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	var h := sb.duplicate() as StyleBoxFlat
	h.bg_color = Color(col.r, col.g, col.b, 0.24)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("disabled", sb)
	b.pressed.connect(func(): Audio.play_sfx("click", 0.02))
	return b


## 从暂停返回原来那一屏
func _resume() -> void:
	var m := _prev_mode
	_prev_mode = ""
	match m:
		"map":
			_show_map()
		"victory":
			_show_victory(_victory_kind, _victory_gold, _victory_heal)
		"shop":
			_show_shop(node)
		"rest":
			_show_rest(node)
		"treasure":
			_show_treasure(node)
		"event":
			_show_event(node)
		"codex":
			_show_codex()
		"relics":
			_show_relics()
		"deck", "deck_remove":
			_show_deck(false)
		"share":
			_show_share()
		"win", "lose":
			_game_over(Run.outcome == "win")
		_:
			_hide_overlay()
