extends RefCounted

## ------------------------------------------------------------------
## English
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "Soulfire",
	"w.grudge": "Grudge",
	"w.block": "Ward",
	"w.poison": "Venom",
	"w.weak": "Weak",
	"w.bind": "Bind",

	"ui.title": "LIAOZHAI BEAUTY",
	"ui.subtitle": "Combat prototype · Lanruo Temple",
	"ui.intro": "Every card has two faces — Guise and True Form.\nIt flips once played: one card, two ways to use it.\n\nGuise leans toward defense and control; True Form strikes harder at a price.\nTaking damage builds Grudge — the deeper it runs, the stronger some cards become.",
	"ui.enter": "ENTER THE DREAM",

	"ui.layer1": "Layer I · First Sight",
	"ui.layer2": "Layer II · Obsession",
	"ui.layer3": "Layer III · Release",
	"ui.chapter1": "Lanruo Temple · Outer Court",
	"ui.chapter2": "Lanruo Temple · Hall of Buddha",
	"ui.chapter3": "Lanruo Temple · Demon Den",

	"ui.pile_draw": "Recall",
	"ui.pile_discard": "Forget",
	"ui.end_turn": "END TURN",
	"ui.target_hint": "▸ CHOOSE A FOE",
	"ui.side_xian": "GUISE",
	"ui.side_ben": "TRUE FORM",
	"ui.bound": "BOUND",

	"ui.toast_busy": "Enemies are acting…",
	"ui.toast_no_energy": "Not enough Will · need %d",
	"ui.toast_curse": "Curse cards cannot be played",
	"ui.toast_deselect": "Selection cleared",
	"ui.toast_pick_first": "Pick a card first, then a foe",
	"ui.toast_lang": "Language changed",

	"ui.reward_title": "A THOUGHT GAINED",
	"ui.reward_sub": "Choose one for your deck",
	"ui.reward_skip": "TAKE NONE",

	"ui.win_title": "THE KNOT IS UNTIED",
	"ui.win_sub": "The mist over Lanruo has thinned.\nShe stands in the light, head lifted for the first time.\n\n\"Thank you… for remembering me.\"",
	"ui.lose_title": "THE SOULFIRE DIMS",
	"ui.lose_sub": "You step back out.\nShe is still waiting — for the next one willing to listen.\n\n\"This life's obsession could not be undone.\"",
	"ui.again": "PLAY AGAIN",
	"ui.exit": "EXIT",

	"ui.pause_title": "PAUSED",
	"ui.pause_sub": "The mist of Lanruo is still waiting.",
	"ui.resume": "RESUME",
	"ui.restart": "RESTART",
	"ui.quit_desktop": "QUIT TO DESKTOP",
	"ui.pause_hint": "Press Back to reopen this menu",

	"ui.language": "LANGUAGE",
	"ui.lang_title": "SELECT LANGUAGE",
	"ui.lang_sub": "Applies at once. Your run is kept.",
	"ui.lang_back": "BACK",

	"t.attack": "Wrath",
	"t.defend": "Ward",
	"t.skill": "Mind",
	"t.power": "Obsession",
	"t.curse": "Curse",

	"e.youhun": "Wandering Soul",
	"e.shukui": "Tree Puppet",
	"e.laolao": "Granny",
	"e.benti": "Tree Demon Granny",

	"i.bite": "Bite",
	"i.branch": "Branch",
	"i.wrap": "Coil",
	"i.lash": "Lash",
	"i.claw": "Claw",
	"i.cocoon": "Cocoon",
	"i.drain": "Drain",
	"i.tendril": "Myriad",
	"i.rot": "Rot",
	"i.dual": "Twin Claw",
	"i.souleat": "Soul Eater",

	"c.sushou": "Pale Hand",
	"c.sushou.x": "Deal 6 damage",
	"c.sushou.b": "Deal 9 damage\nLose 2 Soulfire",

	"c.zhusha": "Cinnabar",
	"c.zhusha.x": "Deal 5 damage\nApply 2 Venom",
	"c.zhusha.b": "Deal 8 damage\nApply 3 Venom, lose 2",

	"c.yeku": "Night Weep",
	"c.yeku.x": "Deal 4 damage twice",
	"c.yeku.b": "Deal 6 damage 3 times\nLose 3 Soulfire",

	"c.chansi": "Snare",
	"c.chansi.x": "Deal 3 damage\nBind 1 turn",
	"c.chansi.b": "Deal damage equal to\ntarget's Venom ×2",

	"c.yuannian": "Grudge",
	"c.yuannian.x": "Deal 6 damage\n+2 per 5 Grudge",
	"c.yuannian.b": "Spend all Grudge\nDeal 2 damage per point",

	"c.suyi": "Pale Robe",
	"c.suyi.x": "Gain 8 Ward",
	"c.suyi.b": "Lose 4 Soulfire\nDeal 12 damage to all",

	"c.bosha": "Gauze",
	"c.bosha.x": "Gain 6 Ward\nDraw 1 card",
	"c.bosha.b": "Gain 3 Ward\nApply 1 Weak to all",

	"c.zhangbi": "Bulwark",
	"c.zhangbi.x": "Gain 12 Ward",
	"c.zhangbi.b": "Gain 6 Ward\nReflect 4 this turn",

	"c.youyuan": "Sorrow",
	"c.youyuan.x": "Apply 3 Venom",
	"c.youyuan.b": "Apply 5 Venom\nLose 3 Soulfire",

	"c.qingsi": "Red Thread",
	"c.qingsi.x": "Bind 1 turn",
	"c.qingsi.b": "Bind 2 turns",

	"c.yinlu": "Guidance",
	"c.yinlu.x": "Draw 2 cards",
	"c.yinlu.b": "Discard 1 card\nDraw 3 cards",

	"c.yi": "Recall",
	"c.yi.x": "Gain 2 Will",
	"c.yi.b": "Lose 3 Soulfire\nGain 3 Will",

	"c.dimei": "Downcast",
	"c.dimei.x": "Target's next attack\nis reduced by 3",
	"c.dimei.b": "Target cannot act 1 turn\nLose 5 Soulfire",

	"c.ku": "Weeping",
	"c.ku.x": "Apply 1 Weak to all",
	"c.ku.b": "Deal 8 damage to all",

	"c.yuanyuan": "Enshrouded",
	"c.yuanyuan.x": "At turn start\ngain 2 Grudge",
	"c.yuanyuan.b": "When damaged\ngain 2 extra Grudge",

	"c.zhong": "Temple Bell",
	"c.zhong.x": "First card each turn\ngrants 2 Ward",
	"c.zhong.b": "First card each turn\ndeals 4 random damage",

	"c.xiesui": "Hex",
	"c.xiesui.x": "Cannot be played\nClogs your hand",
	"c.xiesui.b": "Cannot be played\nClogs your hand",
}
