class_name EventDB
extends RefCounted

## ------------------------------------------------------------------
## 事件节点（6 个）
##
## 文案：ev.{id}.t 标题 / ev.{id}.b 正文 / ev.{id}.o{n} 选项
## 效果：由 Battle._apply_effect 执行
##   heal / max_hp / gold / damage / insight
##   relic   抽一个旧物（来源字符串，见 RelicDB.DROP）
##   card    获得 N 张随机情念
##   curse   往牌组塞一张祟
##   battle  打一场（敌人 key，可选 scale 放大血量）
##   gamble  {"cost": 押注, "win": 赢多少}
## ------------------------------------------------------------------

const EVENTS := {
	"snow": {
		"options": [
			{"fx": {"max_hp": 5}},
			{"fx": {"battle": "youhun", "scale": 1.3}},
			{"fx": {"curse": "jiangbanya"}},
		],
	},
	"temple": {
		"options": [
			{"fx": {"heal": 12}},
			{"fx": {"relic": "treasure", "damage": 6}},
			{"fx": {}},
		],
	},
	"drowned": {
		"options": [
			{"fx": {"damage": 8, "max_hp": 8}},
			{"fx": {"card": 1}},
			{"fx": {}},
		],
	},
	"gamble": {
		"options": [
			{"fx": {"gamble": {"cost": 30, "win": 60}}},
			{"fx": {"gold": 70, "curse": "xinmo"}},
			{"fx": {}},
		],
	},
	"wedding": {
		"options": [
			{"fx": {"gold": 30, "curse": "xiesui"}},
			{"fx": {"battle": "zhiren", "scale": 1.3}},
			{"fx": {}},
		],
	},
	"well": {
		"options": [
			{"fx": {"heal": 10}},
			{"fx": {"damage": 8, "relic": "treasure"}},
			{"fx": {"gold": -10, "max_hp": 3}},
		],
	},
}


static func ids() -> Array:
	return EVENTS.keys()


static func get_event(id: String) -> Dictionary:
	return EVENTS.get(id, {})


static func title(id: String) -> String:
	return I18N.t("ev.%s.t" % id)


static func body(id: String) -> String:
	return I18N.t("ev.%s.b" % id)


static func option_text(id: String, index: int) -> String:
	return I18N.t("ev.%s.o%d" % [id, index + 1])


## 选项下方的小字提示（让玩家知道自己在选什么）
static func option_hint(id: String, index: int) -> String:
	return I18N.t("ev.%s.h%d" % [id, index + 1])
