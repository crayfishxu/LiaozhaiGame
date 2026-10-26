extends RefCounted

## ------------------------------------------------------------------
## 日本語
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "魂火",
	"w.grudge": "怨気",
	"w.block": "障",
	"w.poison": "毒",
	"w.weak": "弱",
	"w.bind": "縛",

	"ui.title": "聊斎美人",
	"ui.subtitle": "戦闘プロトタイプ · 蘭若寺",
	"ui.intro": "カードには「顕相」と「本相」の二面がある。\n出したあと自動で裏返る —— 一枚で二通りの使い方。\n\n顕相は防御と安定、本相は爆発力と引き換えの代償。\n被弾すると「怨気」が溜まり、深いほど強くなるカードもある。",
	"ui.enter": "入夢",

	"ui.layer1": "第一層 · 初見",
	"ui.layer2": "第二層 · 執",
	"ui.layer3": "第三層 · 解",
	"ui.chapter1": "蘭若寺 · 外院",
	"ui.chapter2": "蘭若寺 · 仏堂",
	"ui.chapter3": "蘭若寺 · 妖窟",

	"ui.pile_draw": "憶",
	"ui.pile_discard": "忘",
	"ui.end_turn": "ターン終了",
	"ui.target_hint": "▸ 敵を選ぶ",
	"ui.side_xian": "顕相",
	"ui.side_ben": "本相",
	"ui.bound": "縛",

	"ui.toast_busy": "敵の行動中…",
	"ui.toast_no_energy": "心力不足 · %d 必要",
	"ui.toast_curse": "祟カードは出せない",
	"ui.toast_deselect": "選択を解除した",
	"ui.toast_pick_first": "先にカードを選び、敵をタップ",
	"ui.toast_lang": "言語を切り替えた",

	"ui.reward_title": "情念を得た",
	"ui.reward_sub": "一枚選んでデッキに入れる",
	"ui.reward_skip": "受け取らない",

	"ui.win_title": "心の劫は解けた",
	"ui.win_sub": "蘭若寺の霧が晴れた。\n彼女は光の中に立ち、はじめて顔を上げた。\n\n「ありがとう……覚えていてくれて。」",
	"ui.lose_title": "魂火が消えゆく",
	"ui.lose_sub": "あなたは退がった。\n彼女はまだ待っている —— 次に耳を貸す人を。\n\n『この世の執念は、解けなかった。』",
	"ui.again": "もう一度",
	"ui.exit": "終了",

	"ui.pause_title": "一時停止",
	"ui.pause_sub": "蘭若寺の霧は、まだ待っている。",
	"ui.resume": "再開",
	"ui.restart": "最初から",
	"ui.quit_desktop": "デスクトップへ戻る",
	"ui.pause_hint": "戻るキーでこのメニューを再表示",

	"ui.language": "言語",
	"ui.lang_title": "言語を選択",
	"ui.lang_sub": "すぐに反映されます。進行状況は保持されます。",
	"ui.lang_back": "戻る",

	"t.attack": "嗔",
	"t.defend": "障",
	"t.skill": "念",
	"t.power": "執",
	"t.curse": "祟",

	"e.youhun": "遊魂",
	"e.shukui": "樹傀",
	"e.laolao": "姥姥",
	"e.benti": "樹妖姥姥",

	"i.bite": "噬",
	"i.branch": "枝",
	"i.wrap": "纏",
	"i.lash": "鞭",
	"i.claw": "爪",
	"i.cocoon": "繭",
	"i.drain": "吸",
	"i.tendril": "万糸",
	"i.rot": "腐",
	"i.dual": "双爪",
	"i.souleat": "噬魂",

	"c.sushou": "素手",
	"c.sushou.x": "6 ダメージ",
	"c.sushou.b": "9 ダメージ\n魂火 2 消耗",

	"c.zhusha": "朱砂",
	"c.zhusha.x": "5 ダメージ\n祟毒 2 付与",
	"c.zhusha.b": "8 ダメージ\n祟毒 3 付与、2 消耗",

	"c.yeku": "夜哭",
	"c.yeku.x": "4 ダメージ ×2",
	"c.yeku.b": "6 ダメージ ×3\n魂火 3 消耗",

	"c.chansi": "纏糸",
	"c.chansi.x": "3 ダメージ\n1 ターン縛る",
	"c.chansi.b": "対象の祟毒 ×2 の\nダメージを与える",

	"c.yuannian": "怨念",
	"c.yuannian.x": "6 ダメージ\n怨気 5 ごとに +2",
	"c.yuannian.b": "怨気をすべて消費\n1 ごとに 2 ダメージ",

	"c.suyi": "素衣",
	"c.suyi.x": "障 8 獲得",
	"c.suyi.b": "魂火 4 消耗\n全体に 12 ダメージ",

	"c.bosha": "薄紗",
	"c.bosha.x": "障 6 獲得\n1 枚引く",
	"c.bosha.b": "障 3 獲得\n全体に祟弱 1 付与",

	"c.zhangbi": "障壁",
	"c.zhangbi.x": "障 12 獲得",
	"c.zhangbi.b": "障 6 獲得\nこのターン反撃 4",

	"c.youyuan": "幽怨",
	"c.youyuan.x": "祟毒 3 付与",
	"c.youyuan.b": "祟毒 5 付与\n魂火 3 消耗",

	"c.qingsi": "情糸",
	"c.qingsi.x": "1 ターン縛る",
	"c.qingsi.b": "2 ターン縛る",

	"c.yinlu": "引路",
	"c.yinlu.x": "2 枚引く",
	"c.yinlu.b": "1 枚捨てる\n3 枚引く",

	"c.yi": "憶",
	"c.yi.x": "心力 2 獲得",
	"c.yi.b": "魂火 3 消耗\n心力 3 獲得",

	"c.dimei": "低眉",
	"c.dimei.x": "対象の次の攻撃を\n3 減少させる",
	"c.dimei.b": "対象は 1 ターン行動不能\n魂火 5 消耗",

	"c.ku": "哭",
	"c.ku.x": "全体に祟弱 1 付与",
	"c.ku.b": "全体に 8 ダメージ",

	"c.yuanyuan": "怨気纏身",
	"c.yuanyuan.x": "ターン開始時\n怨気 2 獲得",
	"c.yuanyuan.b": "被ダメージ時\n怨気を追加で 2 獲得",

	"c.zhong": "蘭若鐘声",
	"c.zhong.x": "毎ターン最初のカードで\n障 2 獲得",
	"c.zhong.b": "毎ターン最初のカードで\nランダムに 4 ダメージ",

	"c.xiesui": "邪祟",
	"c.xiesui.x": "出せない\n手札を圧迫する",
	"c.xiesui.b": "出せない\n手札を圧迫する",
}
