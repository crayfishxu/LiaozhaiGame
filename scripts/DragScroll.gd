class_name DragScroll
extends ScrollContainer

## ------------------------------------------------------------------
## 可以用手指拖动的滚动容器
##
## 为什么不用引擎自带的行为：
##   ScrollContainer 的拖拽要在事件真的送到它身上时才生效，而格子里的
##   CardView 是 MOUSE_FILTER_STOP，手指按在卡上时事件被卡吃掉，容器一次
##   都收不到。所以列表里的卡牌改成 MOUSE_FILTER_PASS（事件继续冒泡到这一
##   层），这里自己处理拖拽。
##
## 触摸与鼠标两条路都吃，但必须仲裁，否则一次拖拽会被算两遍：
##   Android 上 emulate_mouse_from_touch 默认开着，一根手指会同时产生
##   ScreenTouch/ScreenDrag 与 MouseButton/MouseMotion，谁先到不保证。
##   所以只要有手指按着，就把鼠标那一套整体忽略。
##
## 手指按下不立刻算拖动，越过 DEADZONE 才开始，避免点按被当成 1px 的滚动；
## 卡牌那边同样用位移阈值判断「这是点按还是拖动」，两边配合才不会误触。
## 抬手时按松手速度做一段惯性滑行，才有手机该有的手感。
## ------------------------------------------------------------------

## 超过这个像素才算拖动。要比卡牌 / 按钮那边的点按阈值（12）大一点，
## 否则 12~14 这一小段会「既滚了一下又当成点击」
const DEADZONE := 14.0
## 松手速度超过这个值才滑行（像素/秒）
const FLING_MIN := 260.0
## 每秒衰减到原来的多少（越小停得越快）
const FLING_DAMP := 0.0022
## 低于这个速度就停
const FLING_STOP := 28.0

var _pressed := false
var _dragging := false
var _by_touch := false
## 有手指正按在屏幕上（含没开始拖的那段）
var _touch_down := false
var _start := Vector2.ZERO
var _last := Vector2.ZERO

## 惯性滑行的当前速度（像素/秒，屏幕方向）
var _fling := Vector2.ZERO


func _ready() -> void:
	set_process(false)
	# 手机上滚动条只是「还能往下翻」的提示，太细看不见，稍微加宽一点
	var vb := get_v_scroll_bar()
	if vb != null:
		vb.custom_minimum_size.x = 12
	var hb := get_h_scroll_bar()
	if hb != null:
		hb.custom_minimum_size.y = 12


func _process(delta: float) -> void:
	if _fling == Vector2.ZERO:
		set_process(false)
		return
	_scroll_by(_fling * delta)
	_fling *= pow(FLING_DAMP, delta)
	if _fling.length() < FLING_STOP or _at_edge():
		_fling = Vector2.ZERO
		set_process(false)


func _at_edge() -> bool:
	var vb := get_v_scroll_bar()
	if absf(_fling.y) > 0.0 and vb.max_value > vb.page:
		if (_fling.y > 0.0 and scroll_vertical <= 0) \
				or (_fling.y < 0.0 and scroll_vertical >= vb.max_value - vb.page):
			return true
	return false


func _gui_input(event: InputEvent) -> void:
	# ---- 触摸 ----
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_down = true
			_begin(true, t.position)
		else:
			_touch_down = false
			_end()
		return

	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if _pressed and _by_touch:
			_move(d.position)
		return

	# ---- 鼠标（桌面；Android 上由触摸模拟出来的那一路要跳过）----
	if _touch_down:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_begin(false, mb.position)
		else:
			_end()
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		# 抬起发生在容器外面时收不到抬起事件，靠「键已经松了」补一刀
		if _pressed and not _by_touch and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_end()
			return
		if _pressed and not _by_touch and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_move(mm.position)
		return


func _begin(by_touch: bool, pos: Vector2) -> void:
	_fling = Vector2.ZERO
	_pressed = true
	_dragging = false
	_by_touch = by_touch
	_start = pos
	_last = pos


func _end() -> void:
	var was_dragging := _dragging
	_pressed = false
	_dragging = false
	# 抬手时还带着速度就滑一段。只看最后这一小段的方向，别用整段平均
	if was_dragging and _fling.length() >= FLING_MIN:
		set_process(true)
	else:
		_fling = Vector2.ZERO


func _move(pos: Vector2) -> void:
	var delta := pos - _last
	_last = pos

	if not _dragging:
		if (pos - _start).length() < DEADZONE:
			return
		# 刚越过阈值的那一下不位移，否则起手会跳一截
		_dragging = true
		delta = Vector2.ZERO

	if delta == Vector2.ZERO:
		return

	_scroll_by(delta)
	# 手指往左上拖 → 内容跟着往上走，松手后继续往同方向滑，速度与位移同向
	var inst := delta / maxf(get_process_delta_time(), 0.001)
	_fling = _fling.lerp(inst, 0.45)
	accept_event()


func _scroll_by(delta: Vector2) -> void:
	var vb := get_v_scroll_bar()
	if vb.max_value > vb.page:
		scroll_vertical = int(clampf(scroll_vertical - delta.y, 0.0, vb.max_value - vb.page))

	var hb := get_h_scroll_bar()
	if hb.max_value > hb.page:
		scroll_horizontal = int(clampf(scroll_horizontal - delta.x, 0.0, hb.max_value - hb.page))
