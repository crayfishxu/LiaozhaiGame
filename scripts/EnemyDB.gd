class_name EnemyDB
extends RefCounted

## ------------------------------------------------------------------
## 敌人数据表
## moves 为行动循环，每回合按顺序取一条
##   kind: attack 攻击 / defend 防御 / debuff 施毒
##   val:  数值
##   hits: 攻击次数（可省略）
##   label: 意图条上显示的短标签
## ------------------------------------------------------------------

const ENEMIES := {
	"youhun": {
		"name": "游魂", "glyph": "魂", "hp": 28,
		"moves": [
			{"kind": "attack", "val": 5, "label": "噬 5"},
			{"kind": "attack", "val": 8, "label": "噬 8"},
			{"kind": "defend", "val": 6, "label": "聚 6"},
		],
	},
	"shukui": {
		"name": "树傀", "glyph": "傀", "hp": 34,
		"moves": [
			{"kind": "attack", "val": 6, "label": "枝 6"},
			{"kind": "debuff", "val": 2, "label": "缠 毒 2"},
			{"kind": "attack", "val": 4, "hits": 2, "label": "鞭 4×2"},
		],
	},
	"laolao": {
		"name": "姥姥", "glyph": "姥", "hp": 52, "art_h": 184,
		"moves": [
			{"kind": "attack", "val": 9, "label": "爪 9"},
			{"kind": "defend", "val": 10, "label": "茧 10"},
			{"kind": "attack", "val": 13, "label": "吸 13"},
		],
	},
	"benti": {
		"name": "树妖姥姥", "glyph": "妖", "hp": 74, "art_h": 190,
		"moves": [
			{"kind": "attack", "val": 11, "label": "万丝 11"},
			{"kind": "debuff", "val": 3, "label": "腐 毒 3"},
			{"kind": "attack", "val": 7, "hits": 2, "label": "双爪 7×2"},
			{"kind": "attack", "val": 16, "label": "噬魂 16"},
		],
	},
}

## 波次配置
const WAVES := [
	{"layer": "第 一 层 · 初 见", "chapter": "兰若寺 · 外院", "enemies": ["youhun", "shukui"]},
	{"layer": "第 二 层 · 执", "chapter": "兰若寺 · 佛堂", "enemies": ["laolao"]},
	{"layer": "第 三 层 · 解", "chapter": "兰若寺 · 妖窟", "enemies": ["benti"]},
]
