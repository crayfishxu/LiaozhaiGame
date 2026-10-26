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
var _pause_open: bool = false


func _ready() -> void:
	_build_theme()
	_build_ui()
	start_game()
	_show_intro()


# ==================================================================
# 系统返回键（Android）
# ==================================================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_requested()


## 返回键语义：暂停菜单开着就关掉，否则呼出暂停菜单
func _on_back_requested() -> void:
	if overlay.visible and _pause_open:
		_hide_overlay()
		return
	_show_pause()


# ==================================================================
# 主题（中文字体：走系统字体，避免打包字体文件）
# ==================================================================
func _build_theme() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "PingFang SC",
		"Noto Sans CJK SC", "Source Han Sans SC",
		"WenQuanYi Micro Hei", "SimHei", "sans-serif",
	])
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

	layer_label = _mk_label("第 一 层 · 初 见", 12, Color("#D46B60"))
	top.add_child(layer_label)

	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.15)
	sep.custom_minimum_size = Vector2(1, 14)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(sep)

	chapter_label = _mk_label("兰若寺", 12, Color(0.92, 0.90, 0.86, 0.62))
	top.add_child(chapter_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	var hp_wrap := HBoxContainer.new()
	hp_wrap.add_theme_constant_override("separation", 10)
	hp_wrap.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(hp_wrap)

	hp_wrap.add_child(_mk_label("魂 火", 11, Color(0.92, 0.90, 0.86, 0.58)))

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
	gw.add_child(_mk_label("怨 气", 12, Color(0.92, 0.90, 0.86, 0.42)))
	grudge_label = _mk_label("0", 16, C_CINNABAR)
	gw.add_child(grudge_label)
	block_label = _mk_label("", 12, C_BLOCK)
	gw.add_child(block_label)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(sp)

	# 选中需要指定目标的卡时，这里会亮起来告诉玩家下一步做什么
	target_hint = _mk_label("▸ 点 一 个 敌 人", 12, Color("#E39A8E"))
	target_hint.visible = false
	mid.add_child(target_hint)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(18, 1)
	mid.add_child(sp2)

	var piles := HBoxContainer.new()
	piles.add_theme_constant_override("separation", 20)
	mid.add_child(piles)
	piles.add_child(_mk_label("忆", 11, Color(0.92, 0.90, 0.86, 0.3)))
	draw_label = _mk_label("0", 11, Color(0.92, 0.90, 0.86, 0.62))
	piles.add_child(draw_label)
	piles.add_child(_mk_label("忘", 11, Color(0.92, 0.90, 0.86, 0.3)))
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
	end_turn_btn.text = "结 束 回 合"
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
	add_child(overlay)

	var ob := ColorRect.new()
	ob.color = Color(0.031, 0.043, 0.055, 0.76)
	ob.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(ob)

	var oc := CenterContainer.new()
	oc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(oc)

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
	player_hp = START_HP
	player_max_hp = START_HP
	player_block = 0
	energy = ENERGY_PER_TURN
	max_energy = ENERGY_PER_TURN
	grudge = 0
	player_poison = 0
	thorns = 0
	powers.clear()
	draw_pile = _starter_deck()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	enemies.clear()
	wave = 0
	busy = false
	selected_index = -1
	game_active = true
	_hide_overlay()
	start_wave(0)


func _starter_deck() -> Array:
	var d: Array = []
	for i in 4:
		d.append({"key": "sushou", "side": "xian"})
	for i in 4:
		d.append({"key": "suyi", "side": "xian"})
	d.append({"key": "youyuan", "side": "xian"})
	d.append({"key": "yinlu", "side": "xian"})
	d.append({"key": "sushou", "side": "ben"})
	d.append({"key": "yeku", "side": "xian"})
	return d


func start_wave(idx: int) -> void:
	wave = idx
	var cfg: Dictionary = EnemyDB.WAVES[idx]
	layer_label.text = str(cfg["layer"])
	chapter_label.text = str(cfg["chapter"])

	# [ART] 每层换背景，缺图时回退通用背景
	if bg_tex != null:
		var bgimg := AssetLoader.battle_bg(idx)
		if bgimg != null:
			bg_tex.texture = bgimg
			bg_tex.visible = true

	for c in field_box.get_children():
		field_box.remove_child(c)
		c.queue_free()
	enemies.clear()

	var keys: Array = cfg["enemies"]
	for i in keys.size():
		var key := str(keys[i])
		var data: Dictionary = (EnemyDB.ENEMIES[key] as Dictionary).duplicate(true)
		data["key"] = key
		var ev := EnemyView.new()
		field_box.add_child(ev)
		ev.setup(data, i)
		ev.clicked.connect(_on_enemy_clicked)
		enemies.append({
			"key": key,
			"name": str(data["name"]),
			"hp": int(data["hp"]),
			"max_hp": int(data["hp"]),
			"block": 0,
			"poison": 0,
			"weak": 0,
			"bind": 0,
			"weaken": 0,
			"move_idx": 0,
			"moves": data["moves"],
			"intent": {},
			"dead": false,
			"view": ev,
		})

	# 所有卡牌收回重洗
	var all_cards: Array = []
	all_cards.append_array(draw_pile)
	all_cards.append_array(hand)
	all_cards.append_array(discard_pile)
	all_cards.shuffle()
	draw_pile = all_cards
	hand.clear()
	discard_pile.clear()

	begin_player_turn()


func begin_player_turn() -> void:
	busy = false
	selected_index = -1
	player_block = 0
	thorns = 0
	energy = max_energy
	first_card_played = false

	if player_poison > 0:
		var pd := player_poison
		player_hp -= pd
		player_poison -= 1
		_float_at(_player_anchor(), "-%d" % pd, C_ROUGE)

	if bool(powers.get("grudge_turn", false)):
		grudge += 2

	_draw_cards(DRAW_PER_TURN)
	_schedule_intents()
	_refresh_all()


func _schedule_intents() -> void:
	for e in enemies:
		if bool(e["dead"]):
			continue
		if int(e["bind"]) > 0:
			e["intent"] = {"kind": "sleep", "label": "缠 缚"}
			continue
		var moves: Array = e["moves"]
		var m: Dictionary = moves[int(e["move_idx"]) % moves.size()]
		e["intent"] = m
		e["move_idx"] = int(e["move_idx"]) + 1


func _draw_cards(n: int) -> void:
	for i in n:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			draw_pile.shuffle()
			discard_pile.clear()
		hand.append(draw_pile.pop_back())


func _on_end_turn() -> void:
	if busy or not game_active:
		return
	busy = true
	selected_index = -1
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
			_float_at(_enemy_anchor(e), "缠 缚", C_DAI)
			_refresh_all()
			await get_tree().create_timer(0.34).timeout
			continue

		var it: Dictionary = e["intent"]
		var kind := str(it.get("kind", "attack"))
		var val := int(it.get("val", 0))

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
		elif kind == "defend":
			e["block"] = int(e["block"]) + val
			_float_at(_enemy_anchor(e), "+%d" % val, C_BLOCK)
		elif kind == "debuff":
			player_poison += val
			_float_at(_player_anchor(), "毒 +%d" % val, C_MOSS)

		# 敌人中毒结算
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
		_wave_clear()
		return
	begin_player_turn()


func _damage_player(dmg: int) -> int:
	var d := dmg
	if player_block > 0:
		var absorbed: int = mini(player_block, d)
		player_block -= absorbed
		d -= absorbed
	if d > 0:
		player_hp -= d
		var g := 2
		if bool(powers.get("grudge_hurt", false)):
			g += 2
		grudge += g
	return d


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


func _wave_clear() -> void:
	busy = true
	if wave >= EnemyDB.WAVES.size() - 1:
		_game_over(true)
		return
	_show_reward()


# ==================================================================
# 出牌
# ==================================================================
func _on_card_clicked(idx: int) -> void:
	if busy:
		_toast("敌人行动中…", Color(0.80, 0.76, 0.70, 0.92))
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
	if int(def["cost"]) > energy:
		_toast("心力不足 · 需要 %d 点" % int(def["cost"]), Color("#E39A8E"))
		return
	if str(def["type"]) == "curse":
		_toast("祟 牌 无 法 打 出", Color("#B69AC0"))
		return

	if bool(def["target"]):
		var was_same := selected_index == idx
		selected_index = -1 if was_same else idx
		if was_same:
			_toast("已取消选择", Color(0.80, 0.76, 0.70, 0.92))
		_refresh_hand()
		_refresh_highlight()
	else:
		play_card(idx, -1)


func _on_enemy_clicked(idx: int) -> void:
	if busy:
		return
	if selected_index < 0:
		_toast("先点一张牌，再点敌人", Color(0.80, 0.76, 0.70, 0.92))
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
	if int(def["cost"]) > energy:
		return
	if str(def["type"]) == "curse":
		return

	energy -= int(def["cost"])
	var cur_side := str(inst["side"])
	var fx: Dictionary = def[cur_side]

	# 能力牌
	if fx.has("power"):
		powers[str(fx["power"])] = true

	# 本回合首次出牌的被动
	if not first_card_played:
		if bool(powers.get("block_first", false)):
			player_block += 2
			_float_at(_player_anchor(), "+2", C_BLOCK)
		if bool(powers.get("dmg_first", false)):
			var alive := _alive_enemies()
			if alive.size() > 0:
				var t: Dictionary = alive[randi() % alive.size()]
				_hit_enemy(t, 4)
				_float_at(_enemy_anchor(t), "-4", C_ROUGE)
	first_card_played = true

	# 自损
	if fx.has("self_hp"):
		var sh := int(fx["self_hp"])
		player_hp -= sh
		_float_at(_player_anchor(), "-%d" % sh, C_ROUGE)
		if bool(powers.get("grudge_hurt", false)):
			grudge += 2

	# 护盾
	if fx.has("block"):
		var bv := int(fx["block"])
		player_block += bv
		_float_at(_player_anchor(), "+%d" % bv, C_BLOCK)

	if fx.has("thorns"):
		thorns += int(fx["thorns"])

	if fx.has("energy"):
		energy += int(fx["energy"])

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
			if di < h_idx:
				h_idx -= 1

	if fx.has("draw"):
		_draw_cards(int(fx["draw"]))

	# 目标
	var tgt: Dictionary = {}
	if t_idx >= 0 and t_idx < enemies.size() and not bool(enemies[t_idx]["dead"]):
		tgt = enemies[t_idx]

	var sp := str(fx.get("special", ""))

	if sp == "poison_strike" and not tgt.is_empty():
		var d := int(tgt["poison"]) * 2
		_hit_enemy(tgt, d)
		_float_at(_enemy_anchor(tgt), "-%d" % d, C_ROUGE)
	elif sp == "grudge_bonus" and not tgt.is_empty():
		var d := int(fx["dmg"]) + int(floor(float(grudge) / 5.0)) * 2
		_hit_enemy(tgt, d)
		_float_at(_enemy_anchor(tgt), "-%d" % d, C_ROUGE)
	elif sp == "grudge_burn" and not tgt.is_empty():
		var d := grudge * 2
		grudge = 0
		_hit_enemy(tgt, d)
		_float_at(_enemy_anchor(tgt), "-%d" % d, C_ROUGE)
	elif fx.has("dmg") and not tgt.is_empty():
		var hits := int(fx.get("hits", 1))
		var total := 0
		for h in hits:
			var d := int(fx["dmg"])
			_hit_enemy(tgt, d)
			total += d
		_float_at(_enemy_anchor(tgt), "-%d" % total, C_ROUGE)
		var tv = tgt.get("view", null)
		if tv != null and is_instance_valid(tv):
			(tv as EnemyView).play_hit_fx()

	# 全体伤害
	if fx.has("aoe_dmg"):
		var ad := int(fx["aoe_dmg"])
		for e in enemies:
			if bool(e["dead"]):
				continue
			_hit_enemy(e, ad)
			_float_at(_enemy_anchor(e), "-%d" % ad, C_ROUGE)

	# 单体毒
	if fx.has("poison") and not tgt.is_empty():
		tgt["poison"] = int(tgt["poison"]) + int(fx["poison"])

	# 全体减益
	if fx.has("aoe_weak"):
		for e in enemies:
			if bool(e["dead"]):
				continue
			e["weak"] = int(e["weak"]) + int(fx["aoe_weak"])

	# 缠绕
	if fx.has("bind") and not tgt.is_empty():
		tgt["bind"] = int(tgt["bind"]) + int(fx["bind"])

	# 削弱
	if fx.has("weaken_enemy") and not tgt.is_empty():
		tgt["weaken"] = int(tgt["weaken"]) + int(fx["weaken_enemy"])

	# 清理死亡
	for e in enemies:
		if not bool(e["dead"]) and int(e["hp"]) <= 0:
			_kill_enemy(e)

	# 翻面 + 入弃牌堆
	inst["side"] = "ben" if cur_side == "xian" else "xian"
	discard_pile.append(inst)
	hand.remove_at(h_idx)

	selected_index = -1
	_refresh_all()

	if player_hp <= 0:
		await get_tree().create_timer(0.35).timeout
		_game_over(false)
		return
	if _all_dead():
		await get_tree().create_timer(0.45).timeout
		_wave_clear()


# ==================================================================
# 刷新
# ==================================================================
func _refresh_all() -> void:
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
	block_label.text = ("障 %d" % player_block) if player_block > 0 else ""
	block_label.add_theme_color_override("font_color", C_BLOCK)


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
		cv.setup(key, str(inst["side"]), i)

		var def: Dictionary = CardDB.CARDS[key]
		var dis := int(def["cost"]) > energy or str(def["type"]) == "curse"
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
	for c in panel_vb.get_children():
		panel_vb.remove_child(c)
		c.queue_free()


func _show_overlay() -> void:
	overlay.visible = true


func _hide_overlay() -> void:
	overlay.visible = false
	_pause_open = false


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
	return b


func _show_intro() -> void:
	_clear_panel()
	_show_overlay()

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

	col.add_child(_panel_title("聊 斋 美 人"))
	col.add_child(_panel_sub("战斗原型 · 兰若寺"))

	var tip := Label.new()
	tip.text = "每张卡牌有「显相」与「本相」两面。\n打出后自动翻面 —— 同一张牌，两套用法。\n\n显相偏防御与稳定，本相偏爆发但有代价。\n受伤积累「怨气」，怨气越深，某些牌越强。"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", int(13 * UI_S))
	tip.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.62))
	tip.add_theme_constant_override("line_spacing", 8)
	col.add_child(tip)

	var brow := CenterContainer.new()
	col.add_child(brow)
	var b := _mk_button("入 梦")
	b.pressed.connect(_hide_overlay)
	brow.add_child(b)


func _show_reward() -> void:
	_clear_panel()
	_show_overlay()

	panel_vb.add_child(_panel_title("拾 得 情 念"))
	panel_vb.add_child(_panel_sub("选一张，入你的牌组"))

	var pool: Array = CardDB.REWARD_POOL.duplicate()
	pool.shuffle()
	var picks: Array = pool.slice(0, 3)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	panel_vb.add_child(row)

	for k in picks:
		var kk := str(k)
		var side := "xian" if randf() < 0.5 else "ben"
		var cv := CardView.new()
		row.add_child(cv)
		cv.setup(kk, side, -1)
		cv.clicked.connect(func(_i: int):
			draw_pile.append({"key": kk, "side": side})
			draw_pile.shuffle()
			_hide_overlay()
			start_wave(wave + 1)
		)

	var brow := CenterContainer.new()
	panel_vb.add_child(brow)
	var skip := _mk_button("不 取")
	skip.pressed.connect(func():
		_hide_overlay()
		start_wave(wave + 1)
	)
	brow.add_child(skip)


func _game_over(win: bool) -> void:
	game_active = false
	_clear_panel()
	_show_overlay()
	_pause_open = false

	if win:
		panel_vb.add_child(_panel_title("心 劫 已 解"))
		panel_vb.add_child(_panel_sub("兰若寺的雾散了。\n她站在光里，第一次没有低着头。\n\n「谢谢你……记得我。」"))
	else:
		panel_vb.add_child(_panel_title("魂 火 将 熄"))
		panel_vb.add_child(_panel_sub("你退了出来。\n她还在等 —— 等下一个愿意听的人。\n\n『这一世的执念，没能解开。』"))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	panel_vb.add_child(row)

	var b := _mk_button("再 来 一 次")
	b.pressed.connect(func():
		_hide_overlay()
		start_game()
	)
	row.add_child(b)

	var bq := _mk_button("退 出")
	bq.pressed.connect(_quit_to_desktop)
	row.add_child(bq)


# ==================================================================
# 暂停菜单 / 退出
# ==================================================================
func _show_pause() -> void:
	_clear_panel()
	_show_overlay()
	_pause_open = true

	panel_vb.add_child(_panel_title("暂 停"))
	panel_vb.add_child(_panel_sub("兰若寺的雾，还在等你。"))

	# 结算之后没有"继续"可言，只留重开与退出
	if game_active:
		var r1 := CenterContainer.new()
		panel_vb.add_child(r1)
		var b1 := _mk_button("继 续 游 戏")
		b1.pressed.connect(func(): _hide_overlay())
		r1.add_child(b1)

	var r2 := CenterContainer.new()
	panel_vb.add_child(r2)
	var b2 := _mk_button("重 新 开 始")
	b2.pressed.connect(func():
		_hide_overlay()
		start_game()
	)
	r2.add_child(b2)

	var r3 := CenterContainer.new()
	panel_vb.add_child(r3)
	var b3 := _mk_button("退 出 到 桌 面")
	b3.pressed.connect(_quit_to_desktop)
	r3.add_child(b3)

	var hint := Label.new()
	hint.text = "返回键可再次呼出本菜单"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", int(11 * UI_S))
	hint.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.30))
	panel_vb.add_child(hint)


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
