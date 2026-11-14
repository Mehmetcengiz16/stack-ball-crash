extends UIScreen
## Ana Menü: logo, coin, Günlük Ödül / Görevler / Toplar, OYNA, seviye, en yüksek skor.

signal play_pressed
signal shop_pressed
signal settings_pressed
signal daily_pressed
signal tasks_pressed
signal map_pressed

var _coin_label: Label
var _level_label: Label
var _best_label: Label
var _logo: Control


func _ready() -> void:
	var gear := UIKit.round_button("gear", 84)
	UIKit.place(gear, Vector2(0, 0), Vector2(66, 72), Vector2(84, 84))
	gear.pressed.connect(func(): settings_pressed.emit())
	add_child(gear)

	var cp: Array = UIKit.coin_pill()
	var pill: Control = cp[0]
	_coin_label = cp[1]
	UIKit.place(pill, Vector2(1, 0), Vector2(-150, 72), Vector2(250, 56))
	add_child(pill)

	# Logo
	var swirl := UIKit.icon("swirl", 330)
	UIKit.place(swirl, Vector2(0.5, 0), Vector2(0, 175), Vector2(330, 330))
	add_child(swirl)
	var lball := UIKit.icon("ball", 110)
	lball.ball_color = UIKit.RED
	UIKit.place(lball, Vector2(0.5, 0), Vector2(0, 165), Vector2(110, 110))
	add_child(lball)
	_logo = VBoxContainer.new()
	_logo.add_theme_constant_override("separation", -34)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.place(_logo, Vector2(0.5, 0), Vector2(0, 340), Vector2(560, 300))
	add_child(_logo)
	var l1 := UIKit.label("STACK", 118, Color.WHITE, 26, Color("4a1aa8"))
	var l2 := UIKit.label("BALL", 132, UIKit.YELLOW, 26, Color("4a1aa8"))
	l1.add_theme_constant_override("shadow_offset_y", 10)
	l1.add_theme_color_override("font_shadow_color", Color(0.1, 0, 0.3, 0.6))
	l2.add_theme_constant_override("shadow_offset_y", 10)
	l2.add_theme_color_override("font_shadow_color", Color(0.1, 0, 0.3, 0.6))
	_logo.add_child(l1)
	_logo.add_child(l2)
	var crash := UIKit.ribbon("CRASH", Color("7a24e0"), 50)
	crash.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_logo.add_child(crash)

	# Sol / sağ kutucuklar
	var daily := UIKit.tile_button("calendar", "Günlük\nÖdül", true)
	UIKit.place(daily, Vector2(0, 0.5), Vector2(84, 80), Vector2(124, 124))
	daily.pressed.connect(func(): daily_pressed.emit())
	add_child(daily)
	var tasks := UIKit.tile_button("target", "Görevler", true)
	UIKit.place(tasks, Vector2(0, 0.5), Vector2(84, 230), Vector2(124, 124))
	tasks.pressed.connect(func(): tasks_pressed.emit())
	add_child(tasks)
	var shop := UIKit.tile_button("ball", "Toplar")
	(shop.get_child(0).get_child(0) as UIKit.Icon).ball_color = UIKit.RED
	UIKit.place(shop, Vector2(1, 0.5), Vector2(-84, 230), Vector2(124, 124))
	shop.pressed.connect(func(): shop_pressed.emit())
	add_child(shop)

	# Alt: OYNA + seviye + en yüksek skor
	var play := UIKit.button("OYNA", "play", Vector2(460, 120), 58)
	UIKit.place(play, Vector2(0.5, 1), Vector2(0, -290), Vector2(460, 120))
	play.pressed.connect(func(): play_pressed.emit())
	add_child(play)

	var lvp := PanelContainer.new()
	var ls := UIKit.style(Color("2c1580"), 20, Color("6d4dff"), 2, 0)
	ls.content_margin_left = 30
	ls.content_margin_right = 30
	lvp.add_theme_stylebox_override("panel", ls)
	_level_label = UIKit.label("Seviye 1", 30)
	lvp.add_child(_level_label)
	lvp.mouse_filter = Control.MOUSE_FILTER_STOP
	lvp.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: AudioManager.play("click"); map_pressed.emit())
	var lvc := UIScreen.centered(lvp)
	UIKit.place(lvc, Vector2(0.5, 1), Vector2(0, -200), Vector2(300, 48))
	add_child(lvc)

	var bp := PanelContainer.new()
	var bs := UIKit.style(Color(0.1, 0.03, 0.3, 0.75), 26, Color("6d4dff"), 2, 0)
	bs.content_margin_left = 22
	bs.content_margin_right = 30
	bs.content_margin_top = 6
	bs.content_margin_bottom = 6
	bp.add_theme_stylebox_override("panel", bs)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 14)
	bp.add_child(bh)
	bh.add_child(UIKit.icon("crown", 58))
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", -6)
	bh.add_child(bv)
	bv.add_child(UIKit.label("En Yüksek Skor", 22))
	_best_label = UIKit.label("0", 34, Color.WHITE, 6)
	bv.add_child(_best_label)
	var bc := UIScreen.centered(bp)
	UIKit.place(bc, Vector2(0.5, 1), Vector2(0, -120), Vector2(360, 90))
	add_child(bc)

	GameManager.coins_changed.connect(func(_c): refresh())


func refresh() -> void:
	_coin_label.text = UIKit.fmt(GameManager.coins())
	_level_label.text = "Seviye %d" % GameManager.level
	_best_label.text = UIKit.fmt(GameManager.best())


func _process(_d: float) -> void:
	if visible and _logo:
		_logo.pivot_offset = _logo.size * 0.5
		var t := Time.get_ticks_msec() * 0.002
		_logo.scale = Vector2.ONE * (1.0 + sin(t) * 0.02)
