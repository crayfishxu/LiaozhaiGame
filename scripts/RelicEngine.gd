class_name RelicEngine
extends RefCounted

## ==================================================================
## 旧物引擎（40 件）
##
## 战斗里只调用这里的钩子与修正函数，不允许写 `if has_relic("A01")`。
## 每件旧物的逻辑都集中在 _on_id() 与各修正函数里。
##
## 战斗内的一次性状态放在 flags，每场战斗重置。
## ==================================================================

var ids: Array = []
var b: Node = null
var flags: Dictionary = {}


func setup(relic_ids: Array, battle: Node) -> void:
	ids = relic_ids.duplicate()
	b = battle
	reset_battle()


func reset_battle() -> void:
	flags.clear()


func has(id: String) -> bool:
	return ids.has(id)


func owned() -> Array:
	return ids


# ==================================================================
# 钩子
# ==================================================================
func on_battle_start() -> void:
	flags["first_ben_free"] = has("A03")
	flags["wrist_used"] = false
	flags["reverse_scale_used"] = false
	flags["bell_used"] = false

	if has("A04"):
		b.player_block += 4
		b._float_at(b._player_anchor(), "+4", b.C_BLOCK)

	if has("E03"):
		b.energy += 3
		b._float_at(b._player_anchor(), "+3", b.C_GOLD)


## 第一回合额外抽牌（旧书）
func first_turn_draw() -> int:
	return 1 if has("C01") else 0


## 起手复制第一张牌（影拓）
func on_first_hand_ready() -> void:
	if has("C05") and b.hand.size() > 0:
		var inst: Dictionary = b.hand[0]
		b.hand.append({"key": str(inst["key"]), "side": str(inst["side"]), "temp": true})
		b._float_at(b._player_anchor(), "＋1", b.C_GOLD)


func on_turn_start() -> void:
	flags.erase("a12_turn")
	if has("E01"):
		b.player_hp -= 2
		b._float_at(b._player_anchor(), "-2", b.C_ROUGE)
	if has("E05"):
		b.player_hp -= 1
		b._float_at(b._player_anchor(), "-1", b.C_ROUGE)

	if has("A11"):
		for e in b.enemies:
			if bool(e["dead"]):
				continue
			b._hit_enemy(e, 2)
			b._float_at(b._enemy_anchor(e), "-2", b.C_ROUGE)

	if has("D05") and b.player_hp * 10 < b.player_max_hp * 3:
		b.player_block += 3
		b._float_at(b._player_anchor(), "+3", b.C_BLOCK)


## 回合结束、弃手牌之前
func on_turn_end() -> void:
	if has("A09"):
		for e in b.enemies:
			if bool(e["dead"]):
				continue
			var stacks := int(e["poison"])
			if stacks > 0:
				b._hit_enemy(e, stacks)
				b._float_at(b._enemy_anchor(e), "-%d" % stacks, b.C_MOSS)


func on_card_played(card_key: String, def: Dictionary, side: String, first_this_turn: bool) -> void:
	if first_this_turn and has("A05"):
		b.player_block += 1
		b._float_at(b._player_anchor(), "+1", b.C_BLOCK)

	if side == "ben":
		if flags.get("first_ben_free", false):
			flags["first_ben_free"] = false
		if has("A12") and not flags.has("a12_turn"):
			flags["a12_turn"] = true
			b.player_hp = mini(b.player_max_hp, b.player_hp + 3)
			b._float_at(b._player_anchor(), "+3", b.C_MOSS)

	if first_this_turn and side == "xian" and has("D06"):
		# 复制本相一张加入手牌，且该副本为消耗牌
		b.hand.append({"key": card_key, "side": "ben", "temp": true})
		b._float_at(b._player_anchor(), "＋本相", b.C_LOTUS)


func on_hurt(dmg_taken: int) -> void:
	if dmg_taken <= 0:
		return
	if has("A01"):
		b.grudge += 1


func on_grudge_changed() -> void:
	if has("A10") and not flags.get("bell_used", false) and b.grudge >= 20:
		flags["bell_used"] = true
		b._draw_cards(2)
		b._toast(I18N.t("relic.A10.trigger"), b.C_GOLD)


## 战斗结束结算：返回额外金币 / 回复 / 额外卡
func on_battle_end(kind: String) -> Dictionary:
	var gold := 0
	var heal := 0
	var cards := 0
	if has("B01"):
		gold += 5
	if has("B08"):
		gold += 12
	if has("B06") and kind == "elite":
		gold *= 2
	if has("B02"):
		heal += 2
	if has("B05"):
		cards += 1
	return {"gold": gold, "heal": heal, "cards": cards, "insight": 3 if has("B07") else 0}


## 玩家受到致命伤时的兜底（逆鳞）
func try_survive() -> bool:
	if has("D07") and not flags.get("reverse_scale_used", false):
		flags["reverse_scale_used"] = true
		return true
	return false


# ==================================================================
# 修正
# ==================================================================
## 伤害修正：固定加值 → 百分比（加法叠加）→ 1.5 倍上限
func mod_damage(raw: int, def: Dictionary, side: String, target: Dictionary) -> int:
	var flat := 0
	if has("A02") and str(def.get("type", "")) == "attack":
		flat += 1
	if has("A07") and side == "ben":
		flat += 3

	var pct := 0.0
	if has("C08"):
		pct += 0.15
	if has("A08") and b.player_hp * 2 < b.player_max_hp and str(def.get("type", "")) == "attack":
		pct += 0.25
	if has("E01") and str(def.get("type", "")) == "attack":
		pct += 0.50
	if has("D04") and not target.is_empty() and int(target.get("bind", 0)) > 0:
		pct += 0.20

	var out := float(raw + flat) * (1.0 + pct)
	out = minf(out, float(raw + flat) * 2.5)
	return int(floor(out))


func mod_block(raw: int, side: String) -> int:
	var add := 0
	if has("A06") and side == "xian":
		add += 2
	var out := float(raw + add)
	if has("C08"):
		out *= 1.15
	return int(floor(out))


## 卡牌实际费用（铜镜 / 逆命 / 心魔）
func cost_of(base: int, side: String, surcharge: int = 0) -> int:
	var c := base
	if has("E04"):
		c -= 1
	if side == "ben" and flags.get("first_ben_free", false):
		c = 0
	if surcharge > 0:
		c += surcharge
	return max(0, c)


func draw_per_turn() -> int:
	var n := 5
	if has("E05"):
		n += 2
	return n


func hand_limit() -> int:
	var n := 10
	if has("E05"):
		n += 2
	return n


func max_energy_bonus() -> int:
	return 1 if has("E02") else 0


func poison_taken(n: int) -> int:
	if has("D01"):
		return int(floor(float(n) / 2.0))
	return n


## 受到攻击时的减伤（护腕：每场首次 −3）
func damage_taken(dmg: int) -> int:
	if has("D02") and not flags.get("wrist_used", false):
		flags["wrist_used"] = true
		return max(0, dmg - 3)
	return dmg


func bind_bonus() -> int:
	return 1 if has("D03") else 0


func reward_choices() -> int:
	return 4 if has("C02") else 3


func rest_remove_extra() -> int:
	return 1 if has("C04") else 0


func shop_discount() -> float:
	return 0.10 if has("B04") else 0.0


## 无归：休息点不能选「回复魂火」
func can_rest_heal() -> bool:
	return not has("E03")
