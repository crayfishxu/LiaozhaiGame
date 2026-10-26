extends RefCounted

## ------------------------------------------------------------------
## Bahasa Indonesia
## ------------------------------------------------------------------

const TEXT := {
	"w.hp": "Api Jiwa",
	"w.grudge": "Dendam",
	"w.block": "Pelindung",
	"w.poison": "Racun",
	"w.weak": "Lemah",
	"w.bind": "Belenggu",

	"ui.title": "SI CANTIK LIAOZHAI",
	"ui.subtitle": "Prototipe pertarungan · Kuil Lanruo",
	"ui.intro": "Setiap kartu punya dua sisi: Rupa dan Wujud Asli.\nKartu berbalik setelah dimainkan: satu kartu, dua cara pakai.\n\nRupa bertahan dan mengendalikan; Wujud Asli menghantam lebih keras dengan harga.\nMenerima kerusakan menumpuk Dendam — makin dalam, makin kuat beberapa kartu.",
	"ui.enter": "MASUK KE MIMPI",

	"ui.layer1": "Lapisan I · Perjumpaan Pertama",
	"ui.layer2": "Lapisan II · Kemelekatan",
	"ui.layer3": "Lapisan III · Kelepasan",
	"ui.chapter1": "Kuil Lanruo · Halaman Luar",
	"ui.chapter2": "Kuil Lanruo · Aula Buddha",
	"ui.chapter3": "Kuil Lanruo · Sarang Iblis",

	"ui.pile_draw": "Ingatan",
	"ui.pile_discard": "Lupa",
	"ui.end_turn": "AKHIRI GILIRAN",
	"ui.target_hint": "▸ PILIH MUSUH",
	"ui.side_xian": "RUPA",
	"ui.side_ben": "WUJUD ASLI",
	"ui.bound": "TERBELENGGU",

	"ui.toast_busy": "Musuh sedang bergerak…",
	"ui.toast_no_energy": "Tekad kurang · butuh %d",
	"ui.toast_curse": "Kartu kutukan tak bisa dimainkan",
	"ui.toast_deselect": "Pilihan dibatalkan",
	"ui.toast_pick_first": "Pilih kartu dulu, lalu musuh",
	"ui.toast_lang": "Bahasa diubah",

	"ui.reward_title": "SEBUAH PIKIRAN DIDAPAT",
	"ui.reward_sub": "Pilih satu untuk dekmu",
	"ui.reward_skip": "TIDAK AMBIL",

	"ui.win_title": "SIMPUL TELAH TERURAI",
	"ui.win_sub": "Kabut Lanruo telah menipis.\nIa berdiri di cahaya, kepala terangkat untuk pertama kalinya.\n\n“Terima kasih… karena mengingatku.”",
	"ui.lose_title": "API JIWA MULAI PADAM",
	"ui.lose_sub": "Kau melangkah mundur.\nIa masih menunggu — orang yang mau mendengar.\n\n«Kemelekatan hidup ini tak terurai.»",
	"ui.again": "MAIN LAGI",
	"ui.exit": "KELUAR",

	"ui.pause_title": "JEDA",
	"ui.pause_sub": "Kabut Lanruo masih menunggumu.",
	"ui.resume": "LANJUTKAN",
	"ui.restart": "MULAI ULANG",
	"ui.quit_desktop": "KELUAR KE DESKTOP",
	"ui.pause_hint": "Tekan Kembali untuk membuka menu ini lagi",

	"ui.language": "BAHASA",
	"ui.lang_title": "PILIH BAHASA",
	"ui.lang_sub": "Langsung berlaku. Progresmu tetap.",
	"ui.lang_back": "KEMBALI",

	"t.attack": "Murka",
	"t.defend": "Pelindung",
	"t.skill": "Pikiran",
	"t.power": "Kemelekatan",
	"t.curse": "Kutukan",

	"e.youhun": "Arwah Gentayangan",
	"e.shukui": "Boneka Kayu",
	"e.laolao": "Nenek",
	"e.benti": "Nenek Iblis Kayu",

	"i.bite": "Gigit",
	"i.branch": "Ranting",
	"i.wrap": "Lilit",
	"i.lash": "Cambuk",
	"i.claw": "Cakar",
	"i.cocoon": "Kepompong",
	"i.drain": "Sedot",
	"i.tendril": "Seribu",
	"i.rot": "Busuk",
	"i.dual": "Cakar Ganda",
	"i.souleat": "Pemakan Jiwa",

	"c.sushou": "Tangan Pucat",
	"c.sushou.x": "Beri 6 kerusakan",
	"c.sushou.b": "Beri 9 kerusakan\n−2 api jiwa",

	"c.zhusha": "Sinabar",
	"c.zhusha.x": "5 kerusakan\nBeri 2 racun",
	"c.zhusha.b": "8 kerusakan\n3 racun, −2 api jiwa",

	"c.yeku": "Tangis Malam",
	"c.yeku.x": "4 kerusakan ×2",
	"c.yeku.b": "6 kerusakan ×3\n−3 api jiwa",

	"c.chansi": "Benang Sutra",
	"c.chansi.x": "3 kerusakan\nBelenggu 1 giliran",
	"c.chansi.b": "Kerusakan sebesar racun\nmusuh ×2",

	"c.yuannian": "Dendam",
	"c.yuannian.x": "6 kerusakan\n+2 tiap 5 dendam",
	"c.yuannian.b": "Habiskan semua dendam\n2 kerusakan per poin",

	"c.suyi": "Jubah Pucat",
	"c.suyi.x": "Dapat 8 pelindung",
	"c.suyi.b": "−4 api jiwa\n12 kerusakan ke semua",

	"c.bosha": "Kasa",
	"c.bosha.x": "Dapat 6 pelindung\nAmbil 1 kartu",
	"c.bosha.b": "Dapat 3 pelindung\n1 lemah ke semua",

	"c.zhangbi": "Benteng",
	"c.zhangbi.x": "Dapat 12 pelindung",
	"c.zhangbi.b": "Dapat 6 pelindung\nPantulkan 4 giliran ini",

	"c.youyuan": "Sedih",
	"c.youyuan.x": "Beri 3 racun",
	"c.youyuan.b": "Beri 5 racun\n−3 api jiwa",

	"c.qingsi": "Benang Merah",
	"c.qingsi.x": "Belenggu 1 giliran",
	"c.qingsi.b": "Belenggu 2 giliran",

	"c.yinlu": "Penuntun",
	"c.yinlu.x": "Ambil 2 kartu",
	"c.yinlu.b": "Buang 1 kartu\nAmbil 3 kartu",

	"c.yi": "Ingatan",
	"c.yi.x": "Dapat 2 tekad",
	"c.yi.b": "−3 api jiwa\nDapat 3 tekad",

	"c.dimei": "Pandangan Turun",
	"c.dimei.x": "Serangan berikutnya musuh\nberkurang 3",
	"c.dimei.b": "Musuh tak bergerak 1 giliran\n−5 api jiwa",

	"c.ku": "Tangis",
	"c.ku.x": "1 lemah ke semua",
	"c.ku.b": "8 kerusakan ke semua",

	"c.yuanyuan": "Dililit Dendam",
	"c.yuanyuan.x": "Di awal giliran\ndapat 2 dendam",
	"c.yuanyuan.b": "Saat terkena serangan\n+2 dendam",

	"c.zhong": "Lonceng Lanruo",
	"c.zhong.x": "Kartu pertama tiap giliran:\n2 pelindung",
	"c.zhong.b": "Kartu pertama tiap giliran:\n4 kerusakan acak",

	"c.xiesui": "Kutukan",
	"c.xiesui.x": "Tak bisa dimainkan\nMemenuhi tangan",
	"c.xiesui.b": "Tak bisa dimainkan\nMemenuhi tangan",
}
