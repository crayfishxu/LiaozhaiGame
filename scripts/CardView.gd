class_name CardView
extends PanelContainer

## ------------------------------------------------------------------
## 卡牌视图
##
## [ART] 美术接入点：
##   卡面图放到  res://art/cards/{卡牌key}_{xian|ben}.png
##   例如      res://art/cards/sushou_xian.png
##   存在则自动显示，不存在则显示占位字符。
##
## [FX] 特效接入点：见 play_hover_fx() / play_play_fx()
## ------------------------------------------------------------------

signal clicked(index: int)

const C_MOON := Color("#EAE6DC")
const C_LOTUS := Color("#C9A8B4")
const C_ROUGE := Color("#A83E4C")
const C_CINNABAR := Color("#B23A30")

const CARD_W := 130.0
const CARD_H := 196.0

var hand_index := -1
var card_key := ""
var side := "xian"
var view_disabled := false
var cost_override := -1

var _style: StyleBoxFlat
var _name_label: Label
var _text_label: Label
var _cost_label: Label
var _cost_panel: PanelContainer
var _side_label: Label
var _glyph_label: Label
var _art_rect: TextureRect


func setup(key: String, p_side: String, idx: int = -1, p_cost: int = -1) -> void:
	card_key = key
	side = p_side
	hand_index = idx
	cost_override = p_cost
	_build()
	_apply_visual()


func _build() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(3)
	_style.set_border_width_all(1)
	_style.content_margin_left = 0
	_style.content_margin_right = 0
	_style.content_margin_top = 0
	_style.content_margin_bottom = 0
	add_theme_stylebox_override("panel", _style)

	var root := Control.new()
	root.custom_minimum_size = Vector2(CARD_W, CARD_H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ---- 费用圆 ----
	_cost_panel = PanelContainer.new()
	_cost_panel.position = Vector2(9, 8)
	_cost_panel.size = Vector2(24, 24)
	_cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var csb := StyleBoxFlat.new()
	csb.set_corner_radius_all(12)
	csb.bg_color = Color("#22282C")
	_cost_panel.add_theme_stylebox_override("panel", csb)
	root.add_child(_cost_panel)

	_cost_label = Label.new()
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.add_theme_font_size_override("font_size", 15)
	_cost_label.add_theme_color_override("font_color", Color("#E9E4D9"))
	_cost_panel.add_child(_cost_label)

	# ---- 显 / 本 标识 ----
	_side_label = Label.new()
	_side_label.position = Vector2(38, 10)
	_side_label.size = Vector2(84, 18)
	_side_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_side_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_side_label.add_theme_font_size_override("font_size", 14)
	_side_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_side_label)

	# ---- 卡名 ----
	_name_label = Label.new()
	_name_label.position = Vector2(0, 32)
	_name_label.size = Vector2(CARD_W, 28)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_name_label)

	# ---- 立绘区 [ART] ----
	_art_rect = TextureRect.new()
	_art_rect.position = Vector2(10, 59)
	_art_rect.size = Vector2(CARD_W - 20, 82)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_art_rect)

	_glyph_label = Label.new()
	_glyph_label.position = Vector2(10, 59)
	_glyph_label.size = Vector2(CARD_W - 20, 82)
	_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph_label.add_theme_font_size_override("font_size", 34)
	_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_glyph_label)

	# 分隔线
	var line := ColorRect.new()
	line.position = Vector2(10, 58)
	line.size = Vector2(CARD_W - 20, 1)
	line.color = Color(0.5, 0.5, 0.5, 0.16)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)

	var line2 := ColorRect.new()
	line2.position = Vector2(10, 144)
	line2.size = Vector2(CARD_W - 20, 1)
	line2.color = Color(0.5, 0.5, 0.5, 0.16)
	line2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line2)

	# ---- 描述 ----
	_text_label = Label.new()
	_text_label.position = Vector2(9, 148)
	_text_label.size = Vector2(CARD_W - 18, 40)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 14)
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_text_label)

	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _apply_visual() -> void:
	if not CardDB.CARDS.has(card_key):
		return
	var def: Dictionary = CardDB.CARDS[card_key]
	var fx: Dictionary = def[side]

	_cost_label.text = str(int(def["cost"]) if cost_override < 0 else cost_override)
	_name_label.text = I18N.card_name(card_key)
	_text_label.text = CardText.build(card_key, side)
	_glyph_label.text = str(def["glyph"])

	if side == "xian":
		_style.bg_color = Color("#E9E4D9")
		_art_rect.modulate = Color(1.26, 1.23, 1.18)
		_style.border_color = Color(0.85, 0.82, 0.76, 0.9)
		_name_label.add_theme_color_override("font_color", Color("#1B2024"))
		_text_label.add_theme_color_override("font_color", Color("#3B4247"))
		_glyph_label.add_theme_color_override("font_color", Color(0.66, 0.24, 0.30, 0.5))
		_cost_panel.get_theme_stylebox("panel").bg_color = Color("#22282C")
		_cost_label.add_theme_color_override("font_color", Color("#E9E4D9"))
		_side_label.add_theme_color_override("font_color", Color("#6B7276"))
	else:
		_style.bg_color = Color("#232D33")
		_art_rect.modulate = Color(1.02, 0.98, 0.96)
		_style.border_color = Color(0.70, 0.23, 0.19, 0.75)
		_name_label.add_theme_color_override("font_color", Color("#F0EAE0"))
		_text_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.82))
		_glyph_label.add_theme_color_override("font_color", Color(0.90, 0.65, 0.62, 0.65))
		_cost_panel.get_theme_stylebox("panel").bg_color = Color("#B23A30")
		_cost_label.add_theme_color_override("font_color", Color("#F2EDE3"))
		_side_label.add_theme_color_override("font_color", Color("#C4645A"))

	_side_label.text = I18N.t("ui.side_xian" if side == "xian" else "ui.side_ben")
	_fit_labels()

	# [ART] 有卡面图则显示，无则显示占位字符
	var art := load_art()
	if art != null:
		_art_rect.texture = art
		_art_rect.visible = true
		_glyph_label.visible = false
	else:
		_art_rect.visible = false
		_glyph_label.visible = true

	set_disabled(view_disabled)


## 不同语言的文本长度差很大（德语、俄语常比中文长一倍），
## 卡面尺寸又是固定的，所以按实际排版结果把字号缩到放得下为止。
func _fit_labels() -> void:
	var font := _name_label.get_theme_font("font")
	if font == null:
		return

	# 卡名：单行，宽度超出就逐级缩小
	var nsize := 20
	while nsize > 11 and font.get_string_size(
			_name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, nsize).x > CARD_W - 10:
		nsize -= 1
	_name_label.add_theme_font_size_override("font_size", nsize)

	# 显相 / 本相：德语、俄语的词比中文长得多
	var ssize := 14
	while ssize > 8 and font.get_string_size(
			_side_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ssize).x > 82:
		ssize -= 1
	_side_label.add_theme_font_size_override("font_size", ssize)

	# 描述：按换行后的总高度缩，保证塞进 40px 的框里
	var tsize := 14
	while tsize > 9:
		var sz := font.get_multiline_string_size(
			_text_label.text, HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 20, tsize)
		if sz.y <= 40.0:
			break
		tsize -= 1
	_text_label.add_theme_font_size_override("font_size", tsize)


## [ART] 卡面图：统一走 AssetLoader，约定路径见 AssetLoader 头部注释
func load_art() -> Texture2D:
	return AssetLoader.card_art(card_key, side)


func set_disabled(v: bool) -> void:
	view_disabled = v
	modulate.a = 0.52 if v else 1.0
	if v:
		scale = Vector2.ONE


func set_selected(v: bool) -> void:
	_style.border_color = C_CINNABAR if v else (
		Color(0.85, 0.82, 0.76, 0.9) if side == "xian" else Color(0.70, 0.23, 0.19, 0.75)
	)
	_style.set_border_width_all(2 if v else 1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.1, 1.1) if v else Vector2.ONE, 0.12)


func _on_gui_input(event: InputEvent) -> void:
	if view_disabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			play_play_fx()
			clicked.emit(hand_index)


func _on_mouse_entered() -> void:
	if view_disabled:
		return
	play_hover_fx()


func _on_mouse_exited() -> void:
	if view_disabled:
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)


## [FX] 悬停特效：美术可在此加描边光晕、粒子
func play_hover_fx() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.07, 1.07), 0.12)


## [FX] 出牌特效：美术可在此加飞行动画、光效
func play_play_fx() -> void:
	pass
