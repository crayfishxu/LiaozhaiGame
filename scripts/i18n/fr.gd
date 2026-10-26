extends RefCounted

## ------------------------------------------------------------------
## Français
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "Feu d'âme",
	"w.grudge": "Rancune",
	"w.block": "Garde",
	"w.poison": "Venin",
	"w.weak": "Faiblesse",
	"w.bind": "Entrave",

	"ui.title": "LA BELLE DE LIAOZHAI",
	"ui.subtitle": "Prototype de combat · Temple de Lanruo",
	"ui.intro": "Chaque carte a deux faces : Apparence et Vraie Forme.\nElle se retourne une fois jouée : une carte, deux usages.\n\nL'Apparence défend et contrôle ; la Vraie Forme frappe plus fort, à un prix.\nSubir des dégâts accumule la Rancune : plus elle est profonde, plus certaines cartes deviennent fortes.",
	"ui.enter": "ENTRER DANS LE RÊVE",

	"ui.layer1": "Couche I · Première rencontre",
	"ui.layer2": "Couche II · Obsession",
	"ui.layer3": "Couche III · Délivrance",
	"ui.chapter1": "Temple de Lanruo · Cour extérieure",
	"ui.chapter2": "Temple de Lanruo · Salle de Bouddha",
	"ui.chapter3": "Temple de Lanruo · Antre des démons",

	"ui.pile_draw": "Mémoire",
	"ui.pile_discard": "Oubli",
	"ui.end_turn": "FIN DU TOUR",
	"ui.target_hint": "▸ CHOISIS UN ENNEMI",
	"ui.side_xian": "APPARENCE",
	"ui.side_ben": "VRAIE FORME",
	"ui.bound": "ENTRAVÉ",

	"ui.toast_busy": "Les ennemis agissent…",
	"ui.toast_no_energy": "Volonté insuffisante · il faut %d",
	"ui.toast_curse": "Les malédictions sont injouables",
	"ui.toast_deselect": "Sélection annulée",
	"ui.toast_pick_first": "Choisis une carte, puis un ennemi",
	"ui.toast_lang": "Langue changée",

	"ui.reward_title": "UNE PENSÉE OBTENUE",
	"ui.reward_sub": "Choisis-en une pour ton deck",
	"ui.reward_skip": "NE RIEN PRENDRE",

	"ui.win_title": "LE NŒUD EST DÉFAIT",
	"ui.win_sub": "La brume de Lanruo s'est dissipée.\nElle se tient dans la lumière, la tête haute pour la première fois.\n\n« Merci… de te souvenir de moi. »",
	"ui.lose_title": "LE FEU D'ÂME S'ÉTEINT",
	"ui.lose_sub": "Tu as reculé.\nElle attend encore — celui qui voudra écouter.\n\n« L'obsession de cette vie n'a pas pu être défaite. »",
	"ui.again": "REJOUER",
	"ui.exit": "QUITTER",

	"ui.pause_title": "PAUSE",
	"ui.pause_sub": "La brume de Lanruo t'attend encore.",
	"ui.resume": "REPRENDRE",
	"ui.restart": "RECOMMENCER",
	"ui.quit_desktop": "QUITTER VERS LE BUREAU",
	"ui.pause_hint": "La touche Retour rouvre ce menu",

	"ui.language": "LANGUE",
	"ui.lang_title": "CHOISIR LA LANGUE",
	"ui.lang_sub": "Appliqué aussitôt. Ta partie est conservée.",
	"ui.lang_back": "RETOUR",

	"t.attack": "Courroux",
	"t.defend": "Garde",
	"t.skill": "Esprit",
	"t.power": "Obsession",
	"t.curse": "Malédiction",

	"e.youhun": "Âme Errante",
	"e.shukui": "Marionnette d'Arbre",
	"e.laolao": "Grand-mère",
	"e.benti": "Grand-mère Démon d'Arbre",

	"i.bite": "Morsure",
	"i.branch": "Branche",
	"i.wrap": "Enrouler",
	"i.lash": "Fouet",
	"i.claw": "Griffe",
	"i.cocoon": "Cocon",
	"i.drain": "Drainer",
	"i.tendril": "Myriade",
	"i.rot": "Pourriture",
	"i.dual": "Double Griffe",
	"i.souleat": "Mangeuse d'âmes",

	"c.sushou": "Main Pâle",
	"c.sushou.x": "Inflige 6 dégâts",
	"c.sushou.b": "Inflige 9 dégâts\n−2 feu d'âme",

	"c.zhusha": "Cinabre",
	"c.zhusha.x": "5 dégâts\nApplique 2 venin",
	"c.zhusha.b": "8 dégâts\n3 venin, −2 feu d'âme",

	"c.yeku": "Pleurs Nocturnes",
	"c.yeku.x": "4 dégâts ×2",
	"c.yeku.b": "6 dégâts ×3\n−3 feu d'âme",

	"c.chansi": "Fil de Soie",
	"c.chansi.x": "3 dégâts\nEntrave 1 tour",
	"c.chansi.b": "Dégâts égaux au venin\nde la cible ×2",

	"c.yuannian": "Rancune",
	"c.yuannian.x": "6 dégâts\n+2 par 5 de rancune",
	"c.yuannian.b": "Consomme toute la rancune\n2 dégâts par point",

	"c.suyi": "Robe Pâle",
	"c.suyi.x": "Gagne 8 garde",
	"c.suyi.b": "−4 feu d'âme\n12 dégâts à tous",

	"c.bosha": "Gaze",
	"c.bosha.x": "Gagne 6 garde\nPioche 1 carte",
	"c.bosha.b": "Gagne 3 garde\n1 faiblesse à tous",

	"c.zhangbi": "Rempart",
	"c.zhangbi.x": "Gagne 12 garde",
	"c.zhangbi.b": "Gagne 6 garde\nRenvoie 4 ce tour",

	"c.youyuan": "Chagrin",
	"c.youyuan.x": "Applique 3 venin",
	"c.youyuan.b": "Applique 5 venin\n−3 feu d'âme",

	"c.qingsi": "Fil Rouge",
	"c.qingsi.x": "Entrave 1 tour",
	"c.qingsi.b": "Entrave 2 tours",

	"c.yinlu": "Guidance",
	"c.yinlu.x": "Pioche 2 cartes",
	"c.yinlu.b": "Défausse 1 carte\nPioche 3 cartes",

	"c.yi": "Mémoire",
	"c.yi.x": "Gagne 2 volonté",
	"c.yi.b": "−3 feu d'âme\nGagne 3 volonté",

	"c.dimei": "Regard Baissé",
	"c.dimei.x": "La prochaine attaque de la cible\nest réduite de 3",
	"c.dimei.b": "La cible n'agit pas 1 tour\n−5 feu d'âme",

	"c.ku": "Pleurs",
	"c.ku.x": "1 faiblesse à tous",
	"c.ku.b": "8 dégâts à tous",

	"c.yuanyuan": "Enveloppé de Rancune",
	"c.yuanyuan.x": "Au début du tour\ngagne 2 rancune",
	"c.yuanyuan.b": "En subissant des dégâts\n+2 rancune",

	"c.zhong": "Cloche de Lanruo",
	"c.zhong.x": "Première carte du tour :\n2 garde",
	"c.zhong.b": "Première carte du tour :\n4 dégâts aléatoires",

	"c.xiesui": "Maléfice",
	"c.xiesui.x": "Injouable\nEncombre la main",
	"c.xiesui.b": "Injouable\nEncombre la main",
}
