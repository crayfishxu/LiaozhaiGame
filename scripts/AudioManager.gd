extends Node

## ==================================================================
## 音频管理（autoload：Audio）
##
##   Audio.play_bgm("layer2")     切换背景音乐（带交叉淡化）
##   Audio.play_sfx("hit")        播放音效
##   Audio.cycle_music()          音乐音量循环 0→20→…→100→0
##   Audio.cycle_sfx()            音效音量循环
##   Audio.toggle_mute()          全局静音
##
## 音频素材由 tools/gen_audio.py 程序化合成，无外部版权。
## BGM 为无缝循环 ogg，音效为短 wav。
## ==================================================================

const CFG_PATH := "user://settings.cfg"
const CFG_SECTION := "audio"

const BGM_PATH := "res://audio/bgm/%s.ogg"
const SFX_PATH := "res://audio/sfx/%s.wav"

## 音量档位：0 表示关闭
const STEPS := [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

const SFX_VOICES := 10
const FADE_TIME := 0.9

var music_volume: float = 0.6
var sfx_volume: float = 0.8
var muted: bool = false

var _bgm_key: String = ""
var _players: Array[AudioStreamPlayer] = []
var _slot: int = 0
var _cache: Dictionary = {}
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_players()
	load_cfg()


func _build_players() -> void:
	# 两个 BGM 声道，用于交叉淡化
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.name = "BGM%d" % i
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)

	# 音效声道池：轮转使用，避免同一声被截断
	for i in SFX_VOICES:
		var s := AudioStreamPlayer.new()
		s.name = "SFX%d" % i
		s.volume_db = 0.0
		add_child(s)
		_players.append(s)


func _sfx_start() -> int:
	return 2          # 前两个是 BGM


func _exit_tree() -> void:
	# 退出时主动断开引用，否则引擎会报 "resources still in use at exit"
	for p in _players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_players.clear()
	_cache.clear()


# ------------------------------------------------------------------
# BGM
# ------------------------------------------------------------------
func play_bgm(key: String) -> void:
	if key == "" or key == _bgm_key:
		return
	var stream := _get_stream(BGM_PATH % key, true)
	if stream == null:
		return

	_bgm_key = key
	# 新曲放进「当前没在播」的那一路，旧曲继续播着淡出
	var nxt: AudioStreamPlayer = _players[0] if not _players[0].playing else _players[1]
	var cur: AudioStreamPlayer = _players[1] if nxt == _players[0] else _players[0]

	nxt.stream = stream
	nxt.volume_db = -60.0
	nxt.play()

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(nxt, "volume_db", _music_db(1.0), FADE_TIME)
	if cur.playing:
		_fade_tween.tween_property(cur, "volume_db", -60.0, FADE_TIME)
		_fade_tween.chain().tween_callback(cur.stop)


func stop_bgm() -> void:
	_bgm_key = ""
	for p in _players.slice(0, 2):
		p.stop()


func _music_db(scale: float) -> float:
	var v := music_volume * scale
	if muted or v <= 0.001:
		return -80.0
	return linear_to_db(v)


func _refresh_music_volume() -> void:
	for i in 2:
		var p := _players[i]
		if p.playing:
			p.volume_db = _music_db(1.0)


# ------------------------------------------------------------------
# SFX
# ------------------------------------------------------------------
func play_sfx(key: String, pitch_jitter: float = 0.05) -> void:
	if muted or sfx_volume <= 0.001:
		return
	var stream := _get_stream(SFX_PATH % key, false)
	if stream == null:
		return
	var start := _sfx_start()
	var p := _players[start + _slot]
	_slot = (_slot + 1) % SFX_VOICES
	p.stream = stream
	p.volume_db = linear_to_db(sfx_volume)
	if pitch_jitter > 0.0:
		p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	else:
		p.pitch_scale = 1.0
	p.play()


func _get_stream(path: String, loop: bool) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_warning("音频缺失: " + path)
		return null
	var st: AudioStream = load(path)
	if st == null:
		return null
	if loop and st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	_cache[path] = st
	return st


# ------------------------------------------------------------------
# 音量控制
# ------------------------------------------------------------------
func cycle_music() -> void:
	music_volume = _next_step(music_volume)
	_refresh_music_volume()
	save_cfg()


func cycle_sfx() -> void:
	sfx_volume = _next_step(sfx_volume)
	save_cfg()
	if sfx_volume > 0.001:
		play_sfx("click", 0.0)


func toggle_mute() -> void:
	muted = not muted
	_refresh_music_volume()
	if not muted:
		play_sfx("click", 0.0)
	save_cfg()


func _next_step(v: float) -> float:
	var best := 0
	var dist := 9.0
	for i in STEPS.size():
		var d := absf(STEPS[i] - v)
		if d < dist:
			dist = d
			best = i
	return STEPS[(best + 1) % STEPS.size()]


## 供 UI 显示：「60%」或「关」
func music_text() -> String:
	return _step_text(music_volume)


func sfx_text() -> String:
	return _step_text(sfx_volume)


func _step_text(v: float) -> String:
	if muted or v <= 0.001:
		return I18N.t("ui.off")
	return "%d%%" % roundi(v * 100.0)


# ------------------------------------------------------------------
# 持久化（与 I18N 共用 settings.cfg，各占一个 section）
# ------------------------------------------------------------------
func save_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)            # 保留其它 section（i18n）
	cfg.set_value(CFG_SECTION, "music", music_volume)
	cfg.set_value(CFG_SECTION, "sfx", sfx_volume)
	cfg.set_value(CFG_SECTION, "muted", muted)
	cfg.save(CFG_PATH)


func load_cfg() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		music_volume = clampf(float(cfg.get_value(CFG_SECTION, "music", 0.6)), 0.0, 1.0)
		sfx_volume = clampf(float(cfg.get_value(CFG_SECTION, "sfx", 0.8)), 0.0, 1.0)
		muted = bool(cfg.get_value(CFG_SECTION, "muted", false))
