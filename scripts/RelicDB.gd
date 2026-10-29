class_name RelicDB
extends RefCounted

## ------------------------------------------------------------------
## 旧物数据表（40 件）
##
## 名字与描述走 I18N：r.{id} / r.{id}.d
## 效果实现在 RelicEngine —— 这里只放静态数据与抽取规则。
##
## rarity  common / rare / epic / legendary
## cat     A 战斗增益 / B 经济资源 / C 构筑操作 / D 状态触发 / E 风险诅咒
## cursed  诅咒旧物，只能从宝箱与事件获得
## ------------------------------------------------------------------

const RELICS := {
	# ===== A 战斗增益 =====
	"A01": {"rarity": "common", "cat": "A", "p": {"grudge": 1}},
	"A02": {"rarity": "common", "cat": "A", "p": {"dmg_add": 1}},
	"A03": {"rarity": "common", "cat": "A", "p": {}},
	"A04": {"rarity": "common", "cat": "A", "p": {"block": 4}},
	"A05": {"rarity": "common", "cat": "A", "p": {"block": 1}},
	"A06": {"rarity": "common", "cat": "A", "p": {"block": 2}},
	"A07": {"rarity": "rare", "cat": "A", "p": {"dmg_add": 3}},
	"A08": {"rarity": "rare", "cat": "A", "p": {"pct": 0.25}},
	"A09": {"rarity": "rare", "cat": "A", "p": {"dmg_per_poison": 1}},
	"A10": {"rarity": "rare", "cat": "A", "p": {"threshold": 20, "draw": 2}},
	"A11": {"rarity": "epic", "cat": "A", "p": {"aoe": 2}},
	"A12": {"rarity": "legendary", "cat": "A", "p": {"heal": 3}},

	# ===== B 经济资源 =====
	"B01": {"rarity": "common", "cat": "B", "p": {"gold": 5}},
	"B02": {"rarity": "common", "cat": "B", "p": {"heal": 2}},
	"B03": {"rarity": "common", "cat": "B", "p": {"max_hp": 5}},
	"B04": {"rarity": "common", "cat": "B", "p": {"shop": 0.10}},
	"B05": {"rarity": "rare", "cat": "B", "p": {"card": 1}},
	"B06": {"rarity": "rare", "cat": "B", "p": {"elite_gold": 2.0}},
	"B07": {"rarity": "rare", "cat": "B", "p": {"insight": 3}},
	"B08": {"rarity": "epic", "cat": "B", "p": {"gold": 12}},

	# ===== C 构筑操作 =====
	"C01": {"rarity": "common", "cat": "C", "p": {"draw_first": 1}},
	"C02": {"rarity": "common", "cat": "C", "p": {"reward": 1}},
	"C03": {"rarity": "common", "cat": "C", "p": {"deck": 5}},
	"C04": {"rarity": "rare", "cat": "C", "p": {"remove": 1}},
	"C05": {"rarity": "rare", "cat": "C", "p": {}},
	"C06": {"rarity": "rare", "cat": "C", "p": {}},
	"C07": {"rarity": "epic", "cat": "C", "p": {}},
	"C08": {"rarity": "epic", "cat": "C", "p": {"pct": 0.15}},

	# ===== D 状态触发 =====
	"D01": {"rarity": "common", "cat": "D", "p": {"poison_half": true}},
	"D02": {"rarity": "common", "cat": "D", "p": {"reduce": 3}},
	"D03": {"rarity": "common", "cat": "D", "p": {"bind": 1}},
	"D04": {"rarity": "rare", "cat": "D", "p": {"pct": 0.20}},
	"D05": {"rarity": "rare", "cat": "D", "p": {"block": 3, "threshold": 0.3}},
	"D06": {"rarity": "rare", "cat": "D", "p": {}},
	"D07": {"rarity": "epic", "cat": "D", "p": {}},

	# ===== E 风险诅咒 =====
	"E01": {"rarity": "rare", "cat": "E", "cursed": true, "p": {"pct": 0.50, "hp": 2}},
	"E02": {"rarity": "epic", "cat": "E", "cursed": true, "p": {"energy": 1, "max_hp": -15}},
	"E03": {"rarity": "epic", "cat": "E", "cursed": true, "p": {"energy_start": 3}},
	"E04": {"rarity": "legendary", "cat": "E", "cursed": true, "p": {"cost": -1, "max_hp": -25}},
	"E05": {"rarity": "legendary", "cat": "E", "cursed": true, "p": {"draw": 2, "hand": 2, "hp": 1}},
}

const ORDER := [
	"A01", "A02", "A03", "A04", "A05", "A06", "A07", "A08", "A09", "A10", "A11", "A12",
	"B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08",
	"C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08",
	"D01", "D02", "D03", "D04", "D05", "D06", "D07",
	"E01", "E02", "E03", "E04", "E05",
]

## 抽取权重：普通/稀有/史诗/传说
const DROP := {
	"elite": {"common": 40, "rare": 45, "epic": 15, "legendary": 0},
	"boss": {"common": 0, "rare": 50, "epic": 40, "legendary": 10},
	"treasure": {"common": 55, "rare": 30, "epic": 12, "legendary": 3},
	"shop": {"common": 50, "rare": 32, "epic": 14, "legendary": 4},
}

const PRICE := {"common": 90, "rare": 140, "epic": 210, "legendary": 300}


static func has(id: String) -> bool:
	return RELICS.has(id)


static func rarity_of(id: String) -> String:
	return str(RELICS[id].get("rarity", "common"))


static func is_cursed(id: String) -> bool:
	return bool(RELICS[id].get("cursed", false))


static func name(id: String) -> String:
	return I18N.t("r." + id)


static func desc(id: String) -> String:
	return I18N.t("r.%s.d" % id)


## 按来源抽 n 个不重复、且未持有的旧物
static func roll(rng: RandomNumberGenerator, source: String, n: int, owned: Array, cursed: bool = false) -> Array:
	var weights: Dictionary = DROP.get(source, DROP["treasure"])
	var total := 0
	for v in weights.values():
		total += int(v)
	if total <= 0:
		return []

	var out: Array = []
	var guard := 0
	while out.size() < n and guard < 300:
		guard += 1
		var roll_v := rng.randi_range(1, max(1, total))
		var want := "common"
		for r in ["common", "rare", "epic", "legendary"]:
			roll_v -= int(weights.get(r, 0))
			if roll_v <= 0:
				want = r
				break
		var bucket: Array = []
		for id in ORDER:
			if owned.has(id) or out.has(id):
				continue
			if is_cursed(id) != cursed:
				continue
			if rarity_of(id) == want:
				bucket.append(id)
		if bucket.is_empty():
			continue
		out.append(str(bucket[rng.randi() % bucket.size()]))
	return out
