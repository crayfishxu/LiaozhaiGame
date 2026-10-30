extends Node

## ==================================================================
## 本地存档（autoload：Save）
##
## 职责只有三件：把 Run 的快照序列化成 JSON、落盘/读盘、导入导出。
## 任何游戏规则都不在这里 —— 什么时候存由 Battle 决定。
##
## 存档点语义：只在「站在地图上」这种干净状态调用 mark()。
## 进节点前存一次（战斗中被打断 → 回来重打这个节点），
## 节点结算后再存一次。战斗中的临时状态（手牌、敌人血量）一律不存。
##
## 两种交换形式：
##   · 文件 user://saves/run.json   —— 本机自动存/读
##   · 口令 LZ1:<base64>            —— 复制粘贴，跨设备/跨安装
## ==================================================================

const SAVE_DIR := "user://saves"
const SAVE_PATH := "user://saves/run.json"
const TMP_PATH := "user://saves/run.json.tmp"
const EXPORT_DIR := "user://exports"

const APP_ID := "liaozhai"
const FORMAT_VERSION := 1
const CODE_PREFIX := "LZ1:"

## 最近一次失败的原因（给 UI 提示用，成功时清空）
var last_error: String = ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORT_DIR))


# ------------------------------------------------------------------
# 本机存档
# ------------------------------------------------------------------
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 把 Run 的当前状态写盘。返回是否成功。
func mark() -> bool:
	last_error = ""
	if not Run.active or str(Run.outcome) != "":
		return false
	var payload := {
		"app": APP_ID,
		"v": FORMAT_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"run": Run.snapshot(),
	}
	var text := JSON.stringify(payload)

	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		last_error = "open"
		return false
	f.store_string(text)
	f.close()

	# 先写临时文件再改名：写一半被杀，旧存档还在
	var from := ProjectSettings.globalize_path(TMP_PATH)
	var to := ProjectSettings.globalize_path(SAVE_PATH)
	if DirAccess.rename_absolute(from, to) != OK:
		last_error = "rename"
		return false
	return true


## 存档摘要，给「继续」按钮显示；没有存档返回空字典
func meta() -> Dictionary:
	var p := _read_file(SAVE_PATH)
	if p.is_empty():
		return {}
	var r: Dictionary = p["run"]
	return {
		"layer": int(r.get("layer", 0)) + 1,
		"hp": int(r.get("hp", 0)),
		"max_hp": int(r.get("max_hp", 0)),
		"deck": (r.get("deck", []) as Array).size(),
		"saved_at": int(p.get("saved_at", 0)),
	}


func load_into_run() -> bool:
	last_error = ""
	var p := _read_file(SAVE_PATH)
	if p.is_empty():
		return false
	return _accept(p)


func erase() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# ------------------------------------------------------------------
# 导入导出
# ------------------------------------------------------------------
## 导出成一段可粘贴的口令（base64，跨设备/跨语言都安全）
func export_code() -> String:
	if not Run.active or str(Run.outcome) != "":
		last_error = "none"
		return ""
	var payload := {
		"app": APP_ID,
		"v": FORMAT_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"run": Run.snapshot(),
	}
	return CODE_PREFIX + Marshalls.utf8_to_base64(JSON.stringify(payload))


## 接受两种输入：带前缀的口令，或直接粘贴的 JSON 全文
func import_code(code: String) -> bool:
	last_error = ""
	var s := code.strip_edges()
	if s.is_empty():
		last_error = "empty"
		return false
	var text := s
	if s.begins_with(CODE_PREFIX):
		var body := s.substr(CODE_PREFIX.length())
		# 先验字符集：base64_to_utf8 遇到非法字符会往控制台喷引擎错误
		if not _is_base64(body):
			last_error = "format"
			return false
		text = Marshalls.base64_to_utf8(body)
	elif not s.begins_with("{"):
		last_error = "format"
		return false
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		last_error = "parse"
		return false
	return _accept(json.data)


## 导出一份 .json 到 user://exports/，返回绝对路径（失败返回空串）
func export_file() -> String:
	last_error = ""
	if not Run.active or str(Run.outcome) != "":
		last_error = "none"
		return ""
	var payload := {
		"app": APP_ID,
		"v": FORMAT_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"run": Run.snapshot(),
	}
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "")
	var name := "liaozhai_run_L%d_%s.json" % [Run.layer + 1, stamp]
	var path := "%s/%s" % [EXPORT_DIR, name]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		last_error = "open"
		return ""
	f.store_string(JSON.stringify(payload, "  "))
	f.close()
	return ProjectSettings.globalize_path(path)


func import_file(path: String) -> bool:
	last_error = ""
	var p := _read_file(path)
	if p.is_empty():
		return false
	return _accept(p)


# ------------------------------------------------------------------
# 内部
# ------------------------------------------------------------------
## 读文件 + 校验，返回 {app, v, run, saved_at} 或空字典
func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		last_error = "missing"
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		last_error = "open"
		return {}
	var text := f.get_as_text()
	f.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		last_error = "parse"
		return {}
	var p: Dictionary = json.data
	if str(p.get("app", "")) != APP_ID:
		last_error = "app"
		return {}
	if int(p.get("v", 0)) != FORMAT_VERSION:
		last_error = "version"
		return {}
	if not (p.get("run") is Dictionary):
		last_error = "run"
		return {}
	return p


## 校验通过后写回 Run。文件与口令两条路都从这里过，所以校验放在这
func _accept(p: Dictionary) -> bool:
	if str(p.get("app", "")) != APP_ID:
		last_error = "app"
		return false
	if int(p.get("v", 0)) != FORMAT_VERSION:
		last_error = "version"
		return false
	if not (p.get("run") is Dictionary):
		last_error = "run"
		return false
	var cleaned := _sanitize(p["run"])
	if cleaned.is_empty():
		return false
	if not Run.restore(cleaned):
		last_error = "run"
		return false
	return true


func _is_base64(s: String) -> bool:
	if s.length() < 2:
		return false
	for i in s.length():
		var c := s.unicode_at(i)
		var ok := (c >= 65 and c <= 90) or (c >= 97 and c <= 122) \
			or (c >= 48 and c <= 57) or c == 43 or c == 47 or c == 61
		if not ok:
			return false
	return true


## 把一份外来存档洗一遍：丢掉不认识的卡、越界的血、坏掉的地图
func _sanitize(run: Dictionary) -> Dictionary:
	var out := run.duplicate(true)

	# 卡牌：不认识的直接丢，全丢光说明这不是本游戏的存档
	var deck: Array = out.get("deck", []) as Array
	var kept: Array = []
	for inst in deck:
		if not (inst is Dictionary):
			continue
		var key := str((inst as Dictionary).get("key", ""))
		var side := str((inst as Dictionary).get("side", "xian"))
		if key == "" or not CardDB.exists(key):
			continue
		kept.append({"key": key, "side": "ben" if side == "ben" else "xian"})
	if kept.is_empty():
		last_error = "deck"
		return {}
	out["deck"] = kept

	# 旧物：不认识的丢掉
	var relics_in: Array = out.get("relics", []) as Array
	var relics_out: Array = []
	for r in relics_in:
		if RelicDB.has(str(r)) and not relics_out.has(str(r)):
			relics_out.append(str(r))
	out["relics"] = relics_out

	# 地图：没有 rows 就直接判坏档
	var mp = out.get("map", {})
	if not (mp is Dictionary) or not ((mp as Dictionary).get("rows") is Array):
		last_error = "map"
		return {}
	if ((mp as Dictionary)["rows"] as Array).is_empty():
		last_error = "map"
		return {}
	out["layer"] = clampi(int(out.get("layer", 0)), 0, EnemyDB.LAYERS.size() - 1)
	out["max_hp"] = maxi(1, int(out.get("max_hp", 50)))
	out["hp"] = clampi(int(out.get("hp", 1)), 1, int(out["max_hp"]))
	out["gold"] = maxi(0, int(out.get("gold", 0)))
	out["outcome"] = ""
	out["diagnosis"] = ""
	return out
