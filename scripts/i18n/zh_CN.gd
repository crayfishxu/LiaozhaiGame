extends RefCounted

## ------------------------------------------------------------------
## 简体中文 —— 源语言
## 其它语种以本表为基准，缺条目时回退到这里
## ------------------------------------------------------------------

const TEXT := {
	# ---- 通用词 ----
	"w.hp": "魂火",
	"w.grudge": "怨气",
	"w.block": "障",
	"w.poison": "毒",
	"w.weak": "弱",
	"w.bind": "缠",

	# ---- 开场 ----
	"ui.title": "聊 斋 美 人",
	"ui.subtitle": "战斗原型 · 兰若寺",
	"ui.intro": "每张卡牌有「显相」与「本相」两面。\n打出后自动翻面 —— 同一张牌，两套用法。\n\n显相偏防御与稳定，本相偏爆发但有代价。\n受伤积累「怨气」，怨气越深，某些牌越强。",
	"ui.enter": "入 梦",

	# ---- 关卡 ----
	"ui.layer1": "第 一 层 · 初 见",
	"ui.layer2": "第 二 层 · 执",
	"ui.layer3": "第 三 层 · 解",
	"ui.chapter1": "兰若寺 · 外院",
	"ui.chapter2": "兰若寺 · 佛堂",
	"ui.chapter3": "兰若寺 · 妖窟",

	# ---- 战斗 ----
	"ui.pile_draw": "忆",
	"ui.pile_discard": "忘",
	"ui.end_turn": "结 束 回 合",
	"ui.target_hint": "▸ 点 一 个 敌 人",
	"ui.side_xian": "显相",
	"ui.side_ben": "本相",
	"ui.bound": "缠 缚",

	# ---- 操作提示 ----
	"ui.toast_busy": "敌人行动中…",
	"ui.toast_no_energy": "心力不足 · 需要 %d 点",
	"ui.toast_curse": "祟 牌 无 法 打 出",
	"ui.toast_deselect": "已取消选择",
	"ui.toast_pick_first": "先点一张牌，再点敌人",
	"ui.toast_lang": "语言已切换",

	# ---- 战后奖励 ----
	"ui.reward_title": "拾 得 情 念",
	"ui.reward_sub": "选一张，入你的牌组",
	"ui.reward_skip": "不 取",

	# ---- 结算 ----
	"ui.win_title": "心 劫 已 解",
	"ui.win_sub": "兰若寺的雾散了。\n她站在光里，第一次没有低着头。\n\n「谢谢你……记得我。」",
	"ui.lose_title": "魂 火 将 熄",
	"ui.lose_sub": "你退了出来。\n她还在等 —— 等下一个愿意听的人。\n\n『这一世的执念，没能解开。』",
	"ui.again": "再 来 一 次",
	"ui.exit": "退 出",

	# ---- 暂停菜单 ----
	"ui.pause_title": "暂 停",
	"ui.pause_sub": "兰若寺的雾，还在等你。",
	"ui.resume": "继 续 游 戏",
	"ui.restart": "重 新 开 始",
	"ui.quit_desktop": "退 出 到 桌 面",
	"ui.pause_hint": "返回键可再次呼出本菜单",

	# ---- 语言 ----
	"ui.language": "语 言",
	"ui.lang_title": "选 择 语 言",
	"ui.lang_sub": "切换后立即生效，当前局面不会丢失",
	"ui.lang_back": "返 回",

	# ---- 卡牌类型 ----
	"t.attack": "嗔",
	"t.defend": "障",
	"t.skill": "念",
	"t.power": "执",
	"t.curse": "祟",

	# ---- 敌人 ----
	"e.youhun": "游魂",
	"e.shukui": "树傀",
	"e.laolao": "姥姥",
	"e.benti": "树妖姥姥",

	# ---- 意图动词 ----
	"i.bite": "噬",
	"i.branch": "枝",
	"i.wrap": "缠",
	"i.lash": "鞭",
	"i.claw": "爪",
	"i.cocoon": "茧",
	"i.drain": "吸",
	"i.tendril": "万丝",
	"i.rot": "腐",
	"i.dual": "双爪",
	"i.souleat": "噬魂",

	# ---- 卡牌 ----
	"c.sushou": "素手",
	"c.sushou.x": "造成 6 点伤害",
	"c.sushou.b": "造成 9 点伤害\n自损 2 魂火",

	"c.zhusha": "朱砂",
	"c.zhusha.x": "造成 5 点伤害\n施 2 层祟毒",
	"c.zhusha.b": "造成 8 点伤害\n施 3 层祟毒，自损 2",

	"c.yeku": "夜哭",
	"c.yeku.x": "造成 4 点伤害 2 次",
	"c.yeku.b": "造成 6 点伤害 3 次\n自损 3 魂火",

	"c.chansi": "缠丝",
	"c.chansi.x": "造成 3 点伤害\n缠绕 1 回合",
	"c.chansi.b": "造成目标祟毒层数 ×2\n的伤害",

	"c.yuannian": "怨念",
	"c.yuannian.x": "造成 6 点伤害\n每 5 点怨气 +2",
	"c.yuannian.b": "耗尽全部怨气\n每点造成 2 点伤害",

	"c.suyi": "素衣",
	"c.suyi.x": "获得 8 点障",
	"c.suyi.b": "失去 4 点魂火\n对全体造成 12 点伤害",

	"c.bosha": "薄纱",
	"c.bosha.x": "获得 6 点障\n抽 1 张牌",
	"c.bosha.b": "获得 3 点障\n全体施 1 层祟弱",

	"c.zhangbi": "障壁",
	"c.zhangbi.x": "获得 12 点障",
	"c.zhangbi.b": "获得 6 点障\n本回合反伤 4",

	"c.youyuan": "幽怨",
	"c.youyuan.x": "施加 3 层祟毒",
	"c.youyuan.b": "施加 5 层祟毒\n自损 3 魂火",

	"c.qingsi": "情丝",
	"c.qingsi.x": "缠绕 1 回合",
	"c.qingsi.b": "缠绕 2 回合",

	"c.yinlu": "引路",
	"c.yinlu.x": "抽 2 张牌",
	"c.yinlu.b": "弃 1 张牌\n抽 3 张牌",

	"c.yi": "忆",
	"c.yi.x": "获得 2 点心力",
	"c.yi.b": "失去 3 点魂火\n获得 3 点心力",

	"c.dimei": "低眉",
	"c.dimei.x": "目标下回合\n攻击降低 3 点",
	"c.dimei.b": "目标无法行动 1 回合\n自损 5 魂火",

	"c.ku": "哭",
	"c.ku.x": "全体施加 1 层祟弱",
	"c.ku.b": "对全体造成 8 点伤害",

	"c.yuanyuan": "怨气缠身",
	"c.yuanyuan.x": "每回合开始\n获得 2 点怨气",
	"c.yuanyuan.b": "受到伤害时\n额外获得 2 点怨气",

	"c.zhong": "兰若钟声",
	"c.zhong.x": "每回合首次出牌\n获得 2 点障",
	"c.zhong.b": "每回合首次出牌\n随机造成 4 点伤害",

	"c.xiesui": "邪祟",
	"c.xiesui.x": "无法打出\n占据手牌",
	"c.xiesui.b": "无法打出\n占据手牌",
}
