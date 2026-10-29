class_name CardDB
extends RefCounted

## ------------------------------------------------------------------
## 卡牌数据表 —— 纯规则数据，不含任何展示文案
##
## 卡名走 I18N.card_name(key)，描述由 CardText.build() 按效果字段生成，
## 所以新增一张牌不需要动 11 个语种的描述文案。
##
## 每张牌都有两面：xian（显相）与 ben（本相）
## 打出后自动翻到另一面 —— 这是本作的核心机制
##
## 字段：
##   type     attack 嗔 / defend 障 / skill 念 / power 执 / curse 祟
##   cost     心力消耗
##   target   是否需要选择敌人
##   rarity   common / rare / epic / legendary
##   glyph    卡面占位字符（没有立绘时显示）
##   xian/ben 两个面各自的效果字段
##
## 通用效果字段：
##   dmg / hits          单体伤害与次数
##   aoe_dmg             全体伤害
##   block               获得障
##   heal                回复魂火
##   self_hp             自损魂火（无视障）
##   poison / aoe_poison 施祟毒
##   bind / aoe_bind     缠绕回合数
##   weak / aoe_weak     施祟弱层数
##   draw / energy       抽牌 / 获得心力
##   energy_next         下回合心力
##   discard             弃牌
##   thorns              本回合反伤
##   weaken_enemy        目标下回合攻击力降低
##   no_attack           本回合无法打出攻击牌
##   cleanse             解除自身负面
##   exhaust             消耗（本场不再回到弃牌堆）
##   power               能力标记
##   return_discard      从弃牌堆取回 N 张
##   add_curse           置入一张祟到弃牌堆
##
## 结算型效果（special）：
##   poison_strike   伤害 = 目标毒层 × 2
##   poison_scale    伤害 = 目标毒层 × mult，之后追加 extra_poison 层毒
##   poison_consume  消耗目标全部毒，每层 mult 点伤害
##   double_poison   目标毒层翻倍
##   grudge_bonus    基础伤害 + 每 5 点怨气 × mult
##   grudge_burn     耗尽怨气，每点 mult 点伤害
##   block_strike    伤害 = 当前障
##   block_burn      消耗全部障，伤害 = 障 × 1.5
##   draw_per_poison 按目标毒层抽牌，上限 max
##   draw_if_bound   若有敌人被缠绕，额外抽 extra 张
##   random_bind     随机缠绕一名敌人 random_bind 回合
##   random_dmg      对随机敌人造成 random_dmg 伤害
##   poison_splash   对每个中毒的敌人造成 poison_splash 伤害
## ------------------------------------------------------------------

const CARDS := {
	# ============ 通用 · 攻击（8） ============
	"sushou": {
		"type": "attack", "cost": 1, "target": true, "rarity": "common", "glyph": "嗔",
		"xian": {"dmg": 6},
		"ben": {"dmg": 9, "self_hp": 2},
	},
	"zhusha": {
		"type": "attack", "cost": 1, "target": true, "rarity": "common", "glyph": "嗔",
		"xian": {"dmg": 5, "poison": 2},
		"ben": {"dmg": 8, "poison": 3, "self_hp": 2},
	},
	"yeku": {
		"type": "attack", "cost": 2, "target": true, "rarity": "common", "glyph": "嗔",
		"xian": {"dmg": 4, "hits": 2},
		"ben": {"dmg": 6, "hits": 3, "self_hp": 3},
	},
	"chansi": {
		"type": "attack", "cost": 1, "target": true, "rarity": "common", "glyph": "嗔",
		"xian": {"dmg": 3, "bind": 1},
		"ben": {"special": "poison_strike"},
	},
	"yuannian": {
		"type": "attack", "cost": 2, "target": true, "rarity": "rare", "glyph": "嗔",
		"xian": {"dmg": 6, "special": "grudge_bonus", "mult": 2},
		"ben": {"special": "grudge_burn", "mult": 2},
	},
	"yichu": {
		"type": "attack", "cost": 0, "target": true, "rarity": "common", "glyph": "嗔",
		"xian": {"dmg": 3},
		"ben": {"dmg": 5, "self_hp": 1},
	},
	"shuangying": {
		"type": "attack", "cost": 1, "target": true, "rarity": "rare", "glyph": "嗔",
		"xian": {"dmg": 5, "hits": 2, "discard": 1},
		"ben": {"dmg": 7, "hits": 2, "self_hp": 2},
	},
	"huifeng": {
		"type": "attack", "cost": 1, "target": true, "rarity": "rare", "glyph": "嗔",
		"xian": {"special": "block_strike"},
		"ben": {"special": "block_burn"},
	},

	# ============ 通用 · 防御（5） ============
	"suyi": {
		"type": "defend", "cost": 1, "target": false, "rarity": "common", "glyph": "障",
		"xian": {"block": 8},
		"ben": {"aoe_dmg": 12, "self_hp": 4},
	},
	"bosha": {
		"type": "defend", "cost": 1, "target": false, "rarity": "common", "glyph": "障",
		"xian": {"block": 6, "draw": 1},
		"ben": {"block": 3, "aoe_weak": 1},
	},
	"zhangbi": {
		"type": "defend", "cost": 2, "target": false, "rarity": "common", "glyph": "障",
		"xian": {"block": 12},
		"ben": {"block": 6, "thorns": 4},
	},
	"pingxi": {
		"type": "defend", "cost": 1, "target": false, "rarity": "rare", "glyph": "障",
		"xian": {"block": 5, "energy_next": 1},
		"ben": {"block": 8, "no_attack": true},
	},
	"luomu": {
		"type": "defend", "cost": 0, "target": false, "rarity": "common", "glyph": "障",
		"xian": {"block": 3},
		"ben": {"block": 6, "self_hp": 2},
	},

	# ============ 通用 · 技能（5） ============
	"yinlu": {
		"type": "skill", "cost": 1, "target": false, "rarity": "common", "glyph": "念",
		"xian": {"draw": 2},
		"ben": {"discard": 1, "draw": 3},
	},
	"yi": {
		"type": "skill", "cost": 0, "target": false, "rarity": "rare", "glyph": "念",
		"xian": {"energy": 2, "exhaust": true},
		"ben": {"energy": 3, "self_hp": 3, "exhaust": true},
	},
	"dimei": {
		"type": "skill", "cost": 1, "target": true, "rarity": "common", "glyph": "念",
		"xian": {"weaken_enemy": 3},
		"ben": {"bind": 1, "self_hp": 5},
	},
	"ku": {
		"type": "skill", "cost": 1, "target": false, "rarity": "common", "glyph": "念",
		"xian": {"aoe_weak": 1},
		"ben": {"aoe_dmg": 8},
	},
	"shiyi": {
		"type": "skill", "cost": 1, "target": false, "rarity": "rare", "glyph": "念",
		"xian": {"return_discard": 1, "exhaust": true},
		"ben": {"return_discard": 2, "self_hp": 3, "exhaust": true},
	},

	# ============ 通用 · 能力（2） ============
	"yuanyuan": {
		"type": "power", "cost": 1, "target": false, "rarity": "rare", "glyph": "执",
		"xian": {"power": "grudge_turn"},
		"ben": {"power": "grudge_hurt"},
	},
	"zhong": {
		"type": "power", "cost": 1, "target": false, "rarity": "epic", "glyph": "执",
		"xian": {"power": "block_first"},
		"ben": {"power": "dmg_first"},
	},

	# ============ 幽怨流（12） ============
	"youyuan": {
		"type": "skill", "cost": 1, "target": true, "rarity": "common", "glyph": "念",
		"xian": {"poison": 3},
		"ben": {"poison": 5, "self_hp": 3},
	},
	"shigu": {
		"type": "skill", "cost": 2, "target": true, "rarity": "common", "glyph": "念",
		"xian": {"poison": 6},
		"ben": {"poison": 9, "self_hp": 4},
	},
	"yuandu": {
		"type": "skill", "cost": 1, "target": true, "rarity": "rare", "glyph": "念",
		"xian": {"poison": 3, "draw": 1},
		"ben": {"special": "double_poison"},
	},
	"shixin": {
		"type": "attack", "cost": 2, "target": true, "rarity": "epic", "glyph": "嗔",
		"xian": {"special": "poison_scale", "mult": 3},
		"ben": {"special": "poison_consume", "mult": 5},
	},
	"yinyi": {
		"type": "skill", "cost": 1, "target": false, "rarity": "common", "glyph": "念",
		"xian": {"aoe_poison": 2},
		"ben": {"aoe_poison": 4, "self_hp": 3},
	},
	"changye": {
		"type": "skill", "cost": 3, "target": false, "rarity": "epic", "glyph": "念",
		"xian": {"aoe_poison": 6},
		"ben": {"aoe_poison": 10, "self_hp": 6},
	},
	"qinran": {
		"type": "skill", "cost": 1, "target": false, "rarity": "rare", "glyph": "念",
		"xian": {"aoe_poison": 3, "add_curse": "xiesui"},
		"ben": {"aoe_poison": 5, "self_hp": 2},
	},
	"shiyue": {
		"type": "attack", "cost": 2, "target": true, "rarity": "rare", "glyph": "嗔",
		"xian": {"dmg": 12, "dmg_if_poison": 6},
		"ben": {"dmg": 18, "dmg_if_poison": 9, "self_hp": 3},
	},
	"binggu": {
		"type": "attack", "cost": 1, "target": true, "rarity": "common", "glyph": "嗔",
		"xian": {"dmg": 5, "poison": 2, "draw": 1},
		"ben": {"dmg": 8, "poison": 3, "self_hp": 2},
	},
	"youhuang": {
		"type": "defend", "cost": 1, "target": false, "rarity": "common", "glyph": "障",
		"xian": {"block": 6, "poison_splash": 4},
		"ben": {"block": 9, "aoe_dmg": 3},
	},
	"shihun": {
		"type": "skill", "cost": 2, "target": true, "rarity": "rare", "glyph": "念",
		"xian": {"special": "draw_per_poison", "max": 3},
		"ben": {"draw": 3, "poison": 3, "self_hp": 3},
	},
	"fuxin": {
		"type": "attack", "cost": 3, "target": true, "rarity": "legendary", "glyph": "嗔",
		"xian": {"special": "poison_scale", "mult": 4, "extra_poison": 3, "exhaust": true},
		"ben": {"special": "poison_consume", "mult": 7, "self_hp": 6},
	},

	# ============ 情丝流（10） ============
	"qingsi": {
		"type": "skill", "cost": 1, "target": true, "rarity": "common", "glyph": "念",
		"xian": {"bind": 1},
		"ben": {"bind": 2},
	},
	"chanmian": {
		"type": "skill", "cost": 2, "target": true, "rarity": "common", "glyph": "念",
		"xian": {"bind": 1, "draw": 2},
		"ben": {"bind": 2, "draw": 1, "self_hp": 3},
	},
	"qiansi": {
		"type": "skill", "cost": 2, "target": false, "rarity": "rare", "glyph": "念",
		"xian": {"aoe_dmg": 4, "aoe_bind": 1},
		"ben": {"aoe_dmg": 7, "aoe_bind": 1, "self_hp": 5},
	},
	"fuhun": {
		"type": "skill", "cost": 1, "target": true, "rarity": "rare", "glyph": "念",
		"xian": {"weaken_enemy": 4},
		"ben": {"bind": 1, "self_hp": 6},
	},
	"suoming": {
		"type": "attack", "cost": 1, "target": true, "rarity": "common", "glyph": "嗔",
		"xian": {"dmg_if_bound": 10},
		"ben": {"dmg_if_bound": 14, "self_hp": 4},
	},
	"sijin": {
		"type": "skill", "cost": 0, "target": true, "rarity": "common", "glyph": "念",
		"xian": {"bind": 1, "self_hp": 2},
		"ben": {"bind": 2, "draw": 2},
	},
	"chanzhu": {
		"type": "defend", "cost": 1, "target": false, "rarity": "common", "glyph": "障",
		"xian": {"block": 5, "special": "random_bind", "random_bind": 1},
		"ben": {"block": 8, "special": "random_bind", "random_bind": 2, "self_hp": 3},
	},
	"siwang": {
		"type": "skill", "cost": 2, "target": false, "rarity": "rare", "glyph": "念",
		"xian": {"aoe_dmg": 3, "aoe_bind": 1},
		"ben": {"aoe_dmg": 6, "aoe_bind": 2, "self_hp": 4},
	},
	"qianji": {
		"type": "skill", "cost": 1, "target": false, "rarity": "common", "glyph": "念",
		"xian": {"draw": 1, "special": "draw_if_bound", "extra": 1},
		"ben": {"draw": 3, "self_hp": 3},
	},
	"duansi": {
		"type": "skill", "cost": 1, "target": false, "rarity": "rare", "glyph": "念",
		"xian": {"cleanse": true, "draw": 1, "exhaust": true},
		"ben": {"cleanse": true, "special": "random_dmg", "random_dmg": 8, "exhaust": true},
	},

	# ============ 核心（3） ============
	"lanruo": {
		"type": "attack", "cost": 3, "target": false, "rarity": "legendary", "glyph": "嗔",
		"xian": {"aoe_dmg": 8, "aoe_poison": 3, "exhaust": true},
		"ben": {"aoe_dmg": 14, "aoe_poison": 5, "self_hp": 8},
	},
	"baiyi": {
		"type": "defend", "cost": 2, "target": false, "rarity": "epic", "glyph": "障",
		"xian": {"block": 15, "draw": 1},
		"ben": {"self_hp": 6, "block": 20, "thorns": 6},
	},
	"youhunbusan": {
		"type": "power", "cost": 2, "target": false, "rarity": "epic", "glyph": "执",
		"xian": {"power": "poison_first"},
		"ben": {"power": "aoe_first"},
	},

	# ============ 祟（7） ============
	"xiesui": {
		"type": "curse", "cost": 0, "target": false, "rarity": "common", "glyph": "祟",
		"curse": "lose_hp", "xian": {"curse": true}, "ben": {"curse": true},
	},
	"yinqi": {
		"type": "curse", "cost": 0, "target": false, "rarity": "common", "glyph": "祟",
		"curse": "hand_minus", "xian": {"curse": true}, "ben": {"curse": true},
	},
	"xinmo": {
		"type": "curse", "cost": 0, "target": false, "rarity": "rare", "glyph": "祟",
		"curse": "cost_up", "xian": {"curse": true}, "ben": {"curse": true},
	},
	"wangnian": {
		"type": "curse", "cost": 0, "target": false, "rarity": "rare", "glyph": "祟",
		"curse": "discard_end", "xian": {"curse": true}, "ben": {"curse": true},
	},
	"yuannianchanshen": {
		"type": "curse", "cost": 0, "target": false, "rarity": "rare", "glyph": "祟",
		"curse": "dmg_up", "xian": {"curse": true}, "ben": {"curse": true},
	},
	"yezhang": {
		"type": "curse", "cost": 0, "target": false, "rarity": "epic", "glyph": "祟",
		"curse": "unremovable", "xian": {"curse": true}, "ben": {"curse": true},
	},
	## 事件「雪山问话」的第三选项奖励 —— 唯一一张带正面收益的祟
	"jiangbanya": {
		"type": "curse", "cost": 0, "target": false, "rarity": "common", "glyph": "祟",
		"curse": "heal_turn", "xian": {"curse": true}, "ben": {"curse": true},
	},
}

## 卡池（不含祟）
const POOL := [
	"sushou", "zhusha", "yeku", "chansi", "yuannian", "yichu", "shuangying", "huifeng",
	"suyi", "bosha", "zhangbi", "pingxi", "luomu",
	"yinlu", "yi", "dimei", "ku", "shiyi",
	"yuanyuan", "zhong",
	"youyuan", "shigu", "yuandu", "shixin", "yinyi", "changye", "qinran",
	"shiyue", "binggu", "youhuang", "shihun", "fuxin",
	"qingsi", "chanmian", "qiansi", "fuhun", "suoming", "sijin", "chanzhu",
	"siwang", "qianji", "duansi",
	"lanruo", "baiyi", "youhunbusan",
]

## 奖励出现权重（GDD 4.2）
const RARITY_WEIGHT := {"common": 60, "rare": 28, "epic": 10, "legendary": 2}

## 商店定价（GDD 7.7）
const PRICE := {"common": 45, "rare": 75, "epic": 110, "legendary": 160}


static func exists(key: String) -> bool:
	return CARDS.has(key)


static func is_curse(key: String) -> bool:
	return CARDS.has(key) and str(CARDS[key]["type"]) == "curse"


static func rarity_of(key: String) -> String:
	return str(CARDS[key].get("rarity", "common"))


## 按稀有度权重抽 n 张不重复的牌
static func roll_rewards(rng: RandomNumberGenerator, n: int) -> Array:
	var total := 0
	for k in RARITY_WEIGHT.values():
		total += int(k)
	var out: Array = []
	var guard := 0
	while out.size() < n and guard < 200:
		guard += 1
		var roll := rng.randi_range(1, total)
		var want := "common"
		for r in ["common", "rare", "epic", "legendary"]:
			roll -= int(RARITY_WEIGHT[r])
			if roll <= 0:
				want = r
				break
		var bucket: Array = []
		for k in POOL:
			if rarity_of(k) == want and not out.has(k):
				bucket.append(k)
		if bucket.is_empty():
			continue
		out.append(str(bucket[rng.randi() % bucket.size()]))
	return out
