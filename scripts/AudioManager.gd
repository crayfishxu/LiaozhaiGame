extends Node

## ==================================================================
## 音频管理（autoload：Audio）
##
##   Audio.play_bgm("layer2")     切换背景音乐（带交叉淡化）
##   Audio.play_sfx("hit")        播放音效
##   Audio.set_music_enabled(on)  音乐开关（与音效互不影响）
##   Audio.set_sfx_enabled(on)    音效开关
##   Audio.cycle_music()          音乐音量 20→40→…→100→20
##   Audio.cycle_sfx()            音效音量
##
## 音频素材由 tools/gen_audio.py 程序化合成，无外部版权。
## BGM 为无缝循环 ogg，音效为短 wav。
## ==================================================================

const CFG_PATH := "user://settings.cfg"
const CFG_SECTION := "audio"

const BGM_PATH := "res://audio/bgm/%s.ogg"
const SFX_PATH := "res://audio/sfx/%s.wav"

## 音量档位：开关负责「有没有声」，档位只管「多大声」
const STEPS := [0.2, 0.4, 0.6, 0.8, 1.0]

const SFX_VOICES := 10
const FADE_TIME := 0.9
const VOL_FADE := 0.30

var music_volume: float = 0.6
var sfx_volume: float = 0.8
var music_on: bool = true
var sfx_on: bool = true

var _bgm_key: String = ""
var _players: Array[AudioStreamPlayer] = []
var _slot: int = 0
var _cache: Dictionary = {}
var _fade_tween: Tween
var _vol_gen: int = 0                 # 变更代次：过期的「淡出后停止」回调靠它作废
var _vol_tweens: Array[Tween] = []


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
	_vol_gen += 1
	_kill_vol_tweens()
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
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
	if not music_on or v <= 0.001:
		return -80.0
	return linear_to_db(v)


## 音乐音量变化后同步到在播的声道。smooth=true 用于开关切换，淡入而非硬跳。
func _refresh_music_volume(smooth: bool = false) -> void:
	var target := _music_db(1.0)
	_kill_vol_tweens()
	for i in 2:
		var p := _players[i]
		if not p.playing:
			continue
		if smooth:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", target, VOL_FADE)
			_vol_tweens.append(tw)
		else:
			p.volume_db = target


## 淡出后停止两路 BGM。用代次号防止「关了又立刻开」时旧回调把新播放掐掉。
func _fade_out_and_stop() -> void:
	_vol_gen += 1
	var gen := _vol_gen
	_kill_vol_tweens()
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	for i in 2:
		var p := _players[i]
		if not p.playing:
			continue
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -80.0, VOL_FADE)
		tw.tween_callback(func():
			if gen == _vol_gen:
				p.stop()
		)
		_vol_tweens.append(tw)


func _kill_vol_tweens() -> void:
	for t in _vol_tweens:
		if t != null and t.is_valid():
			t.kill()
	_vol_tweens.clear()


# ------------------------------------------------------------------
# SFX
# ------------------------------------------------------------------
func play_sfx(key: String, pitch_jitter: float = 0.05) -> void:
	if not sfx_on or sfx_volume <= 0.001:
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
# 开关
# ------------------------------------------------------------------
## 音乐开关。关掉时淡出并停止播放（省电），曲目名留着，打开时重新起播。
func set_music_enabled(v: bool) -> void:
	if v == music_on:
		return
	music_on = v
	if v:
		_vol_gen += 1                       # 作废可能还在跑的「淡出后停止」
		if _fade_tween != null and _fade_tween.is_valid():
			_fade_tween.kill()
		if _bgm_key != "" and not (_players[0].playing or _players[1].playing):
			var key := _bgm_key
			_bgm_key = ""
			play_bgm(key)
		else:
			_refresh_music_volume(true)
		play_sfx("click", 0.0)
	else:
		_fade_out_and_stop()
	save_cfg()


## 音效开关。关掉之前先响一记，让玩家确认「我按到了」。
func set_sfx_enabled(v: bool) -> void:
	if v == sfx_on:
		return
	if v:
		sfx_on = true
		play_sfx("click", 0.0)
	else:
		play_sfx("click", 0.0)
		sfx_on = false
	save_cfg()


# ------------------------------------------------------------------
# 音量档位
# ------------------------------------------------------------------
## 点一下升一档；关着的时候第一下先打开（不跳档），符合「我想听」的直觉
func cycle_music() -> void:
	if not music_on:
		set_music_enabled(true)
		return
	music_volume = _next_step(music_volume)
	_refresh_music_volume()
	save_cfg()


func cycle_sfx() -> void:
	if not sfx_on:
		set_sfx_enabled(true)
		return
	sfx_volume = _next_step(sfx_volume)
	save_cfg()
	play_sfx("click", 0.0)


func _next_step(v: float) -> float:
	var best := 0
	var dist := 9.0
	for i in STEPS.size():
		var d := absf(STEPS[i] - v)
		if d < dist:
			dist = d
			best = i
	return STEPS[(best + 1) % STEPS.size()]


## 供 UI 显示：音量百分比（开关状态由开关本身表达）
func music_label() -> String:
	return "%d%%" % roundi(music_volume * 100.0)


func sfx_label() -> String:
	return "%d%%" % roundi(sfx_volume * 100.0)


# ------------------------------------------------------------------
# 持久化（与 I18N 共用 settings.cfg，各占一个 section）
# ------------------------------------------------------------------
func save_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)            # 保留其它 section（i18n）
	cfg.set_value(CFG_SECTION, "music", music_volume)
	cfg.set_value(CFG_SECTION, "sfx", sfx_volume)
	cfg.set_value(CFG_SECTION, "music_on", music_on)
	cfg.set_value(CFG_SECTION, "sfx_on", sfx_on)
	if cfg.has_section_key(CFG_SECTION, "muted"):
		cfg.erase_section_key(CFG_SECTION, "muted")   # 旧版全局静音位，已拆成两个开关
	cfg.save(CFG_PATH)


func load_cfg() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return
	music_volume = clampf(float(cfg.get_value(CFG_SECTION, "music", 0.6)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value(CFG_SECTION, "sfx", 0.8)), 0.0, 1.0)
	music_on = bool(cfg.get_value(CFG_SECTION, "music_on", true))
	sfx_on = bool(cfg.get_value(CFG_SECTION, "sfx_on", true))

	# 迁移 0.1.7 及以前的存法：那时只有「全局静音」和 0 档音量，都折算成开关
	if bool(cfg.get_value(CFG_SECTION, "muted", false)):
		music_on = false
		sfx_on = false
	if music_volume <= 0.001:
		music_volume = 0.6
		music_on = false
	if sfx_volume <= 0.001:
		sfx_volume = 0.8
		sfx_on = false
