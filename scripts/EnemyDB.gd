class_name EnemyDB
extends RefCounted

## ------------------------------------------------------------------
## 敌人数据表 —— 纯规则数据，不含任何展示文案
##
## 名字走 I18N.enemy_name(key)，意图条走 I18N.intent_text(move)。
##
## moves 为行动循环，每回合按顺序取一条
##   kind:  attack 攻击 / defend 防御 / debuff 施毒 / weak 施祟弱
##          buff 强化自身攻击 / summon 召唤
##   val:   数值
##   hits:  攻击次数（可省略）
##   self:  自身受到的伤害（暴食之类）
##   verb:  意图条上的动词词条（见 scripts/i18n/*.gd 的 i.* ）
## ------------------------------------------------------------------

const ENEMIES := {
	# ===== 第 1 层 · 凡尘 =====
	"youhun": {
		"glyph": "魂", "hp": 28,
		"moves": [
			{"kind": "attack", "val": 5, "verb": "i.bite"},
			{"kind": "attack", "val": 8, "verb": "i.bite"},
			{"kind": "defend", "val": 6, "verb": "i.cocoon"},
		],
	},
	"shukui": {
		"glyph": "傀", "hp": 34,
		"moves": [
			{"kind": "attack", "val": 6, "verb": "i.branch"},
			{"kind": "debuff", "val": 2, "verb": "i.wrap"},
			{"kind": "attack", "val": 4, "hits": 2, "verb": "i.lash"},
		],
	},
	"kugu": {
		"glyph": "骨", "hp": 30,
		"moves": [
			{"kind": "attack", "val": 7, "verb": "i.claw"},
			{"kind": "defend", "val": 5, "verb": "i.harden"},
		],
	},
	"zhiren": {
		"glyph": "纸", "hp": 22,
		"moves": [
			{"kind": "attack", "val": 4, "hits": 2, "verb": "i.tear"},
			{"kind": "weak", "val": 1, "verb": "i.possess"},
		],
	},
	"laolao": {
		"glyph": "姥", "hp": 52, "art_h": 184,
		"moves": [
			{"kind": "attack", "val": 9, "verb": "i.claw"},
			{"kind": "defend", "val": 10, "verb": "i.cocoon"},
			{"kind": "attack", "val": 13, "verb": "i.drain"},
		],
	},
	"benti": {
		"glyph": "妖", "hp": 74, "art_h": 190,
		"moves": [
			{"kind": "attack", "val": 11, "verb": "i.tendril"},
			{"kind": "debuff", "val": 3, "verb": "i.rot"},
			{"kind": "attack", "val": 7, "hits": 2, "verb": "i.dual"},
			{"kind": "attack", "val": 16, "verb": "i.souleat"},
		],
	},

	# ===== 第 2 层 · 幽冥 =====
	"yinchai": {
		"glyph": "差", "hp": 42,
		"moves": [
			{"kind": "attack", "val": 9, "verb": "i.lock"},
			{"kind": "attack", "val": 12, "verb": "i.judge"},
			{"kind": "attack", "val": 6, "verb": "i.reap"},
		],
	},
	"egui": {
		"glyph": "饿", "hp": 38,
		"moves": [
			{"kind": "attack", "val": 8, "verb": "i.swallow"},
			{"kind": "attack", "val": 8, "verb": "i.swallow"},
			{"kind": "attack", "val": 14, "self": 5, "verb": "i.gluttony"},
		],
	},
	"shuigui": {
		"glyph": "溺", "hp": 45,
		"moves": [
			{"kind": "attack", "val": 10, "verb": "i.drag"},
			{"kind": "debuff", "val": 4, "verb": "i.drown"},
		],
	},
	"wuchang": {
		"glyph": "无常", "hp": 50,
		"moves": [
			{"kind": "attack", "val": 11, "verb": "i.arrest"},
			{"kind": "attack", "val": 15, "verb": "i.claim"},
		],
	},
	"guimu_small": {
		"glyph": "母", "hp": 85, "art_h": 190,
		"moves": [
			{"kind": "attack", "val": 12, "verb": "i.feed"},
			{"kind": "attack", "val": 8, "hits": 2, "verb": "i.swarm"},
			{"kind": "weak", "val": 3, "verb": "i.wind"},
		],
	},
	"guimu": {
		"glyph": "鬼母", "hp": 110, "art_h": 196,
		"moves": [
			{"kind": "attack", "val": 9, "hits": 3, "verb": "i.swarm"},
			{"kind": "weak", "val": 2, "verb": "i.wind"},
			{"kind": "attack", "val": 18, "verb": "i.devour"},
			{"kind": "summon", "val": 2, "verb": "i.summon"},
		],
	},

	# ===== 第 3 层 · 妖界 =====
	"huyao": {
		"glyph": "狐", "hp": 58,
		"moves": [
			{"kind": "attack", "val": 12, "verb": "i.charm"},
			{"kind": "weak", "val": 3, "verb": "i.illusion"},
			{"kind": "attack", "val": 16, "verb": "i.bite"},
		],
	},
	"shemei": {
		"glyph": "蛇", "hp": 62,
		"moves": [
			{"kind": "attack", "val": 14, "verb": "i.coil"},
			{"kind": "debuff", "val": 5, "verb": "i.venom"},
			{"kind": "attack", "val": 18, "verb": "i.constrict"},
		],
	},
	"huapi": {
		"glyph": "皮", "hp": 65,
		"moves": [
			{"kind": "defend", "val": 20, "verb": "i.shed"},
			{"kind": "attack", "val": 15, "verb": "i.peel"},
			{"kind": "attack", "val": 20, "verb": "i.reveal"},
		],
	},
	"yaojiang": {
		"glyph": "将", "hp": 110, "art_h": 196,
		"moves": [
			{"kind": "attack", "val": 18, "verb": "i.slash"},
			{"kind": "attack", "val": 12, "hits": 2, "verb": "i.sweep"},
			{"kind": "buff", "val": 3, "verb": "i.war"},
		],
	},
	"shuyao": {
		"glyph": "树妖", "hp": 150, "art_h": 200,
		"moves": [
			{"kind": "attack", "val": 11, "verb": "i.silk"},
			{"kind": "debuff", "val": 3, "verb": "i.rot"},
			{"kind": "attack", "val": 7, "hits": 2, "verb": "i.dual"},
			{"kind": "attack", "val": 16, "verb": "i.souleat"},
			{"kind": "attack", "val": 12, "poison": 4, "verb": "i.swarm"},
		],
	},
}

## 层配置 —— 地图生成与敌人生成共用
const LAYERS := [
	{
		"name": "ui.layer1", "chapter": "ui.chapter1",
		"rows": 6, "cols_min": 2, "cols_max": 4, "min_paths": 4,
		"pool": ["youhun", "shukui", "kugu", "zhiren"],
		"elite": "laolao", "boss": "benti",
	},
	{
		"name": "ui.layer2", "chapter": "ui.chapter2",
		"rows": 6, "cols_min": 2, "cols_max": 4, "min_paths": 4,
		"pool": ["yinchai", "egui", "shuigui", "wuchang"],
		"elite": "guimu_small", "boss": "guimu",
	},
	{
		"name": "ui.layer3", "chapter": "ui.chapter3",
		"rows": 5, "cols_min": 2, "cols_max": 3, "min_paths": 3,
		"pool": ["huyao", "shemei", "huapi"],
		"elite": "yaojiang", "boss": "shuyao",
	},
]
