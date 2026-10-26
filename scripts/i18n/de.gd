extends RefCounted

## ------------------------------------------------------------------
## Deutsch
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "Seelenfeuer",
	"w.grudge": "Groll",
	"w.block": "Schild",
	"w.poison": "Gift",
	"w.weak": "Schwäche",
	"w.bind": "Fessel",

	"ui.title": "DIE SCHÖNE VON LIAOZHAI",
	"ui.subtitle": "Kampfprototyp · Lanruo-Tempel",
	"ui.intro": "Jede Karte hat zwei Seiten: Schein und Wahre Form.\nNach dem Ausspielen dreht sie sich um: eine Karte, zwei Arten zu spielen.\n\nDer Schein verteidigt und hält stand; die Wahre Form trifft härter, aber zu einem Preis.\nSchaden sammelt Groll — je tiefer er reicht, desto stärker werden manche Karten.",
	"ui.enter": "IN DEN TRAUM",

	"ui.layer1": "Ebene I · Erste Begegnung",
	"ui.layer2": "Ebene II · Obsession",
	"ui.layer3": "Ebene III · Erlösung",
	"ui.chapter1": "Lanruo-Tempel · Äußerer Hof",
	"ui.chapter2": "Lanruo-Tempel · Buddha-Halle",
	"ui.chapter3": "Lanruo-Tempel · Dämonengrube",

	"ui.pile_draw": "Erinnerung",
	"ui.pile_discard": "Vergessen",
	"ui.end_turn": "ZUG BEENDEN",
	"ui.target_hint": "▸ WÄHLE EINEN FEIND",
	"ui.side_xian": "SCHEIN",
	"ui.side_ben": "WAHRE FORM",
	"ui.bound": "GEFESSELT",

	"ui.toast_busy": "Die Feinde handeln…",
	"ui.toast_no_energy": "Nicht genug Wille · %d nötig",
	"ui.toast_curse": "Fluchkarten sind nicht spielbar",
	"ui.toast_deselect": "Auswahl aufgehoben",
	"ui.toast_pick_first": "Erst eine Karte, dann ein Feind",
	"ui.toast_lang": "Sprache geändert",

	"ui.reward_title": "EIN GEDANKE GEFUNDEN",
	"ui.reward_sub": "Wähle eine für dein Deck",
	"ui.reward_skip": "KEINE NEHMEN",

	"ui.win_title": "DER KNOTEN IST GELÖST",
	"ui.win_sub": "Der Nebel über Lanruo hat sich gelichtet.\nSie steht im Licht und hebt zum ersten Mal den Kopf.\n\n„Danke … dass du dich an mich erinnerst.“",
	"ui.lose_title": "DAS SEELENFEUER ERLISCHT",
	"ui.lose_sub": "Du bist zurückgewichen.\nSie wartet noch — auf den Nächsten, der zuhören will.\n\n»Die Obsession dieses Lebens ließ sich nicht lösen.«",
	"ui.again": "NOCH EINMAL",
	"ui.exit": "BEENDEN",

	"ui.pause_title": "PAUSE",
	"ui.pause_sub": "Der Nebel von Lanruo wartet noch.",
	"ui.resume": "FORTSETZEN",
	"ui.restart": "NEU STARTEN",
	"ui.quit_desktop": "ZUM DESKTOP",
	"ui.pause_hint": "Zurück-Taste öffnet dieses Menü erneut",

	"ui.language": "SPRACHE",
	"ui.lang_title": "SPRACHE WÄHLEN",
	"ui.lang_sub": "Gilt sofort. Dein Fortschritt bleibt.",
	"ui.lang_back": "ZURÜCK",

	"t.attack": "Zorn",
	"t.defend": "Schild",
	"t.skill": "Geist",
	"t.power": "Obsession",
	"t.curse": "Fluch",

	"e.youhun": "Wandernde Seele",
	"e.shukui": "Baumpuppe",
	"e.laolao": "Großmutter",
	"e.benti": "Baumdämon-Großmutter",

	"i.bite": "Biss",
	"i.branch": "Ast",
	"i.wrap": "Umschlingen",
	"i.lash": "Peitsche",
	"i.claw": "Klaue",
	"i.cocoon": "Kokon",
	"i.drain": "Aussaugen",
	"i.tendril": "Myriaden",
	"i.rot": "Fäule",
	"i.dual": "Doppelklaue",
	"i.souleat": "Seelensauger",

	"c.sushou": "Blasse Hand",
	"c.sushou.x": "Verursacht 6 Schaden",
	"c.sushou.b": "Verursacht 9 Schaden\n−2 Seelenfeuer",

	"c.zhusha": "Zinnober",
	"c.zhusha.x": "5 Schaden\n2 Gift",
	"c.zhusha.b": "8 Schaden\n3 Gift, −2 Seelenfeuer",

	"c.yeku": "Nachtweinen",
	"c.yeku.x": "4 Schaden ×2",
	"c.yeku.b": "6 Schaden ×3\n−3 Seelenfeuer",

	"c.chansi": "Seidenfaden",
	"c.chansi.x": "3 Schaden\nFessel 1 Zug",
	"c.chansi.b": "Schaden gleich dem\nGift des Ziels ×2",

	"c.yuannian": "Groll",
	"c.yuannian.x": "6 Schaden\n+2 je 5 Groll",
	"c.yuannian.b": "Verbraucht allen Groll\n2 Schaden pro Punkt",

	"c.suyi": "Bleiches Gewand",
	"c.suyi.x": "8 Schild",
	"c.suyi.b": "−4 Seelenfeuer\n12 Schaden an alle",

	"c.bosha": "Gaze",
	"c.bosha.x": "6 Schild\nZiehe 1 Karte",
	"c.bosha.b": "3 Schild\n1 Schwäche an alle",

	"c.zhangbi": "Bollwerk",
	"c.zhangbi.x": "12 Schild",
	"c.zhangbi.b": "6 Schild\nReflektiere 4 diesen Zug",

	"c.youyuan": "Kummer",
	"c.youyuan.x": "3 Gift",
	"c.youyuan.b": "5 Gift\n−3 Seelenfeuer",

	"c.qingsi": "Roter Faden",
	"c.qingsi.x": "Fessel 1 Zug",
	"c.qingsi.b": "Fessel 2 Züge",

	"c.yinlu": "Geleit",
	"c.yinlu.x": "Ziehe 2 Karten",
	"c.yinlu.b": "Wirf 1 Karte ab\nZiehe 3 Karten",

	"c.yi": "Erinnerung",
	"c.yi.x": "2 Wille",
	"c.yi.b": "−3 Seelenfeuer\n3 Wille",

	"c.dimei": "Senkter Blick",
	"c.dimei.x": "Nächster Angriff des Ziels\num 3 reduziert",
	"c.dimei.b": "Ziel handelt 1 Zug nicht\n−5 Seelenfeuer",

	"c.ku": "Weinen",
	"c.ku.x": "1 Schwäche an alle",
	"c.ku.b": "8 Schaden an alle",

	"c.yuanyuan": "Grollumwoben",
	"c.yuanyuan.x": "Zu Zugbeginn\n2 Groll",
	"c.yuanyuan.b": "Bei Schaden\n+2 zusätzlicher Groll",

	"c.zhong": "Glocke von Lanruo",
	"c.zhong.x": "Erste Karte je Zug:\n2 Schild",
	"c.zhong.b": "Erste Karte je Zug:\n4 zufälliger Schaden",

	"c.xiesui": "Fluch",
	"c.xiesui.x": "Nicht spielbar\nBlockiert die Hand",
	"c.xiesui.b": "Nicht spielbar\nBlockiert die Hand",
}
