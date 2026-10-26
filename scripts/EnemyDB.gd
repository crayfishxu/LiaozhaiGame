class_name EnemyDB
extends RefCounted

## ------------------------------------------------------------------
## 敌人数据表 —— 纯规则数据，不含展示文案
##
## 名字走 I18N.enemy_name(key)，意图条走 I18N.intent_text(move)。
##
## moves 为行动循环，每回合按顺序取一条
##   kind:  attack 攻击 / defend 防御 / debuff 施毒
##   val:   数值
##   hits:  攻击次数（可省略）
##   verb:  意图条上的动词词条（见 scripts/i18n/*.gd 的 i.* ）
## ------------------------------------------------------------------

const ENEMIES := {
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
}

## 波次配置 —— layer / chapter 存的是词条 key，显示时再翻译
const WAVES := [
	{"layer": "ui.layer1", "chapter": "ui.chapter1", "enemies": ["youhun", "shukui"]},
	{"layer": "ui.layer2", "chapter": "ui.chapter2", "enemies": ["laolao"]},
	{"layer": "ui.layer3", "chapter": "ui.chapter3", "enemies": ["benti"]},
]
