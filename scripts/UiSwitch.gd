extends Control

## ==================================================================
## 开关控件（胶囊轨道 + 圆形滑块）
##
##   var sw := UiSwitch.new()
##   sw.set_on(true, false)          # 初始状态（不播动画）
##   sw.toggled.connect(func(on): ...)
##
## 只处理鼠标事件：Godot 默认开启 emulate_mouse_from_touch，
## 触摸会被转成鼠标，重复处理会一次点击切两下。
## ==================================================================

signal toggled(on: bool)

const TRACK_H := 34.0     # 轨道高度（逻辑像素）
const PAD := 4.0          # 滑块与轨道的间隙
const ANIM := 0.14

var on: bool = false

var _knob: float = 0.0    # 0 = 左（关），1 = 右（开）
var _sb_on: StyleBoxFlat
var _sb_off: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = Vector2(78, 42)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_sb_on = StyleBoxFlat.new()
	_sb_on.bg_color = Color(0.70, 0.23, 0.19, 0.90)
	_sb_on.border_color = Color(0.88, 0.58, 0.50, 0.80)
	_sb_on.set_border_width_all(1)
	_sb_on.set_corner_radius_all(int(TRACK_H * 0.5))

	_sb_off = StyleBoxFlat.new()
	_sb_off.bg_color = Color(0.13, 0.16, 0.18, 1.0)
	_sb_off.border_color = Color(0.92, 0.90, 0.86, 0.20)
	_sb_off.set_border_width_all(1)
	_sb_off.set_corner_radius_all(int(TRACK_H * 0.5))

	_set_knob(1.0 if on else 0.0)


## 外部设置状态。animate=false 用于按真实状态重建 UI 时，避免每一帧都滑一遍。
func set_on(v: bool, animate: bool = true) -> void:
	on = v
	var target := 1.0 if v else 0.0
	if animate and is_inside_tree():
		var tw := create_tween()
		tw.tween_method(_set_knob, _knob, target, ANIM)
	else:
		_set_knob(target)


func _set_knob(t: float) -> void:
	_knob = clampf(t, 0.0, 1.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			accept_event()
			set_on(not on)
			toggled.emit(on)


func _draw() -> void:
	var y := (size.y - TRACK_H) * 0.5
	var track := Rect2(Vector2(0.0, y), Vector2(size.x, TRACK_H))
	draw_style_box(_sb_on if on else _sb_off, track)

	var radius := TRACK_H * 0.5 - PAD
	var travel := size.x - radius * 2.0 - PAD * 2.0
	var center := Vector2(track.position.x + PAD + radius + travel * _knob, track.position.y + TRACK_H * 0.5)

	# 落地阴影：滑块不贴轨道，看起来有厚度
	draw_circle(center + Vector2(0.0, 1.5), radius, Color(0.0, 0.0, 0.0, 0.30))
	draw_circle(center, radius, Color(0.96, 0.95, 0.92) if on else Color(0.56, 0.58, 0.59))
