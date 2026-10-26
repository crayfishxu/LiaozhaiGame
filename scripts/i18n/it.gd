extends RefCounted

## ------------------------------------------------------------------
## Italiano
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "Fuoco d'anima",
	"w.grudge": "Rancore",
	"w.block": "Scudo",
	"w.poison": "Veleno",
	"w.weak": "Debolezza",
	"w.bind": "Legame",

	"ui.title": "LA BELLA DI LIAOZHAI",
	"ui.subtitle": "Prototipo di combattimento · Tempio di Lanruo",
	"ui.intro": "Ogni carta ha due facce: Apparenza e Vera Forma.\nSi gira dopo averla giocata: una carta, due modi d'uso.\n\nL'Apparenza difende e controlla; la Vera Forma colpisce più forte, a un prezzo.\nSubire danni accumula Rancore: più è profondo, più certe carte diventano forti.",
	"ui.enter": "ENTRA NEL SOGNO",

	"ui.layer1": "Strato I · Primo incontro",
	"ui.layer2": "Strato II · Ossessione",
	"ui.layer3": "Strato III · Liberazione",
	"ui.chapter1": "Tempio di Lanruo · Cortile esterno",
	"ui.chapter2": "Tempio di Lanruo · Sala di Buddha",
	"ui.chapter3": "Tempio di Lanruo · Tana dei demoni",

	"ui.pile_draw": "Ricordo",
	"ui.pile_discard": "Oblio",
	"ui.end_turn": "TERMINA TURNO",
	"ui.target_hint": "▸ SCEGLI UN NEMICO",
	"ui.side_xian": "APPARENZA",
	"ui.side_ben": "VERA FORMA",
	"ui.bound": "LEGATO",

	"ui.toast_busy": "I nemici agiscono…",
	"ui.toast_no_energy": "Volontà insufficiente · ne servono %d",
	"ui.toast_curse": "Le maledizioni non si possono giocare",
	"ui.toast_deselect": "Selezione annullata",
	"ui.toast_pick_first": "Prima una carta, poi un nemico",
	"ui.toast_lang": "Lingua cambiata",

	"ui.reward_title": "UN PENSIERO OTTENUTO",
	"ui.reward_sub": "Scegline uno per il mazzo",
	"ui.reward_skip": "NON PRENDERE NULLA",

	"ui.win_title": "IL NODO È SCIOLTO",
	"ui.win_sub": "La nebbia di Lanruo si è diradata.\nLei sta nella luce, a capo alto per la prima volta.\n\n«Grazie… per esserti ricordato di me.»",
	"ui.lose_title": "IL FUOCO D'ANIMA SI SPEGNE",
	"ui.lose_sub": "Sei indietreggiato.\nLei aspetta ancora — chi vorrà ascoltare.\n\n«L'ossessione di questa vita non si è potuta sciogliere.»",
	"ui.again": "GIOCA ANCORA",
	"ui.exit": "ESCI",

	"ui.pause_title": "IN PAUSA",
	"ui.pause_sub": "La nebbia di Lanruo ti attende ancora.",
	"ui.resume": "RIPRENDI",
	"ui.restart": "RICOMINCIA",
	"ui.quit_desktop": "ESCI AL DESKTOP",
	"ui.pause_hint": "Il tasto Indietro riapre questo menu",

	"ui.language": "LINGUA",
	"ui.lang_title": "SCEGLI LA LINGUA",
	"ui.lang_sub": "Si applica subito. La partita resta.",
	"ui.lang_back": "INDIETRO",

	"t.attack": "Ira",
	"t.defend": "Scudo",
	"t.skill": "Mente",
	"t.power": "Ossessione",
	"t.curse": "Maledizione",

	"e.youhun": "Anima Errante",
	"e.shukui": "Marionetta d'Albero",
	"e.laolao": "Nonna",
	"e.benti": "Nonna Demone d'Albero",

	"i.bite": "Morso",
	"i.branch": "Ramo",
	"i.wrap": "Avvolgere",
	"i.lash": "Frusta",
	"i.claw": "Artiglio",
	"i.cocoon": "Bozzolo",
	"i.drain": "Prosciugare",
	"i.tendril": "Miriade",
	"i.rot": "Marciume",
	"i.dual": "Doppio Artiglio",
	"i.souleat": "Mangiatrice di anime",

	"c.sushou": "Mano Pallida",
	"c.sushou.x": "Infligge 6 danni",
	"c.sushou.b": "Infligge 9 danni\n−2 fuoco d'anima",

	"c.zhusha": "Cinabro",
	"c.zhusha.x": "5 danni\nApplica 2 veleno",
	"c.zhusha.b": "8 danni\n3 veleno, −2 fuoco d'anima",

	"c.yeku": "Pianto Notturno",
	"c.yeku.x": "4 danni ×2",
	"c.yeku.b": "6 danni ×3\n−3 fuoco d'anima",

	"c.chansi": "Filo di Seta",
	"c.chansi.x": "3 danni\nLegame 1 turno",
	"c.chansi.b": "Danni pari al veleno\ndel bersaglio ×2",

	"c.yuannian": "Rancore",
	"c.yuannian.x": "6 danni\n+2 ogni 5 di rancore",
	"c.yuannian.b": "Consuma tutto il rancore\n2 danni per punto",

	"c.suyi": "Veste Pallida",
	"c.suyi.x": "Ottieni 8 scudo",
	"c.suyi.b": "−4 fuoco d'anima\n12 danni a tutti",

	"c.bosha": "Garza",
	"c.bosha.x": "Ottieni 6 scudo\nPesca 1 carta",
	"c.bosha.b": "Ottieni 3 scudo\n1 debolezza a tutti",

	"c.zhangbi": "Baluardo",
	"c.zhangbi.x": "Ottieni 12 scudo",
	"c.zhangbi.b": "Ottieni 6 scudo\nRifletti 4 questo turno",

	"c.youyuan": "Dolore",
	"c.youyuan.x": "Applica 3 veleno",
	"c.youyuan.b": "Applica 5 veleno\n−3 fuoco d'anima",

	"c.qingsi": "Filo Rosso",
	"c.qingsi.x": "Legame 1 turno",
	"c.qingsi.b": "Legame 2 turni",

	"c.yinlu": "Guida",
	"c.yinlu.x": "Pesca 2 carte",
	"c.yinlu.b": "Scarta 1 carta\nPesca 3 carte",

	"c.yi": "Ricordo",
	"c.yi.x": "Ottieni 2 volontà",
	"c.yi.b": "−3 fuoco d'anima\nOttieni 3 volontà",

	"c.dimei": "Sguardo Basso",
	"c.dimei.x": "Il prossimo attacco del bersaglio\nè ridotto di 3",
	"c.dimei.b": "Il bersaglio non agisce 1 turno\n−5 fuoco d'anima",

	"c.ku": "Pianto",
	"c.ku.x": "1 debolezza a tutti",
	"c.ku.b": "8 danni a tutti",

	"c.yuanyuan": "Avvolto dal Rancore",
	"c.yuanyuan.x": "A inizio turno\nottieni 2 rancore",
	"c.yuanyuan.b": "Subendo danni\n+2 rancore extra",

	"c.zhong": "Campana di Lanruo",
	"c.zhong.x": "Prima carta di ogni turno:\n2 scudo",
	"c.zhong.b": "Prima carta di ogni turno:\n4 danni casuali",

	"c.xiesui": "Maleficio",
	"c.xiesui.x": "Non giocabile\nIngombra la mano",
	"c.xiesui.b": "Non giocabile\nIngombra la mano",
}
