extends RefCounted

## ------------------------------------------------------------------
## Português (Brasil)
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "Alma",
	"w.grudge": "Rancor",
	"w.block": "Barreira",
	"w.poison": "Veneno",
	"w.weak": "Fraqueza",
	"w.bind": "Atadura",

	"ui.title": "A BELA DE LIAOZHAI",
	"ui.subtitle": "Protótipo de combate · Templo Lanruo",
	"ui.intro": "Toda carta tem duas faces: Aparência e Forma Real.\nEla vira ao ser jogada: uma carta, dois modos de usar.\n\nA Aparência defende e controla; a Forma Real bate mais forte a um preço.\nLevar dano acumula Rancor: quanto mais fundo, mais fortes ficam certas cartas.",
	"ui.enter": "ENTRAR NO SONHO",

	"ui.layer1": "Camada I · Primeiro Encontro",
	"ui.layer2": "Camada II · Obsessão",
	"ui.layer3": "Camada III · Libertação",
	"ui.chapter1": "Templo Lanruo · Pátio Externo",
	"ui.chapter2": "Templo Lanruo · Salão de Buda",
	"ui.chapter3": "Templo Lanruo · Covil Demoníaco",

	"ui.pile_draw": "Lembrança",
	"ui.pile_discard": "Esquecimento",
	"ui.end_turn": "ENCERRAR TURNO",
	"ui.target_hint": "▸ ESCOLHA UM INIMIGO",
	"ui.side_xian": "APARÊNCIA",
	"ui.side_ben": "FORMA REAL",
	"ui.bound": "ATADO",

	"ui.toast_busy": "Os inimigos estão agindo…",
	"ui.toast_no_energy": "Vontade insuficiente · faltam %d",
	"ui.toast_curse": "Cartas de maldição não podem ser jogadas",
	"ui.toast_deselect": "Seleção cancelada",
	"ui.toast_pick_first": "Escolha uma carta e depois um inimigo",
	"ui.toast_lang": "Idioma alterado",

	"ui.reward_title": "UM PENSAMENTO OBTIDO",
	"ui.reward_sub": "Escolha uma para o seu baralho",
	"ui.reward_skip": "NÃO PEGAR NENHUMA",

	"ui.win_title": "O NÓ FOI DESFEITO",
	"ui.win_sub": "A névoa de Lanruo se dissipou.\nEla está de pé na luz, de cabeça erguida pela primeira vez.\n\n«Obrigada… por lembrar de mim.»",
	"ui.lose_title": "A ALMA SE APAGA",
	"ui.lose_sub": "Você recuou.\nEla ainda espera — por quem quiser escutar.\n\n«A obsessão desta vida não pôde ser desfeita.»",
	"ui.again": "JOGAR NOVAMENTE",
	"ui.exit": "SAIR",

	"ui.pause_title": "PAUSADO",
	"ui.pause_sub": "A névoa de Lanruo ainda espera.",
	"ui.resume": "CONTINUAR",
	"ui.restart": "RECOMEÇAR",
	"ui.quit_desktop": "SAIR PARA A ÁREA DE TRABALHO",
	"ui.pause_hint": "Pressione Voltar para reabrir este menu",

	"ui.language": "IDIOMA",
	"ui.lang_title": "ESCOLHER IDIOMA",
	"ui.lang_sub": "Aplica na hora. Sua partida é mantida.",
	"ui.lang_back": "VOLTAR",

	"t.attack": "Ira",
	"t.defend": "Barreira",
	"t.skill": "Mente",
	"t.power": "Obsessão",
	"t.curse": "Maldição",

	"e.youhun": "Alma Errante",
	"e.shukui": "Marionete de Árvore",
	"e.laolao": "Avó",
	"e.benti": "Avó Demônio de Árvore",

	"i.bite": "Mordida",
	"i.branch": "Galho",
	"i.wrap": "Enroscar",
	"i.lash": "Chicote",
	"i.claw": "Garra",
	"i.cocoon": "Casulo",
	"i.drain": "Drenar",
	"i.tendril": "Miríade",
	"i.rot": "Apodrecer",
	"i.dual": "Garra Dupla",
	"i.souleat": "Devaalmas",

	"c.sushou": "Mão Pálida",
	"c.sushou.x": "Causa 6 de dano",
	"c.sushou.b": "Causa 9 de dano\nPerde 2 de alma",

	"c.zhusha": "Cinábrio",
	"c.zhusha.x": "Causa 5 de dano\nAplica 2 de veneno",
	"c.zhusha.b": "Causa 8 de dano\nAplica 3 de veneno, −2 alma",

	"c.yeku": "Choro Noturno",
	"c.yeku.x": "Causa 4 de dano 2 vezes",
	"c.yeku.b": "Causa 6 de dano 3 vezes\nPerde 3 de alma",

	"c.chansi": "Fio de Seda",
	"c.chansi.x": "Causa 3 de dano\nAtadura 1 turno",
	"c.chansi.b": "Dano igual ao veneno\ndo alvo ×2",

	"c.yuannian": "Rancor",
	"c.yuannian.x": "Causa 6 de dano\n+2 a cada 5 de rancor",
	"c.yuannian.b": "Consome todo o rancor\n2 de dano por ponto",

	"c.suyi": "Túnica Pálida",
	"c.suyi.x": "Ganha 8 de barreira",
	"c.suyi.b": "Perde 4 de alma\n12 de dano em todos",

	"c.bosha": "Gaze",
	"c.bosha.x": "Ganha 6 de barreira\nCompra 1 carta",
	"c.bosha.b": "Ganha 3 de barreira\n1 de fraqueza em todos",

	"c.zhangbi": "Baluarte",
	"c.zhangbi.x": "Ganha 12 de barreira",
	"c.zhangbi.b": "Ganha 6 de barreira\nReflete 4 neste turno",

	"c.youyuan": "Mágoa",
	"c.youyuan.x": "Aplica 3 de veneno",
	"c.youyuan.b": "Aplica 5 de veneno\nPerde 3 de alma",

	"c.qingsi": "Fio Vermelho",
	"c.qingsi.x": "Atadura 1 turno",
	"c.qingsi.b": "Atadura 2 turnos",

	"c.yinlu": "Orientação",
	"c.yinlu.x": "Compra 2 cartas",
	"c.yinlu.b": "Descarta 1 carta\nCompra 3 cartas",

	"c.yi": "Lembrança",
	"c.yi.x": "Ganha 2 de vontade",
	"c.yi.b": "Perde 3 de alma\nGanha 3 de vontade",

	"c.dimei": "Olhar Baixo",
	"c.dimei.x": "O próximo ataque do alvo\né reduzido em 3",
	"c.dimei.b": "O alvo não age por 1 turno\nPerde 5 de alma",

	"c.ku": "Choro",
	"c.ku.x": "1 de fraqueza em todos",
	"c.ku.b": "8 de dano em todos",

	"c.yuanyuan": "Envolto em Rancor",
	"c.yuanyuan.x": "No início do turno\nganha 2 de rancor",
	"c.yuanyuan.b": "Ao receber dano\nganha 2 de rancor extra",

	"c.zhong": "Sino de Lanruo",
	"c.zhong.x": "Primeira carta de cada turno:\n2 de barreira",
	"c.zhong.b": "Primeira carta de cada turno:\n4 de dano aleatório",

	"c.xiesui": "Maldição",
	"c.xiesui.x": "Não pode ser jogada\nOcupa a mão",
	"c.xiesui.b": "Não pode ser jogada\nOcupa a mão",
}
