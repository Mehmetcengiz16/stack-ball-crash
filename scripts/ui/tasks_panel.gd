extends UIScreen
## Görevler: ilerleme çubuklu görev listesi, tamamlananlar coin verir.

signal close_pressed

const TASKS := [
	{"id": "rings10", "text": "10 halka kır", "stat": "rings_broken", "goal": 10, "reward": 50},
	{"id": "levels3", "text": "3 seviye tamamla", "stat": "levels_done", "goal": 3, "reward": 100},
	{"id": "fire2", "text": "Ateş topunu 2 kez kullan", "stat": "fireballs", "goal": 2, "reward": 75},
	{"id": "rings100", "text": "100 halka kır", "stat": "rings_broken", "goal": 100, "reward": 250},
	{"id": "levels10", "text": "10 seviye tamamla", "stat": "levels_done", "goal": 10, "reward": 400},
]

var _list: VBoxContainer


func _ready() -> void:
	add_backdrop()
	var vb := make_card(620)
	var rib := UIKit.ribbon("GÖREVLER", UIKit.RIBBON, 50, Color.WHITE, "target")
	rib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(rib)
	var p := UIKit.panel(UIKit.PANEL, 40, UIKit.PANEL_BORDER, 4, 22)
	vb.add_child(p)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 14)
	p.add_child(_list)
	var close := UIKit.round_button("back", 80)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): close_pressed.emit())
	vb.add_child(close)


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var claimed: Array = SaveManager.get_v("tasks_claimed")
	for t in TASKS:
		var prog := mini(int(SaveManager.get_v(t["stat"])), int(t["goal"]))
		var done := prog >= int(t["goal"])
		var is_claimed := claimed.has(t["id"])
		var row := UIKit.inner_panel(16)
		_list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		row.add_child(h)
		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(left)
		var tl := UIKit.label(t["text"], 28)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		left.add_child(tl)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(300, 30)
		bar.show_percentage = false
		bar.max_value = float(t["goal"])
		bar.value = prog
		bar.add_theme_stylebox_override("background", UIKit.style(Color("2a1470"), 15, Color("9b85ff"), 2, 0))
		bar.add_theme_stylebox_override("fill", UIKit.style(UIKit.GREEN if done else UIKit.ORANGE, 15, Color.TRANSPARENT, 0, 0))
		var bl := UIKit.label("%d/%d" % [prog, t["goal"]], 20, Color.WHITE, 5)
		bl.set_anchors_preset(Control.PRESET_FULL_RECT)
		bar.add_child(bl)
		var bh := HBoxContainer.new()
		bh.add_child(bar)
		if done:
			bh.add_child(UIKit.icon("check", 34, UIKit.GREEN))
		left.add_child(bh)
		var right := VBoxContainer.new()
		right.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(right)
		var ci := UIKit.icon("coin", 40)
		ci.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		right.add_child(ci)
		if done and not is_claimed:
			var b := UIKit.button("+%d" % t["reward"], "", Vector2(110, 56), 26)
			b.pressed.connect(_claim.bind(t))
			right.add_child(b)
		else:
			right.add_child(UIKit.label("✓" if is_claimed else "+%d" % t["reward"], 30, Color.WHITE, 6))


func _claim(t: Dictionary) -> void:
	var claimed: Array = SaveManager.get_v("tasks_claimed")
	if claimed.has(t["id"]):
		return
	claimed.append(t["id"])
	SaveManager.set_v("tasks_claimed", claimed)
	GameManager.add_coins(int(t["reward"]))
	AudioManager.play("combo")
	refresh()
