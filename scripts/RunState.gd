extends Node

## ==================================================================
## 一局游戏的状态（autoload：Run）
##
## 负责：牌组、旧物、金币、魂火、当前层与地图、本局统计。
## 战斗内的临时状态（能量、护盾、手牌）仍然留在 Battle.gd，
## 战斗开始/结束时与本对象同步。
## ==================================================================

const START_HP := 50
const START_GOLD := 0

var active: bool = false
var seed: int = 0
var rng := RandomNumberGenerator.new()

var deck: Array = []          # [{key, side}]
var relics: Array = []        # ["A01", ...]
var gold: int = 0
var insight: int = 0
var hp: int = START_HP
var max_hp: int = START_HP

var layer: int = 0
var map: Dictionary = {}      # {"layer":int, "rows":[[node]]}
var node_id: String = ""      # 当前所在节点，"" 表示还没进第一行
var done_nodes: Array = []    # 已结算的节点 id
var deck_limit: int = 40
var free_play_next: bool = false

## 本局统计 —— 结算时的「确诊」读这六项
var rounds: int = 0
var played: int = 0
var skipped: int = 0
var self_damage: int = 0
var block_total: int = 0
var discards: int = 0
var max_hit: int = 0
var grudge_peak: int = 0
var battles: int = 0
var elites: int = 0
var bosses: int = 0
var outcome: String = ""      # win / lose
var diagnosis: String = ""    # 确诊标签 key


func new_run(s: int = 0) -> void:
	seed = s if s != 0 else int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	rng.seed = seed
	active = true
	deck = _starter_deck()
	relics.clear()
	gold = START_GOLD
	insight = 0
	hp = START_HP
	max_hp = START_HP
	layer = 0
	node_id = ""
	done_nodes.clear()
	deck_limit = 40
	free_play_next = false
	rounds = 0
	played = 0
	skipped = 0
	self_damage = 0
	block_total = 0
	discards = 0
	max_hit = 0
	grudge_peak = 0
	battles = 0
	elites = 0
	bosses = 0
	outcome = ""
	diagnosis = ""
	start_layer(0)


func _starter_deck() -> Array:
	var d: Array = []
	for i in 4:
		d.append({"key": "sushou", "side": "xian"})
	for i in 4:
		d.append({"key": "suyi", "side": "xian"})
	for i in 2:
		d.append({"key": "youyuan", "side": "xian"})
	d.append({"key": "yinlu", "side": "xian"})
	d.append({"key": "yi", "side": "xian"})
	return d


func start_layer(idx: int) -> void:
	layer = idx
	map = MapGen.generate(idx, rng)
	node_id = ""
	for n in all_nodes():
		n["visited"] = false


func rows() -> Array:
	return map.get("rows", [])


func all_nodes() -> Array:
	var out: Array = []
	for row in rows():
		for n in row:
			out.append(n)
	return out


func node_by_id(id: String) -> Dictionary:
	for n in all_nodes():
		if str(n["id"]) == id:
			return n
	return {}


## 当前可以进入的节点
func available() -> Array:
	if rows().is_empty():
		return []
	if node_id == "":
		return rows()[0]
	var cur := node_by_id(node_id)
	var out: Array = []
	for nid in cur.get("next", []):
		var n := node_by_id(str(nid))
		if not n.is_empty():
			out.append(n)
	return out


func is_available(id: String) -> bool:
	for n in available():
		if str(n["id"]) == id:
			return true
	return false


## 进入节点：记账并返回节点数据
func enter(id: String) -> Dictionary:
	var n := node_by_id(id)
	if n.is_empty():
		return {}
	n["visited"] = true
	node_id = id
	return n


func finish_node(id: String) -> void:
	if not done_nodes.has(id):
		done_nodes.append(id)


func add_card(key: String, side: String = "xian") -> bool:
	if deck.size() >= deck_limit:
		return false
	deck.append({"key": key, "side": side})
	return true


func remove_card(index: int) -> bool:
	if index < 0 or index >= deck.size():
		return false
	# 业障：无法被任何方式移除
	if str(CardDB.CARDS[deck[index]["key"]].get("curse", "")) == "unremovable":
		return false
	deck.remove_at(index)
	return true


func add_relic(id: String) -> void:
	if has_relic(id):
		return
	relics.append(id)
	if id == "B03":
		max_hp += 5
		hp += 5
	elif id == "E02":
		max_hp -= 15
		hp = mini(hp, max_hp)
	elif id == "E04":
		max_hp -= 25
		hp = mini(hp, max_hp)
	elif id == "C03":
		deck_limit += 5


func has_relic(id: String) -> bool:
	return relics.has(id)


func relic_count() -> int:
	return relics.size()


func heal(n: int) -> void:
	hp = mini(max_hp, hp + n)


func gain_gold(n: int) -> void:
	gold = max(0, gold + n)


func spend(n: int) -> bool:
	if gold < n:
		return false
	gold -= n
	return true


# ------------------------------------------------------------------
# 存档：只导出 JSON 原生类型，不含随机数状态与本局的临时物件
# ------------------------------------------------------------------
## 会被写进存档的字段。往 Run 里加新字段时记得同步这里，
## 否则读档后那个字段会悄悄回到默认值。
const SAVE_FIELDS := [
	"seed", "deck", "relics", "gold", "insight", "hp", "max_hp",
	"layer", "map", "node_id", "done_nodes", "deck_limit", "free_play_next",
	"rounds", "played", "skipped", "self_damage", "block_total",
	"discards", "max_hit", "grudge_peak", "battles", "elites", "bosses",
	"outcome", "diagnosis",
]


## 当前局面的快照（纯数据，可直接 JSON 序列化）
func snapshot() -> Dictionary:
	var out: Dictionary = {}
	for f in SAVE_FIELDS:
		out[f] = get(f)
	# 深拷贝，避免存档对象和运行时对象共享引用
	return out.duplicate(true)


## 从快照恢复。缺字段取默认值，坏字段跳过 —— 读档宁可少一点也不要整个失败
func restore(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	for f in SAVE_FIELDS:
		if not d.has(f):
			continue
		var v: Variant = d[f]
		# 数组/字典要深拷贝，否则存档对象和运行时对象会共享同一份引用
		if v is Array:
			set(f, (v as Array).duplicate(true))
		elif v is Dictionary:
			set(f, (v as Dictionary).duplicate(true))
		else:
			set(f, v)

	# JSON 里的数字一律是 float，整型字段在这里收一次
	hp = int(hp)
	max_hp = maxi(1, int(max_hp))
	gold = maxi(0, int(gold))
	insight = int(insight)
	layer = clampi(int(layer), 0, EnemyDB.LAYERS.size() - 1)
	deck_limit = maxi(1, int(deck_limit))
	seed = int(seed)
	rounds = int(rounds)
	played = int(played)
	skipped = int(skipped)
	self_damage = int(self_damage)
	block_total = int(block_total)
	discards = int(discards)
	max_hit = int(max_hit)
	grudge_peak = int(grudge_peak)
	battles = int(battles)
	elites = int(elites)
	bosses = int(bosses)
	hp = clampi(hp, 1, max_hp)
	outcome = str(outcome)
	diagnosis = str(diagnosis)
	node_id = str(node_id)
	if not (map is Dictionary) or not (map.get("rows") is Array):
		return false

	active = true
	# 随机数不复原：读档后不要求和原来逐帧一致，randomize 更省心
	rng.randomize()
	return true


# ------------------------------------------------------------------
# 确诊
# ------------------------------------------------------------------
func evaluate_diagnosis() -> String:
	var win := outcome == "win"
	if rounds <= 2 and not win:
		return "d_nobody"
	if skipped >= int(ceil(float(rounds) * 0.3)):
		return "d_slacker"
	if rounds > 0 and float(played) / float(rounds) >= 3.5 and self_damage >= 10:
		return "d_rusher"
	if block_total >= 100:
		return "d_turtle"
	if discards >= 15:
		return "d_slippery"
	if rounds >= 25:
		return "d_burnout"
	if win and hp <= 10:
		return "d_stubborn"
	if win and max_hit <= 8:
		return "d_stable"
	return "d_nobody"


## 结算分享文本（复制到剪贴板 / 商店截图同款）
func share_text() -> String:
	var tag := I18N.t("diag." + diagnosis) if diagnosis != "" else I18N.t("diag.d_nobody")
	var head := I18N.t("share.head", [tag])
	var line := I18N.t("share.stats", [rounds, played, self_damage, grudge_peak])
	var note := I18N.t("diag.%s.c" % (diagnosis if diagnosis != "" else "d_nobody"))
	return "%s\n%s\n%s\n\n%s" % [head, line, note, I18N.t("share.tag")]
