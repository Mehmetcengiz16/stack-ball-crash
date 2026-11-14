extends Node
## Bağımsız ses sistemi. res://assets/audio/<isim>.(ogg|wav|mp3) varsa onu kullanır,
## yoksa prosedürel kısa ses üretir; dosya eksikliği oyunu bozmaz.

const DEFS := {
	"bounce": [480.0, 0.07, "sine"],
	"break": [160.0, 0.10, "noise"],
	"combo": [880.0, 0.08, "sine"],
	"fireball": [260.0, 0.40, "sweep"],
	"fail": [200.0, 0.50, "sweepdown"],
	"complete": [523.0, 0.60, "arp"],
	"click": [1100.0, 0.04, "sine"],
}

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for n in DEFS.keys():
		_streams[n] = _load_or_generate(n)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -8.0
	add_child(_music)
	var m: Resource = _try_load("music")
	if m is AudioStream:
		_music.stream = m
		_music.finished.connect(_music.play)
	update_music()


func _try_load(n: String) -> Resource:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://assets/audio/%s.%s" % [n, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _load_or_generate(n: String) -> AudioStream:
	var r: Resource = _try_load(n)
	if r is AudioStream:
		return r
	return _generate(DEFS[n])


func _generate(d: Array) -> AudioStreamWAV:
	var rate := 22050
	var freq: float = d[0]
	var dur: float = d[1]
	var kind: String = d[2]
	var count := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var notes := [1.0, 1.26, 1.5, 2.0]
	for i in count:
		var t := float(i) / rate
		var k := float(i) / count
		var env := (1.0 - k) * minf(1.0, t * 200.0)
		var f := freq
		match kind:
			"sweep":
				f = freq + 700.0 * k
			"sweepdown":
				f = freq * (1.0 - 0.6 * k)
			"arp":
				f = freq * float(notes[mini(3, int(k * 4.0))])
		phase += TAU * f / rate
		var s := sin(phase)
		if kind == "noise":
			s = randf_range(-1.0, 1.0) * 0.6 + sin(phase) * 0.4
		var v := int(clampf(s * env * 0.45, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = bytes
	return w


func play(n: String, pitch: float = 1.0) -> void:
	if not bool(SaveManager.get_v("sfx")) or not _streams.has(n):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[n]
			p.pitch_scale = pitch
			p.play()
			return


func update_music() -> void:
	if _music.stream == null:
		return
	if bool(SaveManager.get_v("music")):
		if not _music.playing:
			_music.play()
	else:
		_music.stop()


func vibrate(ms: int = 25) -> void:
	if bool(SaveManager.get_v("vibration")) and (OS.has_feature("android") or OS.has_feature("ios")):
		Input.vibrate_handheld(ms)
