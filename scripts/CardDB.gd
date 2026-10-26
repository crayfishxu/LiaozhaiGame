class_name CardDB
extends RefCounted

## ------------------------------------------------------------------
## 卡牌数据表
## 每张牌都有两面：xian（显相）与 ben（本相）
## 打出后自动翻到另一面 —— 这是本作的核心机制
##
## 字段说明：
##   name    卡名
##   type    attack 嗔 / defend 障 / skill 念 / power 执 / curse 祟
##   cost    心力消耗
##   target  是否需要选择敌人
##   glyph   卡面占位字符（美术接入后可忽略，改为显示立绘）
##   xian/ben 两个面各自的 { text, 效果字段... }
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
		"name": "素手", "type": "attack", "cost": 1, "target": true, "glyph": "嗔",
		"xian": {"text": "造成 6 点伤害", "dmg": 6},
		"ben": {"text": "造成 9 点伤害\n自损 2 魂火", "dmg": 9, "self_hp": 2},
	},
	"zhusha": {
		"name": "朱砂", "type": "attack", "cost": 1, "target": true, "glyph": "嗔",
		"xian": {"text": "造成 5 点伤害\n施 2 层祟毒", "dmg": 5, "poison": 2},
		"ben": {"text": "造成 8 点伤害\n施 3 层祟毒，自损 2", "dmg": 8, "poison": 3, "self_hp": 2},
	},
	"yeku": {
		"name": "夜哭", "type": "attack", "cost": 2, "target": true, "glyph": "嗔",
		"xian": {"text": "造成 4 点伤害 2 次", "dmg": 4, "hits": 2},
		"ben": {"text": "造成 6 点伤害 3 次\n自损 3 魂火", "dmg": 6, "hits": 3, "self_hp": 3},
	},
	"chansi": {
		"name": "缠丝", "type": "attack", "cost": 1, "target": true, "glyph": "嗔",
		"xian": {"text": "造成 3 点伤害\n缠绕 1 回合", "dmg": 3, "bind": 1},
		"ben": {"text": "造成目标祟毒层数 ×2\n的伤害", "special": "poison_strike"},
	},
	"yuannian": {
		"name": "怨念", "type": "attack", "cost": 2, "target": true, "glyph": "嗔",
		"xian": {"text": "造成 6 点伤害\n每 5 点怨气 +2", "dmg": 6, "special": "grudge_bonus"},
		"ben": {"text": "耗尽全部怨气\n每点造成 2 点伤害", "special": "grudge_burn"},
	},

	# ---------- 障 · 防御 ----------
	"suyi": {
		"name": "素衣", "type": "defend", "cost": 1, "target": false, "glyph": "障",
		"xian": {"text": "获得 8 点障", "block": 8},
		"ben": {"text": "失去 4 点魂火\n对全体造成 12 点伤害", "aoe_dmg": 12, "self_hp": 4},
	},
	"bosha": {
		"name": "薄纱", "type": "defend", "cost": 1, "target": false, "glyph": "障",
		"xian": {"text": "获得 6 点障\n抽 1 张牌", "block": 6, "draw": 1},
		"ben": {"text": "获得 3 点障\n全体施 1 层祟弱", "block": 3, "aoe_weak": 1},
	},
	"zhangbi": {
		"name": "障壁", "type": "defend", "cost": 2, "target": false, "glyph": "障",
		"xian": {"text": "获得 12 点障", "block": 12},
		"ben": {"text": "获得 6 点障\n本回合反伤 4", "block": 6, "thorns": 4},
	},

	# ---------- 念 · 技能 ----------
	"youyuan": {
		"name": "幽怨", "type": "skill", "cost": 1, "target": true, "glyph": "念",
		"xian": {"text": "施加 3 层祟毒", "poison": 3},
		"ben": {"text": "施加 5 层祟毒\n自损 3 魂火", "poison": 5, "self_hp": 3},
	},
	"qingsi": {
		"name": "情丝", "type": "skill", "cost": 1, "target": true, "glyph": "念",
		"xian": {"text": "缠绕 1 回合", "bind": 1},
		"ben": {"text": "缠绕 2 回合", "bind": 2},
	},
	"yinlu": {
		"name": "引路", "type": "skill", "cost": 1, "target": false, "glyph": "念",
		"xian": {"text": "抽 2 张牌", "draw": 2},
		"ben": {"text": "弃 1 张牌\n抽 3 张牌", "discard": 1, "draw": 3},
	},
	"yi": {
		"name": "忆", "type": "skill", "cost": 0, "target": false, "glyph": "念",
		"xian": {"text": "获得 2 点心力", "energy": 2},
		"ben": {"text": "失去 3 点魂火\n获得 3 点心力", "energy": 3, "self_hp": 3},
	},
	"dimei": {
		"name": "低眉", "type": "skill", "cost": 1, "target": true, "glyph": "念",
		"xian": {"text": "目标下回合\n攻击降低 3 点", "weaken_enemy": 3},
		"ben": {"text": "目标无法行动 1 回合\n自损 5 魂火", "bind": 1, "self_hp": 5},
	},
	"ku": {
		"name": "哭", "type": "skill", "cost": 1, "target": false, "glyph": "念",
		"xian": {"text": "全体施加 1 层祟弱", "aoe_weak": 1},
		"ben": {"text": "对全体造成 8 点伤害", "aoe_dmg": 8},
	},

	# ---------- 执 · 能力 ----------
	"yuanyuan": {
		"name": "怨气缠身", "type": "power", "cost": 1, "target": false, "glyph": "执",
		"xian": {"text": "每回合开始\n获得 2 点怨气", "power": "grudge_turn"},
		"ben": {"text": "受到伤害时\n额外获得 2 点怨气", "power": "grudge_hurt"},
	},
	"zhong": {
		"name": "兰若钟声", "type": "power", "cost": 1, "target": false, "glyph": "执",
		"xian": {"text": "每回合首次出牌\n获得 2 点障", "power": "block_first"},
		"ben": {"text": "每回合首次出牌\n随机造成 4 点伤害", "power": "dmg_first"},
	},

	# ---------- 祟 · 诅咒 ----------
	"xiesui": {
		"name": "邪祟", "type": "curse", "cost": 0, "target": false, "glyph": "祟",
		"xian": {"text": "无法打出\n占据手牌", "curse": true},
		"ben": {"text": "无法打出\n占据手牌", "curse": true},
	},
}

## 奖励池（战后三选一）
const REWARD_POOL := [
	"zhusha", "yeku", "chansi", "yuannian",
	"bosha", "zhangbi", "qingsi", "yi",
	"dimei", "ku", "yuanyuan", "zhong",
]

## 类型显示名
const TYPE_NAMES := {
	"attack": "嗔",
	"defend": "障",
	"skill": "念",
	"power": "执",
	"curse": "祟",
}
