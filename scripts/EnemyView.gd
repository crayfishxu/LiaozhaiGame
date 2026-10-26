class_name EnemyView
extends VBoxContainer

## ------------------------------------------------------------------
## 敌人视图
##
## [ART] 敌人立绘：res://art/enemies/{key}.png
##       存在则显示，否则显示占位字符（如「魂」「傀」）
##
## [FX] 受击 / 死亡特效：见 play_hit_fx() / play_death_fx()
## ------------------------------------------------------------------

signal clicked(index: int)

const BODY_W := 152.0
const BODY_H := 196.0
const BODY_H_MAX := 220.0
const HP_BAR_W := 136.0

const C_MOON := Color("#EAE6DC")
const C_CINNABAR := Color("#B23A30")
const C_MOSS := Color("#5A6B52")
const C_LOTUS := Color("#C9A8B4")

const INTENT_COLORS := {
	"attack": Color("#E39A8E"),
	"defend": Color("#9FB6BC"),
	"debuff": Color("#B69AC0"),
	"buff": Color("#C9B37A"),
	"sleep": Color(0.92, 0.90, 0.86, 0.34),
	"none": Color(0.92, 0.90, 0.86, 0.34),
}

var index := 0
var enemy_key := ""
var body_w := BODY_W
var body_h := BODY_H
var glyph_text := ""
var hp := 0
var max_hp := 1
var block := 0
var poison := 0
var weak := 0
var bind := 0
var dead := false
var targetable := false

var _intent_label: Label
var _intent_panel: PanelContainer
var _intent_style: StyleBoxFlat
var _body_panel: PanelContainer
var _body_style: StyleBoxFlat
var _art_rect: TextureRect
var _glyph_label: Label
var _name_label: Label
var _hp_bar: Control
var _hp_fill: ColorRect
var _hp_label: Label
var _status_box: HBoxContainer
var _target_frame: PanelContainer


func setup(data: Dictionary, idx: int) -> void:
	index = idx
	enemy_key = str(data.get("key", ""))
	glyph_text = str(data.get("glyph", ""))
	max_hp = int(data.get("hp", 1))
	hp = max_hp
	# 精英 / BOSS 可用更大的立绘（art_h），普通敌人保持 132x172
	var want := clampf(float(data.get("art_h", BODY_H)), BODY_H, BODY_H_MAX)
	body_h = want
	body_w = want * (BODY_W / BODY_H)
	add_theme_constant_override("separation", 6)
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build(I18N.enemy_name(enemy_key))
	refresh()
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)


func _build(enemy_name: String) -> void:
	# ---- 意图条 ----
	_intent_panel = PanelContainer.new()
	_intent_panel.custom_minimum_size = Vector2(0, 28)
	_intent_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# 装饰性子节点一律 IGNORE：事件必须能穿透到最外层的 EnemyView，
	# 否则点立绘/意图条/血条都不会响应（PanelContainer 会吃掉点击）
	_intent_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_style = StyleBoxFlat.new()
	_intent_style.set_corner_radius_all(2)
	_intent_style.set_border_width_all(1)
	_intent_style.content_margin_left = 12
	_intent_style.content_margin_right = 12
	_intent_panel.add_theme_stylebox_override("panel", _intent_style)
	add_child(_intent_panel)

	_intent_label = Label.new()
	_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intent_label.add_theme_font_size_override("font_size", 16)
	_intent_panel.add_child(_intent_label)

	# ---- 立绘框 ----
	_body_panel = PanelContainer.new()
	_body_panel.custom_minimum_size = Vector2(body_w, body_h)
	_body_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_body_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_style = StyleBoxFlat.new()
	_body_style.bg_color = Color(0.92, 0.90, 0.86, 0.09)
	_body_style.border_color = Color(0.92, 0.90, 0.86, 0.22)
	_body_style.set_border_width_all(1)
	_body_panel.add_theme_stylebox_override("panel", _body_style)
	add_child(_body_panel)

	var body_root := Control.new()
	body_root.custom_minimum_size = Vector2(body_w, body_h)
	body_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_panel.add_child(body_root)

	_art_rect = TextureRect.new()
	_art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_rect.position = Vector2.ZERO
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_root.add_child(_art_rect)

	_glyph_label = Label.new()
	_glyph_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glyph_label.position = Vector2.ZERO
	_glyph_label.text = glyph_text
	_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph_label.add_theme_font_size_override("font_size", 56)
	_glyph_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.8))
	_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_root.add_child(_glyph_label)

	# ---- 选中目标框 ----
	# 有立绘时 _body_panel 的 stylebox 会被换成 StyleBoxEmpty（避免透出底色），
	# 那样 set_targetable() 改的边框就看不见了。所以选中框必须独立成一层。
	_target_frame = PanelContainer.new()
	_target_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_target_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0, 0, 0, 0)
	fsb.border_color = C_CINNABAR
	fsb.set_border_width_all(3)
	fsb.set_corner_radius_all(2)
	_target_frame.add_theme_stylebox_override("panel", fsb)
	_target_frame.visible = false
	body_root.add_child(_target_frame)

	# ---- 名字 ----
	_name_label = Label.new()
	_name_label.text = enemy_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 17)
	_name_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.78))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.clip_text = true
	add_child(_name_label)

	# ---- 血条 ----
	_hp_bar = Control.new()
	_hp_bar.custom_minimum_size = Vector2(HP_BAR_W, 5)
	_hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.12)
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.add_child(bar_bg)

	_hp_fill = ColorRect.new()
	_hp_fill.color = C_CINNABAR
	_hp_fill.position = Vector2.ZERO
	_hp_fill.size = Vector2(HP_BAR_W, 5)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.add_child(_hp_fill)

	# ---- 血量文字 ----
	_hp_label = Label.new()
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.5))
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_label)

	# ---- 状态 ----
	_status_box = HBoxContainer.new()
	_status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_status_box.add_theme_constant_override("separation", 5)
	_status_box.custom_minimum_size = Vector2(0, 22)
	_status_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_box)


## 由 Battle 每帧状态变化时调用
func refresh_from(e: Dictionary) -> void:
	hp = int(e.get("hp", hp))
	max_hp = int(e.get("max_hp", max_hp))
	block = int(e.get("block", 0))
	poison = int(e.get("poison", 0))
	weak = int(e.get("weak", 0))
	bind = int(e.get("bind", 0))
	dead = bool(e.get("dead", false))

	var it: Dictionary = e.get("intent", {})
	_intent_label.text = I18N.intent_text(it) if not it.is_empty() else "—"
	var kind := str(it.get("kind", "none"))
	if bind > 0:
		kind = "sleep"
		_intent_label.text = I18N.t("ui.bound")
	_intent_label.add_theme_color_override("font_color", INTENT_COLORS.get(kind, C_MOON))
	_intent_style.border_color = Color(INTENT_COLORS.get(kind, C_MOON), 0.45)
	_intent_style.bg_color = Color(INTENT_COLORS.get(kind, C_MOON), 0.10)

	refresh()


func refresh() -> void:
	var ratio := clampf(float(hp) / float(max(1, max_hp)), 0.0, 1.0)
	_hp_fill.size = Vector2(HP_BAR_W * ratio, 5.0)
	_hp_label.text = "%d / %d" % [max(0, hp), max_hp]

	# 状态标签
	for c in _status_box.get_children():
		_status_box.remove_child(c)
		c.queue_free()
	if block > 0:
		_status_box.add_child(_chip(_stat("w.block", block), Color("#A9BEC7")))
	if poison > 0:
		_status_box.add_child(_chip(_stat("w.poison", poison), Color("#8FA36F")))
	if weak > 0:
		_status_box.add_child(_chip(_stat("w.weak", weak), Color("#B69AC0")))
	if bind > 0:
		_status_box.add_child(_chip(_stat("w.bind", bind), Color("#9FB6BC")))

	# 立绘 / 占位
	var art := AssetLoader.enemy_art(enemy_key)
	if art != null:
		_art_rect.texture = art
		_art_rect.visible = true
		_glyph_label.visible = false
		# 有立绘时彻底去掉占位框的底色与描边，避免透出一圈浅灰
		_body_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		_art_rect.visible = false
		_glyph_label.visible = true
		_body_style.bg_color = Color(0.92, 0.90, 0.86, 0.09)
		_body_style.border_color = Color(0.92, 0.90, 0.86, 0.22)
		_body_panel.add_theme_stylebox_override("panel", _body_style)

	modulate.a = 0.24 if dead else 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE if dead else Control.MOUSE_FILTER_STOP

	_fit_name()
	_fit_intent()


## "障 5" —— 词与数字分开存，翻译时不用为每种语言再写一遍模板
func _stat(word_key: String, value: int) -> String:
	return "%s %d" % [I18N.t(word_key), value]


## 名字过长时缩字号（德语/俄语常见）
func _fit_name() -> void:
	var font := _name_label.get_theme_font("font")
	if font == null:
		return
	var max_w := body_w + 26.0
	var size := 17
	while size > 10 and font.get_string_size(
			_name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w:
		size -= 1
	_name_label.add_theme_font_size_override("font_size", size)


## 意图条同理，但不能缩得太小，否则看不清
func _fit_intent() -> void:
	var font := _intent_label.get_theme_font("font")
	if font == null:
		return
	var max_w := body_w + 30.0
	var size := 16
	while size > 11 and font.get_string_size(
			_intent_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w:
		size -= 1
	_intent_label.add_theme_font_size_override("font_size", size)


func _chip(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(2)
	sb.bg_color = Color(color, 0.14)
	sb.border_color = Color(color, 0.5)
	sb.set_border_width_all(1)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", color)
	p.add_child(l)
	return p


func set_targetable(v: bool) -> void:
	targetable = v
	if dead:
		if _target_frame != null:
			_target_frame.visible = false
		return
	# 独立描边层：立绘存在时也能看见
	if _target_frame != null and is_instance_valid(_target_frame):
		_target_frame.visible = v
	if _art_rect != null and is_instance_valid(_art_rect):
		_art_rect.modulate = Color(1.14, 1.06, 1.02) if v else Color.WHITE
	if v:
		_body_style.border_color = C_CINNABAR
		_body_style.set_border_width_all(2)
	else:
		_body_style.border_color = Color(0.92, 0.90, 0.86, 0.22)
		_body_style.set_border_width_all(1)


func set_dead(v: bool) -> void:
	dead = v
	refresh()
	if v:
		play_death_fx()


func _on_gui_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(index)


func _on_enter() -> void:
	if dead:
		return
	if targetable:
		play_hover_fx()


func _on_exit() -> void:
	pass


## [FX] 敌人受击：美术可加闪白、粒子、震屏
func play_hit_fx() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.6, 1.1, 1.1, 1.0), 0.06)
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)


## [FX] 敌人死亡：美术可加消散、烟雾
func play_death_fx() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.24, 0.5)
	tw.tween_property(self, "scale", Vector2(0.92, 0.92), 0.5)


## [FX] 悬停高亮
func play_hover_fx() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		if not dead:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2.ONE, 0.12)
