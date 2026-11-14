extends UIScreen
## Top Koleksiyonu: 3x3 ızgara, seçili top yeşil çerçeve + tik, fiyatlar, kilit.

signal back_pressed
signal skin_selected(idx: int)

var _coin_label: Label
var _grid: GridContainer


func _ready() -> void:
	add_backdrop()
	var back := UIKit.round_button("back", 80)
	UIKit.place(back, Vector2(0, 0), Vector2(64, 72), Vector2(80, 80))
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	var cp: Array = UIKit.coin_pill()
	_coin_label = cp[1]
	UIKit.place(cp[0], Vector2(1, 0), Vector2(-150, 72), Vector2(250, 56))
	add_child(cp[0])

	var vb := make_card(640, -40)
	var rib := UIKit.ribbon("TOPLAR", UIKit.RIBBON, 56)
	rib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(rib)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_grid)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 14)
	vb.add_child(dots)
	for i in 4:
		var d := Panel.new()
		d.custom_minimum_size = Vector2(14, 14)
		d.add_theme_stylebox_override("panel", UIKit.style(Color.WHITE if i == 0 else Color("6d4dff"), 7, Color.TRANSPARENT, 0, 0))
		dots.add_child(d)
	GameManager.coins_changed.connect(func(_c): if visible: refresh())


func refresh() -> void:
	_coin_label.text = UIKit.fmt(GameManager.coins())
	for c in _grid.get_children():
		c.queue_free()
	var unlocked: Array = SaveManager.get_v("unlocked")
	var selected := int(SaveManager.get_v("ball"))
	for i in BallSkins.LIST.size():
		var d: Dictionary = BallSkins.LIST[i]
		var owned := unlocked.has(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(190, 200)
		b.focus_mode = Control.FOCUS_NONE
		var sel := i == selected
		var st := UIKit.style(Color("3d22a8"), 26, UIKit.GREEN if sel else Color("6d4dff"), 6 if sel else 3, 6)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		b.add_theme_stylebox_override("pressed", st)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var ic := UIKit.icon("ball", 110)
		ic.ball_color = d["color"]
		ic.pattern = d.has("pattern")
		ic.ball_style = d.get("style", "")
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var price: int = d["price"]
		if not owned and price > 0:
			var ph := HBoxContainer.new()
			ph.alignment = BoxContainer.ALIGNMENT_CENTER
			ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ph.add_child(UIKit.icon("coin", 30))
			ph.add_child(UIKit.label(UIKit.fmt(price), 28, Color.WHITE, 6))
			v.add_child(ph)
		elif not owned:
			var lk := UIKit.icon("lock", 40)
			lk.position = Vector2(130, 140)
			b.add_child(lk)
			ic.modulate = Color(1, 1, 1, 0.55)
		if sel:
			var chk := Panel.new()
			chk.add_theme_stylebox_override("panel", UIKit.style(UIKit.GREEN, 20, Color.WHITE, 3, 0))
			chk.size = Vector2(40, 40)
			chk.position = Vector2(150, 160)
			chk.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ci := UIKit.icon("check", 28)
			ci.position = Vector2(6, 6)
			chk.add_child(ci)
			b.add_child(chk)
		b.pressed.connect(_on_cell.bind(i))
		_grid.add_child(b)


func _on_cell(i: int) -> void:
	AudioManager.play("click")
	var unlocked: Array = SaveManager.get_v("unlocked")
	var price: int = BallSkins.LIST[i]["price"]
	if not unlocked.has(i):
		if price < 0:
			if GameManager.level < -price:
				return
		elif not GameManager.spend_coins(price):
			return
		unlocked.append(i)
		SaveManager.set_v("unlocked", unlocked)
	SaveManager.set_v("ball", i)
	skin_selected.emit(i)
	refresh()
