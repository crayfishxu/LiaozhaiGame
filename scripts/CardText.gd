class_name CardText
extends RefCounted

## ------------------------------------------------------------------
## 卡面描述生成器
##
## 51 张卡 × 两面 × 11 个语种 = 1122 条描述，手写不可能维护。
## 所以描述不存文案表，而是由效果字段拼出来：
##   效果模板 40 条 × 11 语种 = 440 条，覆盖全部卡牌。
## 新增一张牌只要在 CardDB 填数值，11 个语种自动就有描述。
## ------------------------------------------------------------------

## 拼接顺序固定，保证同类卡描述读起来一致
static func build(key: String, side: String) -> String:
	if not CardDB.CARDS.has(key):
		return ""
	var def: Dictionary = CardDB.CARDS[key]

	# 祟：两面相同，走独立词条
	if str(def["type"]) == "curse":
		return I18N.t("curse." + str(def.get("curse", "lose_hp")))

	var fx: Dictionary = def[side]
	if fx.has("power"):
		return I18N.t("pw." + str(fx["power"]))

	var parts: Array = []
	var sp := str(fx.get("special", ""))

	# ---- 伤害 ----
	if sp == "poison_strike":
		parts.append(I18N.t("fx.p2"))
	elif sp == "poison_scale":
		parts.append(I18N.t("fx.pscale", [int(fx.get("mult", 3))]))
	elif sp == "poison_consume":
		parts.append(I18N.t("fx.pconsume", [int(fx.get("mult", 5))]))
	elif sp == "grudge_burn":
		parts.append(I18N.t("fx.grp_burn", [int(fx.get("mult", 2))]))
	elif sp == "block_strike":
		parts.append(I18N.t("fx.block_strike"))
	elif sp == "block_burn":
		parts.append(I18N.t("fx.block_burn"))
	elif sp == "random_dmg":
		parts.append(I18N.t("fx.random_dmg", [int(fx.get("random_dmg", 0))]))
	elif fx.has("dmg_if_bound"):
		parts.append(I18N.t("fx.if_bound", [int(fx["dmg_if_bound"])]))
	elif fx.has("dmg"):
		var hits := int(fx.get("hits", 1))
		if hits > 1:
			parts.append(I18N.t("fx.dmg_hits", [int(fx["dmg"]), hits]))
		else:
			parts.append(I18N.t("fx.dmg", [int(fx["dmg"])]))
		if sp == "grudge_bonus":
			parts.append(I18N.t("fx.grp_bonus", [int(fx.get("mult", 2))]))
		if fx.has("dmg_if_poison"):
			parts.append(I18N.t("fx.if_poison", [int(fx["dmg_if_poison"])]))

	if fx.has("aoe_dmg"):
		parts.append(I18N.t("fx.aoe_dmg", [int(fx["aoe_dmg"])]))

	# ---- 防御与回复 ----
	if fx.has("block"):
		parts.append(I18N.t("fx.block", [int(fx["block"])]))
	if fx.has("heal"):
		parts.append(I18N.t("fx.heal", [int(fx["heal"])]))
	if fx.has("thorns"):
		parts.append(I18N.t("fx.thorns", [int(fx["thorns"])]))

	# ---- 状态 ----
	if fx.has("poison"):
		parts.append(I18N.t("fx.poison", [int(fx["poison"])]))
	if fx.has("aoe_poison"):
		parts.append(I18N.t("fx.aoe_poison", [int(fx["aoe_poison"])]))
	if sp == "double_poison":
		parts.append(I18N.t("fx.pdouble"))
	if fx.has("extra_poison"):
		parts.append(I18N.t("fx.extra_poison", [int(fx["extra_poison"])]))
	if fx.has("bind"):
		parts.append(I18N.t("fx.bind", [int(fx["bind"])]))
	if fx.has("aoe_bind"):
		parts.append(I18N.t("fx.aoe_bind", [int(fx["aoe_bind"])]))
	if fx.has("weak"):
		parts.append(I18N.t("fx.weak", [int(fx["weak"])]))
	if fx.has("aoe_weak"):
		parts.append(I18N.t("fx.aoe_weak", [int(fx["aoe_weak"])]))
	if fx.has("weaken_enemy"):
		parts.append(I18N.t("fx.weaken", [int(fx["weaken_enemy"])]))
	if sp == "random_bind":
		parts.append(I18N.t("fx.random_bind", [int(fx.get("random_bind", 1))]))
	if sp == "poison_splash":
		parts.append(I18N.t("fx.poison_splash", [int(fx.get("poison_splash", 0))]))

	# ---- 牌与资源 ----
	if fx.has("draw"):
		parts.append(I18N.t("fx.draw", [int(fx["draw"])]))
	if sp == "draw_per_poison":
		parts.append(I18N.t("fx.draw_per_poison", [int(fx.get("max", 3))]))
	if sp == "draw_if_bound":
		parts.append(I18N.t("fx.draw_if_bound", [int(fx.get("extra", 1))]))
	if fx.has("energy"):
		parts.append(I18N.t("fx.energy", [int(fx["energy"])]))
	if fx.has("energy_next"):
		parts.append(I18N.t("fx.energy_next", [int(fx["energy_next"])]))
	if fx.has("discard"):
		parts.append(I18N.t("fx.discard", [int(fx["discard"])]))
	if fx.has("return_discard"):
		parts.append(I18N.t("fx.return", [int(fx["return_discard"])]))
	if fx.has("add_curse"):
		parts.append(I18N.t("fx.add_curse", [I18N.card_name(str(fx["add_curse"]))]))
	if fx.has("cleanse"):
		parts.append(I18N.t("fx.cleanse"))
	if fx.has("no_attack"):
		parts.append(I18N.t("fx.no_attack"))

	# ---- 代价（放最后）----
	if fx.has("self_hp"):
		parts.append(I18N.t("fx.self_hp", [int(fx["self_hp"])]))

	var out := ""
	for i in parts.size():
		if i > 0:
			out += I18N.t("fx.sep")
		out += str(parts[i])
	if fx.has("exhaust"):
		out += I18N.t("fx.exhaust_suffix")
	return out
