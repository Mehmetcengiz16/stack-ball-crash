extends UIScreen
## Oyun İçi HUD: seviye göstergesi + ilerleme, skor, ateş topu güç çubuğu, duraklat, kombo.

signal pause_pressed

var _cur: Label
var _next: Label
var _bar: ProgressBar
var _score: Label
var _fire: ProgressBar
var _fire_fill: StyleBoxFlat
var _flame: Control
var _combo: Label
var _shown_score: float = 0.0


func _level_circle(yellow: bool) -> Array:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(76, 76)
	if yellow:
		p.add_theme_stylebox_override("panel", UIKit.style(UIKit.YELLOW, 38, UIKit.ORANGE, 6, 4))
	else:
		p.add_theme_stylebox_override("panel", UIKit.style(Color("3a1f9a"), 38, Color.WHITE, 6, 4))
	var l := UIKit.label("1", 34, Color("6a2a00") if yellow else Color.WHITE, 0)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(l)
	return [p, l]


func _ready() -> void:
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", -6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.place(top, Vector2(0.5, 0), Vector2(-10, 80), Vector2(470, 80))
	add_child(top)
	var a: Array = _level_circle(true)
	_cur = a[1]
	top.add_child(a[0])
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(300, 26)
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.add_theme_stylebox_override("background", UIKit.style(Color("2a1470"), 13, Color("9b85ff"), 3, 0))
	_bar.add_theme_stylebox_override("fill", UIKit.style(UIKit.YELLOW, 13, UIKit.ORANGE, 0, 0))
	top.add_child(_bar)
	var b: Array = _level_circle(false)
	_next = b[1]
	top.add_child(b[0])

	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", -10)
	sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.place(sv, Vector2(0.5, 0), Vector2(0, 175), Vector2(400, 110))
	add_child(sv)
	sv.add_child(UIKit.label("Skor", 32, Color.WHITE, 8))
	_score = UIKit.label("0", 60, Color.WHITE, 12)
	sv.add_child(_score)

	var pause := UIKit.round_button("pause", 76)
	UIKit.place(pause, Vector2(1, 0), Vector2(-60, 70), Vector2(76, 76))
	pause.pressed.connect(func(): pause_pressed.emit())
	add_child(pause)

	# Ateş topu güç çubuğu (sol)
	_flame = UIKit.icon("flame", 74)
	UIKit.place(_flame, Vector2(0, 0.5), Vector2(58, -250), Vector2(74, 74))
	add_child(_flame)
	_fire = ProgressBar.new()
	_fire.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	_fire.show_percentage = false
	_fire.max_value = 1.0
	_fire.step = 0.0
	_fire.add_theme_stylebox_override("background", UIKit.style(Color(0.12, 0.04, 0.3, 0.8), 20, Color.WHITE, 4, 4))
	_fire_fill = UIKit.style(UIKit.ORANGE, 16, Color.TRANSPARENT, 0, 0)
	_fire.add_theme_stylebox_override("fill", _fire_fill)
	_fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.place(_fire, Vector2(0, 0.5), Vector2(58, -20), Vector2(40, 380))
	add_child(_fire)

	_combo = UIKit.label("KOMBO\nx2", 72, UIKit.YELLOW, 18, Color("c2240f"))
	_combo.add_theme_constant_override("line_spacing", -30)
	UIKit.place(_combo, Vector2(0.5, 0), Vector2(30, 340), Vector2(460, 220))
	_combo.rotation_degrees = -6
	_combo.visible = false
	add_child(_combo)

	GameManager.score_changed.connect(_on_score)
	GameManager.progress_changed.connect(func(v): _bar.value = v)
	GameManager.fire_changed.connect(_on_fire)
	GameManager.combo_changed.connect(_on_combo)
	GameManager.level_loaded.connect(func(_l): refresh())


func refresh() -> void:
	_cur.text = str(GameManager.level)
	_next.text = str(GameManager.level + 1)
	_shown_score = GameManager.score
	_score.text = UIKit.fmt(GameManager.score)


func _on_score(s: int) -> void:
	_score.pivot_offset = _score.size * 0.5
	_score.scale = Vector2(1.12, 1.12)
	if s < _shown_score:
		_shown_score = s


func _on_fire(v: float, active: bool) -> void:
	_fire.value = v
	_fire_fill.bg_color = Color("ff5a1f") if active else UIKit.ORANGE.lerp(UIKit.YELLOW, 1.0 - v)


func _on_combo(c: int) -> void:
	if c >= 3:
		_combo.text = "KOMBO\nx%d" % c
		_combo.visible = true
		_combo.pivot_offset = _combo.size * 0.5
		_combo.scale = Vector2(1.25, 1.25)
		_combo.modulate.a = 1.0
	else:
		_combo.visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_shown_score = lerpf(_shown_score, GameManager.score, 1.0 - exp(-12.0 * delta))
	_score.text = UIKit.fmt(int(round(_shown_score)))
	_score.scale = _score.scale.lerp(Vector2.ONE, 1.0 - exp(-10.0 * delta))
	if _combo.visible:
		_combo.scale = _combo.scale.lerp(Vector2.ONE, 1.0 - exp(-10.0 * delta))
	var pulse := 1.0 + (sin(Time.get_ticks_msec() * 0.012) * 0.08 if _fire.value > 0.8 else 0.0)
	_flame.pivot_offset = _flame.size * 0.5
	_flame.scale = Vector2(pulse, pulse)
