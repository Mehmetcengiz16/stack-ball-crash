extends UIScreen
## Seviye Tamamlandı: taç, kurdele, 3 yıldız, skor + kazanılan coin, konfeti.

signal next_pressed
signal home_pressed
signal replay_pressed

var _score: Label
var _coins: Label
var _stars: Array = []
var _confetti: CPUParticles2D


func _ready() -> void:
	add_backdrop()
	var vb := make_card(560, -20)
	var crown := UIKit.icon("crown", 110)
	crown.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(crown)
	var rh0 := HBoxContainer.new()
	rh0.alignment = BoxContainer.ALIGNMENT_CENTER
	rh0.add_theme_constant_override("separation", -8)
	vb.add_child(rh0)
	var lw := UIKit.laurel(false, 96)
	lw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rh0.add_child(lw)
	rh0.add_child(UIKit.ribbon("SEVİYE\nTAMAMLANDI!", UIKit.RIBBON, 44))
	var rw := UIKit.laurel(true, 96)
	rw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rh0.add_child(rw)

	var sh := HBoxContainer.new()
	sh.alignment = BoxContainer.ALIGNMENT_CENTER
	sh.add_theme_constant_override("separation", 10)
	vb.add_child(sh)
	for i in 3:
		var s := UIKit.icon("star", 104 if i == 1 else 88)
		s.size_flags_vertical = Control.SIZE_SHRINK_END if i != 1 else Control.SIZE_SHRINK_BEGIN
		sh.add_child(s)
		_stars.append(s)

	var ip := UIKit.inner_panel(22)
	ip.custom_minimum_size.x = 420
	ip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(ip)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 0)
	ip.add_child(iv)
	iv.add_child(UIKit.label("Skor", 30))
	_score = UIKit.label("0", 56, Color.WHITE, 8)
	iv.add_child(_score)
	var ch := HBoxContainer.new()
	ch.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_theme_constant_override("separation", 12)
	iv.add_child(ch)
	ch.add_child(UIKit.label("Kazanılan Coin", 28))
	ch.add_child(UIKit.icon("coin", 36))
	_coins = UIKit.label("+0", 32, Color.WHITE, 6)
	ch.add_child(_coins)

	var next := UIKit.button("Sonraki Seviye", "play", Vector2(460, 104), 42)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(func(): next_pressed.emit())
	vb.add_child(next)
	var rh := HBoxContainer.new()
	rh.alignment = BoxContainer.ALIGNMENT_CENTER
	rh.add_theme_constant_override("separation", 30)
	vb.add_child(rh)
	var home := UIKit.round_button("home", 92)
	home.pressed.connect(func(): home_pressed.emit())
	rh.add_child(home)
	var rep := UIKit.round_button("replay", 92)
	rep.pressed.connect(func(): replay_pressed.emit())
	rh.add_child(rep)

	_confetti = CPUParticles2D.new()
	_confetti.amount = 140
	_confetti.lifetime = 3.2
	_confetti.one_shot = true
	_confetti.explosiveness = 0.75
	_confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_confetti.emission_rect_extents = Vector2(360, 10)
	_confetti.direction = Vector2(0, 1)
	_confetti.spread = 40
	_confetti.gravity = Vector2(0, 420)
	_confetti.initial_velocity_min = 80
	_confetti.initial_velocity_max = 380
	_confetti.angular_velocity_min = -540
	_confetti.angular_velocity_max = 540
	_confetti.scale_amount_min = 8
	_confetti.scale_amount_max = 16
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	g.colors = PackedColorArray([Color("ff4fd0"), Color("ffd23f"), Color("5fd61f"), Color("2fb7ff"), Color("9b4dff"), Color("ff7a1f")])
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_confetti.color_initial_ramp = g
	_confetti.position = Vector2(360, -20)
	_confetti.emitting = false
	add_child(_confetti)


func show_result(score: int, coins: int) -> void:
	_score.text = UIKit.fmt(score)
	_coins.text = "+%d" % coins
	open()
	_confetti.position = Vector2(size.x * 0.5, -20)
	_confetti.emission_rect_extents = Vector2(size.x * 0.5, 10)
	_confetti.restart()
	for i in _stars.size():
		var s: Control = _stars[i]
		s.pivot_offset = s.custom_minimum_size * 0.5
		s.scale = Vector2.ZERO
		var tw := create_tween()
		tw.tween_interval(0.25 + i * 0.18)
		tw.tween_property(s, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
