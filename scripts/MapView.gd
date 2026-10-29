class_name MapView
extends Control

## ==================================================================
## 地图界面：自下而上的分支路径
##
## 只负责画和点。节点结算在 Battle.gd。
## ==================================================================

signal node_chosen(id: String)
signal open_deck
signal open_relics
signal open_codex

const NODE_R := 27.0

## 与 Battle 同步的字号增量
const FONT_ADD := 2
const HEADER_H := 54.0
const FOOTER_H := 12.0

const TYPE_COLOR := {
	"battle": Color("#8C4B42"),
	"elite": Color("#6B3F5C"),
	"event": Color("#3F4E58"),
	"shop": Color("#6A5630"),
	"rest": Color("#2F5148"),
	"treasure": Color("#5E5630"),
	"boss": Color("#7A2A26"),
}

var map_data: Dictionary = {}
var current_id: String = ""
var avail_ids: Array = []
var theme_ref: Theme
var title_text: String = ""
var chapter_text: String = ""

var _centers: Dictionary = {}
var _buttons: Dictionary = {}
var _header: HBoxContainer


func setup(data: Dictionary, cur: String, avail: Array, th: Theme, title: String, chapter: String) -> void:
	map_data = data
	current_id = cur
	avail_ids = avail.duplicate()
	theme_ref = th
	title_text = title
	chapter_text = chapter


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if theme_ref != null:
		theme = theme_ref
	_build()
	resized.connect(_layout)


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.055, 0.066, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 顶部信息条
	_header = HBoxContainer.new()
	_header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_header.offset_left = 96      # 28 边距 + 56 菜单按钮 + 12 间隔
	_header.offset_right = -28
	_header.offset_top = 16
	_header.offset_bottom = HEADER_H
	_header.add_theme_constant_override("separation", 16)
	add_child(_header)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", int((17 + FONT_ADD) * 1.2))
	t.add_theme_color_override("font_color", Color("#D46B60"))
	_header.add_child(t)

	var sub := Label.new()
	sub.text = chapter_text
	sub.add_theme_font_size_override("font_size", int((13 + FONT_ADD) * 1.2))
	sub.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.55))
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(sub)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(sp)

	var hp := Label.new()
	hp.text = "%s %d/%d" % [I18N.t("w.hp"), Run.hp, Run.max_hp]
	hp.add_theme_font_size_override("font_size", int((13 + FONT_ADD) * 1.2))
	hp.add_theme_color_override("font_color", Color("#C9A8B4"))
	hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(hp)

	var gold := Label.new()
	gold.text = "%s %d" % [I18N.t("w.gold"), Run.gold]
	gold.add_theme_font_size_override("font_size", int((13 + FONT_ADD) * 1.2))
	gold.add_theme_color_override("font_color", Color("#B08D3F"))
	gold.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(gold)

	for spec in [
		{"key": "ui.deck", "sig": open_deck},
		{"key": "ui.relics", "sig": open_relics},
		{"key": "ui.codex", "sig": open_codex},
	]:
		var b := Button.new()
		b.text = I18N.t(str(spec["key"]))
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(84, 36)
		b.add_theme_font_size_override("font_size", int((12 + FONT_ADD) * 1.2))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_style(b, Color(0.92, 0.90, 0.86, 0.06), Color(0.92, 0.90, 0.86, 0.22))
		var sig: Signal = spec["sig"]
		b.pressed.connect(func(): sig.emit())
		_header.add_child(b)

	# 节点按钮
	var rows: Array = map_data.get("rows", [])
	for row in rows:
		for n in row:
			var btn := _make_node(n)
			add_child(btn)
			_buttons[str(n["id"])] = btn

	_layout()


func _layout() -> void:
	if _buttons.is_empty():
		return
	var rows: Array = map_data.get("rows", [])
	var total: int = rows.size()
	if total == 0:
		return
	var w := size.x
	if w <= 1.0:
		w = 1024.0
	var h := size.y
	if h <= 1.0:
		h = 720.0

	var top := HEADER_H + 26.0
	var bottom := h - FOOTER_H - 24.0
	var step := (bottom - top) / float(max(1, total - 1))

	var max_cols := 2
	for row in rows:
		max_cols = maxi(max_cols, row.size())

	var span := minf(w - 190.0, float(max_cols - 1) * 168.0)

	for r in total:
		var row: Array = rows[r]
		var y := bottom - float(r) * step
		var count: int = row.size()
		for c in count:
			var n: Dictionary = row[c]
			var x := w * 0.5
			if count > 1:
				x = w * 0.5 + (float(c) - float(count - 1) * 0.5) * (span / float(maxi(1, count - 1)))
			var center := Vector2(x, y)
			_centers[str(n["id"])] = center
			var btn: Button = _buttons[str(n["id"])]
			btn.position = center - Vector2(NODE_R, NODE_R)
			btn.size = Vector2(NODE_R * 2.0, NODE_R * 2.0)
	queue_redraw()


func _make_node(n: Dictionary) -> Button:
	var id := str(n["id"])
	var type := str(n["type"])
	var b := Button.new()
	b.text = I18N.t("map.short." + type)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(NODE_R * 2.0, NODE_R * 2.0)
	b.size = Vector2(NODE_R * 2.0, NODE_R * 2.0)

	var visited := bool(n.get("visited", false)) or Run.done_nodes.has(id)
	var open := avail_ids.has(id)
	var is_cur := id == current_id

	var base: Color = TYPE_COLOR.get(type, Color("#44505A"))
	var bg := base
	var border := Color(0.92, 0.90, 0.86, 0.20)
	var width := 1

	if open:
		border = Color("#E3B07A")
		width = 2
		bg = base.lightened(0.16)
	elif is_cur:
		border = Color("#D46B60")
		width = 2
	elif visited:
		bg = base.darkened(0.35)

	_style(b, bg, border, width)
	b.add_theme_font_size_override("font_size", int((14 + FONT_ADD) * 1.2))
	b.add_theme_color_override("font_color",
		Color(0.96, 0.94, 0.90, 0.95) if open or is_cur else Color(0.92, 0.90, 0.86, 0.45))
	b.disabled = not open
	b.modulate.a = 1.0 if (open or is_cur) else (0.45 if not visited else 0.32)
	b.pressed.connect(func(): node_chosen.emit(id))

	if type == "elite" or type == "boss":
		b.add_theme_font_size_override("font_size", int((12 + FONT_ADD) * 1.2))
	return b


func _style(b: Button, bg: Color, border: Color, width: int = 1) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(int(NODE_R))
	var h := sb.duplicate() as StyleBoxFlat
	h.bg_color = bg.lightened(0.22)
	h.border_color = Color("#E3B07A")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("disabled", sb)


func _draw() -> void:
	var rows: Array = map_data.get("rows", [])
	if rows.is_empty():
		return
	var col_avail := Color(0.89, 0.69, 0.48, 0.55)
	var col_dim := Color(0.92, 0.90, 0.86, 0.10)

	for row in rows:
		for n in row:
			var a: Vector2 = _centers.get(str(n["id"]), Vector2.ZERO)
			if a == Vector2.ZERO:
				continue
			for nid in n.get("next", []):
				var bpt: Vector2 = _centers.get(str(nid), Vector2.ZERO)
				if bpt == Vector2.ZERO:
					continue
				var lit := str(n["id"]) == current_id and avail_ids.has(str(nid))
				draw_line(a, bpt, col_avail if lit else col_dim, 2.0 if lit else 1.0)

	# 起点标记
	var first: Array = rows[0]
	for n in first:
		var p: Vector2 = _centers.get(str(n["id"]), Vector2.ZERO)
		if p != Vector2.ZERO:
			draw_arc(p, NODE_R + 8.0, 0, TAU, 32, Color(0.70, 0.55, 0.25, 0.35), 1.0)
