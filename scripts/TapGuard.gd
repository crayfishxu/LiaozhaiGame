class_name TapGuard
extends RefCounted

## ------------------------------------------------------------------
## 滚动列表里的按钮：区分「点一下」和「拖着列表滑」
##
## Button 自己不管位移，手指压着它滑 20 像素再松手照样算一次点击 ——
## 列表一旦能拖动，买东西、删牌这种操作就会误触。所以在按钮自己的
## gui_input 上记一笔，pressed 回调里先问一句。
##
## 用法：
##   var g := TapGuard.attach(btn)
##   btn.pressed.connect(func(): if g.ok(): _buy())
## ------------------------------------------------------------------

## 位移超过这个值就算「在拖」
const SLOP := 12.0

var _pos := Vector2.ZERO
var _moved := false


static func attach(c: Control) -> TapGuard:
	var g := TapGuard.new()
	c.gui_input.connect(g._on_input)
	return g


## 只看不取（给点击音效用：拖拽松手时不该响）
func peek_ok() -> bool:
	return not _moved


## 这次点击是不是真的点击（读过一次就复位）
func ok() -> bool:
	var moved := _moved
	_moved = false
	return not moved


func _on_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var t := e as InputEventScreenTouch
		if t.pressed:
			_begin(t.position)
	elif e is InputEventScreenDrag:
		_track((e as InputEventScreenDrag).position)
	elif e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_begin(mb.position)
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_track(mm.position)


func _begin(p: Vector2) -> void:
	_pos = p
	_moved = false


func _track(p: Vector2) -> void:
	if p.distance_to(_pos) > SLOP:
		_moved = true
