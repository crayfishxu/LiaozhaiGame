extends RefCounted

## ------------------------------------------------------------------
## Español
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "Alma",
	"w.grudge": "Rencor",
	"w.block": "Resguardo",
	"w.poison": "Veneno",
	"w.weak": "Debilidad",
	"w.bind": "Atadura",

	"ui.title": "LA BELLA DE LIAOZHAI",
	"ui.subtitle": "Prototipo de combate · Templo Lanruo",
	"ui.intro": "Cada carta tiene dos caras: Apariencia y Forma real.\nSe voltea al jugarla: una carta, dos maneras de usarla.\n\nLa Apariencia defiende y controla; la Forma real golpea más fuerte a cambio de un precio.\nRecibir daño acumula Rencor: cuanto más profundo, más fuertes se vuelven ciertas cartas.",
	"ui.enter": "ENTRAR AL SUEÑO",

	"ui.layer1": "Capa I · Primer encuentro",
	"ui.layer2": "Capa II · Obsesión",
	"ui.layer3": "Capa III · Liberación",
	"ui.chapter1": "Templo Lanruo · Patio exterior",
	"ui.chapter2": "Templo Lanruo · Sala de Buda",
	"ui.chapter3": "Templo Lanruo · Guarida demoníaca",

	"ui.pile_draw": "Recuerdo",
	"ui.pile_discard": "Olvido",
	"ui.end_turn": "TERMINAR TURNO",
	"ui.target_hint": "▸ ELIGE UN ENEMIGO",
	"ui.side_xian": "APARIENCIA",
	"ui.side_ben": "FORMA REAL",
	"ui.bound": "ATADO",

	"ui.toast_busy": "Los enemigos actúan…",
	"ui.toast_no_energy": "Voluntad insuficiente · faltan %d",
	"ui.toast_curse": "Las maldiciones no se pueden jugar",
	"ui.toast_deselect": "Selección cancelada",
	"ui.toast_pick_first": "Elige una carta y luego un enemigo",
	"ui.toast_lang": "Idioma cambiado",

	"ui.reward_title": "UN PENSAMIENTO OBTENIDO",
	"ui.reward_sub": "Elige una para tu mazo",
	"ui.reward_skip": "NO TOMAR NINGUNA",

	"ui.win_title": "EL NUDO SE HA DESATADO",
	"ui.win_sub": "La niebla de Lanruo se ha disipado.\nElla está de pie en la luz, con la cabeza alta por primera vez.\n\n«Gracias… por acordarte de mí.»",
	"ui.lose_title": "EL ALMA SE APAGA",
	"ui.lose_sub": "Has retrocedido.\nElla sigue esperando — a quien quiera escuchar.\n\n«La obsesión de esta vida no pudo deshacerse.»",
	"ui.again": "JUGAR OTRA VEZ",
	"ui.exit": "SALIR",

	"ui.pause_title": "EN PAUSA",
	"ui.pause_sub": "La niebla de Lanruo aún te espera.",
	"ui.resume": "CONTINUAR",
	"ui.restart": "REINICIAR",
	"ui.quit_desktop": "SALIR AL ESCRITORIO",
	"ui.pause_hint": "Pulsa Atrás para reabrir este menú",

	"ui.language": "IDIOMA",
	"ui.lang_title": "ELEGIR IDIOMA",
	"ui.lang_sub": "Se aplica al instante. Tu partida se conserva.",
	"ui.lang_back": "VOLVER",

	"t.attack": "Ira",
	"t.defend": "Resguardo",
	"t.skill": "Mente",
	"t.power": "Obsesión",
	"t.curse": "Maldición",

	"e.youhun": "Alma Errante",
	"e.shukui": "Títere de Árbol",
	"e.laolao": "Abuela",
	"e.benti": "Abuela Demonio de Árbol",

	"i.bite": "Morder",
	"i.branch": "Rama",
	"i.wrap": "Enrollar",
	"i.lash": "Látigo",
	"i.claw": "Garra",
	"i.cocoon": "Capullo",
	"i.drain": "Drenar",
	"i.tendril": "Miríada",
	"i.rot": "Podrir",
	"i.dual": "Garra doble",
	"i.souleat": "Comealmas",

	"c.sushou": "Mano Pálida",
	"c.sushou.x": "Inflige 6 de daño",
	"c.sushou.b": "Inflige 9 de daño\nPierdes 2 de alma",

	"c.zhusha": "Cinabrio",
	"c.zhusha.x": "Inflige 5 de daño\nAplica 2 de veneno",
	"c.zhusha.b": "Inflige 8 de daño\nAplica 3 de veneno, −2 alma",

	"c.yeku": "Llanto Nocturno",
	"c.yeku.x": "Inflige 4 de daño 2 veces",
	"c.yeku.b": "Inflige 6 de daño 3 veces\nPierdes 3 de alma",

	"c.chansi": "Lazo de Seda",
	"c.chansi.x": "Inflige 3 de daño\nAtadura 1 turno",
	"c.chansi.b": "Daño igual al veneno\ndel objetivo ×2",

	"c.yuannian": "Rencor",
	"c.yuannian.x": "Inflige 6 de daño\n+2 por cada 5 de rencor",
	"c.yuannian.b": "Consume todo el rencor\n2 de daño por punto",

	"c.suyi": "Túnica Pálida",
	"c.suyi.x": "Ganas 8 de resguardo",
	"c.suyi.b": "Pierdes 4 de alma\n12 de daño a todos",

	"c.bosha": "Gasa",
	"c.bosha.x": "Ganas 6 de resguardo\nRobas 1 carta",
	"c.bosha.b": "Ganas 3 de resguardo\n1 de debilidad a todos",

	"c.zhangbi": "Baluarte",
	"c.zhangbi.x": "Ganas 12 de resguardo",
	"c.zhangbi.b": "Ganas 6 de resguardo\nReflejas 4 este turno",

	"c.youyuan": "Pena",
	"c.youyuan.x": "Aplica 3 de veneno",
	"c.youyuan.b": "Aplica 5 de veneno\nPierdes 3 de alma",

	"c.qingsi": "Hilo Rojo",
	"c.qingsi.x": "Atadura 1 turno",
	"c.qingsi.b": "Atadura 2 turnos",

	"c.yinlu": "Guía",
	"c.yinlu.x": "Robas 2 cartas",
	"c.yinlu.b": "Descartas 1 carta\nRobas 3 cartas",

	"c.yi": "Recuerdo",
	"c.yi.x": "Ganas 2 de voluntad",
	"c.yi.b": "Pierdes 3 de alma\nGanas 3 de voluntad",

	"c.dimei": "Mirada Baja",
	"c.dimei.x": "El próximo ataque del objetivo\nse reduce en 3",
	"c.dimei.b": "El objetivo no actúa 1 turno\nPierdes 5 de alma",

	"c.ku": "Llanto",
	"c.ku.x": "1 de debilidad a todos",
	"c.ku.b": "8 de daño a todos",

	"c.yuanyuan": "Envuelto en Rencor",
	"c.yuanyuan.x": "Al inicio del turno\nganas 2 de rencor",
	"c.yuanyuan.b": "Al recibir daño\nganas 2 de rencor extra",

	"c.zhong": "Campana de Lanruo",
	"c.zhong.x": "Primera carta de cada turno:\n2 de resguardo",
	"c.zhong.b": "Primera carta de cada turno:\n4 de daño aleatorio",

	"c.xiesui": "Maleficio",
	"c.xiesui.x": "No se puede jugar\nOcupa la mano",
	"c.xiesui.b": "No se puede jugar\nOcupa la mano",
}
