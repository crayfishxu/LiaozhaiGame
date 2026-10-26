class_name CardDB
extends RefCounted

## ------------------------------------------------------------------
## 卡牌数据表 —— 纯规则数据，不含任何展示文案
##
## 卡名与描述全部走 I18N：
##   I18N.card_name("sushou")        → 素手 / Pale Hand / 素手 / …
##   I18N.card_text("sushou", "xian")→ 显相描述
##
## 每张牌都有两面：xian（显相）与 ben（本相）
## 打出后自动翻到另一面 —— 这是本作的核心机制
##
## 字段说明：
##   type    attack 嗔 / defend 障 / skill 念 / power 执 / curse 祟
##   cost    心力消耗
##   target  是否需要选择敌人
##   glyph   卡面占位字符（仅在没有立绘时显示）
##   xian/ben 两个面各自的效果字段
##
## 效果字段（可组合）：
##   dmg        造成伤害
##   hits       攻击次数（默认 1）
##   aoe_dmg    对全体造成伤害
##   block      获得障
##   self_hp    自损魂火
##   poison     施加祟毒层数
##   bind       缠绕回合数
##   weak       施加减益层数
##   aoe_weak   全体减益
##   draw       抽牌数
##   energy     获得心力
##   discard    弃牌数
##   thorns     反伤
##   weaken_enemy 降低目标攻击力
##   power      能力标记（永久生效）
##   special    特殊逻辑：poison_strike / grudge_bonus / grudge_burn
## ------------------------------------------------------------------

const CARDS := {
	# ---------- 嗔 · 攻击 ----------
	"sushou": {
		"type": "attack", "cost": 1, "target": true, "glyph": "嗔",
		"xian": {"dmg": 6},
		"ben": {"dmg": 9, "self_hp": 2},
	},
	"zhusha": {
		"type": "attack", "cost": 1, "target": true, "glyph": "嗔",
		"xian": {"dmg": 5, "poison": 2},
		"ben": {"dmg": 8, "poison": 3, "self_hp": 2},
	},
	"yeku": {
		"type": "attack", "cost": 2, "target": true, "glyph": "嗔",
		"xian": {"dmg": 4, "hits": 2},
		"ben": {"dmg": 6, "hits": 3, "self_hp": 3},
	},
	"chansi": {
		"type": "attack", "cost": 1, "target": true, "glyph": "嗔",
		"xian": {"dmg": 3, "bind": 1},
		"ben": {"special": "poison_strike"},
	},
	"yuannian": {
		"type": "attack", "cost": 2, "target": true, "glyph": "嗔",
		"xian": {"dmg": 6, "special": "grudge_bonus"},
		"ben": {"special": "grudge_burn"},
	},

	# ---------- 障 · 防御 ----------
	"suyi": {
		"type": "defend", "cost": 1, "target": false, "glyph": "障",
		"xian": {"block": 8},
		"ben": {"aoe_dmg": 12, "self_hp": 4},
	},
	"bosha": {
		"type": "defend", "cost": 1, "target": false, "glyph": "障",
		"xian": {"block": 6, "draw": 1},
		"ben": {"block": 3, "aoe_weak": 1},
	},
	"zhangbi": {
		"type": "defend", "cost": 2, "target": false, "glyph": "障",
		"xian": {"block": 12},
		"ben": {"block": 6, "thorns": 4},
	},

	# ---------- 念 · 技能 ----------
	"youyuan": {
		"type": "skill", "cost": 1, "target": true, "glyph": "念",
		"xian": {"poison": 3},
		"ben": {"poison": 5, "self_hp": 3},
	},
	"qingsi": {
		"type": "skill", "cost": 1, "target": true, "glyph": "念",
		"xian": {"bind": 1},
		"ben": {"bind": 2},
	},
	"yinlu": {
		"type": "skill", "cost": 1, "target": false, "glyph": "念",
		"xian": {"draw": 2},
		"ben": {"discard": 1, "draw": 3},
	},
	"yi": {
		"type": "skill", "cost": 0, "target": false, "glyph": "念",
		"xian": {"energy": 2},
		"ben": {"energy": 3, "self_hp": 3},
	},
	"dimei": {
		"type": "skill", "cost": 1, "target": true, "glyph": "念",
		"xian": {"weaken_enemy": 3},
		"ben": {"bind": 1, "self_hp": 5},
	},
	"ku": {
		"type": "skill", "cost": 1, "target": false, "glyph": "念",
		"xian": {"aoe_weak": 1},
		"ben": {"aoe_dmg": 8},
	},

	# ---------- 执 · 能力 ----------
	"yuanyuan": {
		"type": "power", "cost": 1, "target": false, "glyph": "执",
		"xian": {"power": "grudge_turn"},
		"ben": {"power": "grudge_hurt"},
	},
	"zhong": {
		"type": "power", "cost": 1, "target": false, "glyph": "执",
		"xian": {"power": "block_first"},
		"ben": {"power": "dmg_first"},
	},

	# ---------- 祟 · 诅咒 ----------
	"xiesui": {
		"type": "curse", "cost": 0, "target": false, "glyph": "祟",
		"xian": {"curse": true},
		"ben": {"curse": true},
	},
}

## 奖励池（战后三选一）
const REWARD_POOL := [
	"zhusha", "yeku", "chansi", "yuannian",
	"bosha", "zhangbi", "qingsi", "yi",
	"dimei", "ku", "yuanyuan", "zhong",
]
