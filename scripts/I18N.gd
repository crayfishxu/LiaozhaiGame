class_name I18N
extends RefCounted

## ==================================================================
## 多语言
##
## 覆盖 Google Play 下载量前 10 的语言（英/日/韩/德/法/葡/俄/西/意/印尼），
## 外加简体中文作为源语言。
##
## 用法：
##   I18N.t("ui.end_turn")                → 取当前语言的文案
##   I18N.t("ui.toast_no_energy", [3])    → 带 %d / %s 占位
##   I18N.set_lang("ja")                  → 切换（内部会存盘）
##
## 词条缺失时回退顺序：当前语言 → 英文 → 返回 key 本身，
## 所以漏翻一条不会崩，只会露出 key，便于排查。
## ==================================================================

const CFG_PATH := "user://settings.cfg"
const CFG_SECTION := "i18n"
const CFG_KEY := "language"

## 语种清单：code 与 Godot 的 locale 命名一致，name 用该语言的母语写法
const LANGS := [
	{"code": "zh_CN", "name": "简体中文"},
	{"code": "en", "name": "English"},
	{"code": "ja", "name": "日本語"},
	{"code": "ko", "name": "한국어"},
	{"code": "es", "name": "Español"},
	{"code": "pt_BR", "name": "Português (Brasil)"},
	{"code": "ru", "name": "Русский"},
	{"code": "de", "name": "Deutsch"},
	{"code": "fr", "name": "Français"},
	{"code": "it", "name": "Italiano"},
	{"code": "id", "name": "Bahasa Indonesia"},
]

const ZH := preload("res://scripts/i18n/zh_CN.gd")
const EN := preload("res://scripts/i18n/en.gd")
const JA := preload("res://scripts/i18n/ja.gd")
const KO := preload("res://scripts/i18n/ko.gd")
const ES := preload("res://scripts/i18n/es.gd")
const PT := preload("res://scripts/i18n/pt_BR.gd")
const RU := preload("res://scripts/i18n/ru.gd")
const DE := preload("res://scripts/i18n/de.gd")
const FR := preload("res://scripts/i18n/fr.gd")
const IT := preload("res://scripts/i18n/it.gd")
const ID := preload("res://scripts/i18n/id.gd")

const TABLES := {
	"zh_CN": ZH.TEXT,
	"en": EN.TEXT,
	"ja": JA.TEXT,
	"ko": KO.TEXT,
	"es": ES.TEXT,
	"pt_BR": PT.TEXT,
	"ru": RU.TEXT,
	"de": DE.TEXT,
	"fr": FR.TEXT,
	"it": IT.TEXT,
	"id": ID.TEXT,
}

static var code: String = "zh_CN"


# ------------------------------------------------------------------
# 取词
# ------------------------------------------------------------------
static func t(key: String, args: Array = []) -> String:
	var s := _raw(key)
	if args.is_empty():
		return s
	return s % args


static func _raw(key: String) -> String:
	var table: Dictionary = TABLES.get(code, EN.TEXT)
	if table.has(key):
		return str(table[key])
	# 回退英文
	if EN.TEXT.has(key):
		return str(EN.TEXT[key])
	return key


## 是否已翻译（供调试用：列出某语言缺哪些条目）
static func missing(lang: String) -> Array:
	var table: Dictionary = TABLES.get(lang, {})
	var out: Array = []
	for k in ZH.TEXT.keys():
		if not table.has(k):
			out.append(k)
	return out


# ------------------------------------------------------------------
# 领域取词
# ------------------------------------------------------------------
static func card_name(key: String) -> String:
	return _raw("c." + key)


static func card_text(key: String, side: String) -> String:
	return _raw("c.%s.%s" % [key, "x" if side == "xian" else "b"])


static func type_name(type_key: String) -> String:
	return _raw("t." + type_key)


static func enemy_name(key: String) -> String:
	return _raw("e." + key)


## 意图条文案：动词 + 数值
##   攻击   "噬 5"
##   多段   "鞭 4×2"
##   施毒   "缠 毒 2"（用 w.poison 这个词，避免每种语言再写一遍）
static func intent_text(move: Dictionary) -> String:
	var verb := _raw(str(move.get("verb", "")))
	var kind := str(move.get("kind", "attack"))
	var val := int(move.get("val", 0))
	var hits := int(move.get("hits", 1))
	if kind == "debuff":
		return "%s %s %d" % [verb, _raw("w.poison"), val]
	if hits > 1:
		return "%s %d×%d" % [verb, val, hits]
	return "%s %d" % [verb, val]


# ------------------------------------------------------------------
# 语言切换 / 持久化
# ------------------------------------------------------------------
static func has_lang(c: String) -> bool:
	for l in LANGS:
		if str(l["code"]) == c:
			return true
	return false


static func lang_name(c: String) -> String:
	for l in LANGS:
		if str(l["code"]) == c:
			return str(l["name"])
	return c


## 按系统语言挑一个最接近的；识别不了就回退英文
static func detect() -> String:
	var loc := OS.get_locale()
	if has_lang(loc):
		return loc
	var base := loc.split("_")[0]
	for l in LANGS:
		if str(l["code"]).split("_")[0] == base:
			return str(l["code"])
	return "en"


static func set_lang(c: String) -> void:
	if not has_lang(c):
		return
	code = c
	TranslationServer.set_locale(c)
	save()


static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		var saved := str(cfg.get_value(CFG_SECTION, CFG_KEY, ""))
		if saved != "" and has_lang(saved):
			code = saved
			TranslationServer.set_locale(code)
			return
	code = detect()
	TranslationServer.set_locale(code)


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(CFG_SECTION, CFG_KEY, code)
	cfg.save(CFG_PATH)


# ------------------------------------------------------------------
# 字体：系统字体回退链
## 中/日/韩 需要 CJK 字形，拉丁与西里尔由无衬线字体覆盖。
## Android 上 "sans-serif" 走 Roboto，缺 CJK 时由系统回退链补上。
# ------------------------------------------------------------------
static func font_names() -> PackedStringArray:
	return PackedStringArray([
		"PingFang SC", "Hiragino Sans GB", "Heiti SC",
		"Microsoft YaHei UI", "Microsoft YaHei",
		"Noto Sans CJK SC", "Noto Sans CJK JP", "Noto Sans CJK KR",
		"Source Han Sans SC", "Source Han Sans",
		"Noto Sans", "Noto Sans Hebrew", "DejaVu Sans",
		"WenQuanYi Micro Hei", "SimHei", "sans-serif",
	])
