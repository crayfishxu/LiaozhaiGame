extends RefCounted

## ------------------------------------------------------------------
## 한국어
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "혼불",
	"w.grudge": "원한",
	"w.block": "장벽",
	"w.poison": "독",
	"w.weak": "약화",
	"w.bind": "속박",

	"ui.title": "요재미인",
	"ui.subtitle": "전투 프로토타입 · 난야사",
	"ui.intro": "모든 카드에는 「현상」과 「본상」 두 면이 있다.\n내면 자동으로 뒤집힌다 —— 한 장으로 두 가지 사용법.\n\n현상은 방어와 안정, 본상은 폭발력과 그 대가.\n피해를 받으면 「원한」이 쌓이고, 깊을수록 강해지는 카드도 있다.",
	"ui.enter": "입몽",

	"ui.layer1": "제1층 · 첫 만남",
	"ui.layer2": "제2층 · 집착",
	"ui.layer3": "제3층 · 해탈",
	"ui.chapter1": "난야사 · 외원",
	"ui.chapter2": "난야사 · 불당",
	"ui.chapter3": "난야사 · 요굴",

	"ui.pile_draw": "기억",
	"ui.pile_discard": "망각",
	"ui.end_turn": "턴 종료",
	"ui.target_hint": "▸ 적을 선택",
	"ui.side_xian": "현상",
	"ui.side_ben": "본상",
	"ui.bound": "속박",

	"ui.toast_busy": "적이 움직이는 중…",
	"ui.toast_no_energy": "의지 부족 · %d 필요",
	"ui.toast_curse": "저주 카드는 낼 수 없다",
	"ui.toast_deselect": "선택이 해제되었다",
	"ui.toast_pick_first": "먼저 카드를 고르고 적을 탭",
	"ui.toast_lang": "언어가 변경되었다",

	"ui.reward_title": "정념을 얻다",
	"ui.reward_sub": "한 장을 골라 덱에 넣으세요",
	"ui.reward_skip": "받지 않기",

	"ui.win_title": "마음의 업이 풀렸다",
	"ui.win_sub": "난야사의 안개가 걷혔다.\n그녀는 빛 속에 서서, 처음으로 고개를 들었다.\n\n\"기억해 주어서…… 고마워.\"",
	"ui.lose_title": "혼불이 꺼져간다",
	"ui.lose_sub": "당신은 물러났다.\n그녀는 아직 기다린다 —— 다음에 귀 기울일 사람을.\n\n『이번 생의 집착은 풀지 못했다.』",
	"ui.again": "다시 시작",
	"ui.exit": "종료",

	"ui.pause_title": "일시 정지",
	"ui.pause_sub": "난야사의 안개가 아직 기다린다.",
	"ui.resume": "계속하기",
	"ui.restart": "처음부터",
	"ui.quit_desktop": "바탕화면으로 나가기",
	"ui.pause_hint": "뒤로 가기 키로 이 메뉴를 다시 열 수 있다",

	"ui.language": "언어",
	"ui.lang_title": "언어 선택",
	"ui.lang_sub": "즉시 적용됩니다. 진행 상황은 유지됩니다.",
	"ui.lang_back": "돌아가기",

	"t.attack": "분노",
	"t.defend": "장벽",
	"t.skill": "염원",
	"t.power": "집착",
	"t.curse": "저주",

	"e.youhun": "유혼",
	"e.shukui": "수괴",
	"e.laolao": "노파",
	"e.benti": "수요노파",

	"i.bite": "물기",
	"i.branch": "가지",
	"i.wrap": "휘감",
	"i.lash": "채찍",
	"i.claw": "발톱",
	"i.cocoon": "고치",
	"i.drain": "흡수",
	"i.tendril": "만사",
	"i.rot": "부패",
	"i.dual": "쌍발톱",
	"i.souleat": "혼식",

	"c.sushou": "여린 손",
	"c.sushou.x": "6 피해",
	"c.sushou.b": "9 피해\n혼불 2 소모",

	"c.zhusha": "주사",
	"c.zhusha.x": "5 피해\n독 2 부여",
	"c.zhusha.b": "8 피해\n독 3 부여, 2 소모",

	"c.yeku": "밤의 곡",
	"c.yeku.x": "4 피해 ×2",
	"c.yeku.b": "6 피해 ×3\n혼불 3 소모",

	"c.chansi": "얽힌 실",
	"c.chansi.x": "3 피해\n1턴 속박",
	"c.chansi.b": "대상의 독 ×2 만큼\n피해를 준다",

	"c.yuannian": "원념",
	"c.yuannian.x": "6 피해\n원한 5당 +2",
	"c.yuannian.b": "원한을 모두 소모\n1당 2 피해",

	"c.suyi": "여린 옷",
	"c.suyi.x": "장벽 8 획득",
	"c.suyi.b": "혼불 4 소모\n모두에게 12 피해",

	"c.bosha": "얇은 사",
	"c.bosha.x": "장벽 6 획득\n1장 드로우",
	"c.bosha.b": "장벽 3 획득\n모두에게 약화 1",

	"c.zhangbi": "장벽",
	"c.zhangbi.x": "장벽 12 획득",
	"c.zhangbi.b": "장벽 6 획득\n이번 턴 반사 4",

	"c.youyuan": "원망",
	"c.youyuan.x": "독 3 부여",
	"c.youyuan.b": "독 5 부여\n혼불 3 소모",

	"c.qingsi": "정의 실",
	"c.qingsi.x": "1턴 속박",
	"c.qingsi.b": "2턴 속박",

	"c.yinlu": "길잡이",
	"c.yinlu.x": "2장 드로우",
	"c.yinlu.b": "1장 버리기\n3장 드로우",

	"c.yi": "기억",
	"c.yi.x": "의지 2 획득",
	"c.yi.b": "혼불 3 소모\n의지 3 획득",

	"c.dimei": "내린 눈썹",
	"c.dimei.x": "대상의 다음 공격\n3 감소",
	"c.dimei.b": "대상 1턴 행동 불가\n혼불 5 소모",

	"c.ku": "울음",
	"c.ku.x": "모두에게 약화 1",
	"c.ku.b": "모두에게 8 피해",

	"c.yuanyuan": "원한이 감돌다",
	"c.yuanyuan.x": "턴 시작 시\n원한 2 획득",
	"c.yuanyuan.b": "피해를 받을 때\n원한 2 추가 획득",

	"c.zhong": "난야사의 종소리",
	"c.zhong.x": "매 턴 첫 카드로\n장벽 2 획득",
	"c.zhong.b": "매 턴 첫 카드로\n무작위 4 피해",

	"c.xiesui": "사귀",
	"c.xiesui.x": "낼 수 없음\n손패를 차지",
	"c.xiesui.b": "낼 수 없음\n손패를 차지",
}
