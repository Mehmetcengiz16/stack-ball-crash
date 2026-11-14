extends UIScreen
## Ayarlar: Müzik, Ses Efektleri, Titreşim anahtarları + Dil.

signal close_pressed

var _toggles: Dictionary = {}


func _ready() -> void:
	add_backdrop()
	var p := UIKit.panel(UIKit.PANEL, 40, UIKit.PANEL_BORDER, 4, 30)
	p.custom_minimum_size.x = 580
	var vb0 := make_card(580)
	var rib := UIKit.ribbon("AYARLAR", UIKit.RIBBON, 52, Color.WHITE, "gear")
	rib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb0.add_child(rib)
	vb0.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	p.add_child(vb)
	_row(vb, "note", "Müzik", "music")
	_row(vb, "speaker", "Ses Efektleri", "sfx")
	_row(vb, "phone", "Titreşim", "vibration")
	var lang := _row_base(vb, "globe", "Dil")
	var tl := UIKit.label("Türkçe  ▾", 30)
	lang.add_child(tl)
	var close := UIKit.button("Tamam", "", Vector2(320, 92), 40)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): close_pressed.emit())
	vb0.add_child(close)


func _row_base(parent: Control, ic: String, text: String) -> HBoxContainer:
	var rp := UIKit.inner_panel(16)
	parent.add_child(rp)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	rp.add_child(h)
	h.add_child(UIKit.icon(ic, 44))
	var l := UIKit.label(text, 32)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


func _row(parent: Control, ic: String, text: String, key: String) -> void:
	var h := _row_base(parent, ic, text)
	var t := Button.new()
	t.toggle_mode = true
	t.focus_mode = Control.FOCUS_NONE
	t.custom_minimum_size = Vector2(100, 52)
	var knob := Panel.new()
	knob.size = Vector2(42, 42)
	knob.position = Vector2(5, 5)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_theme_stylebox_override("panel", UIKit.style(Color.WHITE, 21, Color.TRANSPARENT, 0, 2))
	t.add_child(knob)
	t.toggled.connect(func(on: bool):
		_style_toggle(t, knob, on)
		SaveManager.set_v(key, on)
		AudioManager.play("click")
		if key == "music":
			AudioManager.update_music())
	h.add_child(t)
	_toggles[key] = [t, knob]


func _style_toggle(t: Button, knob: Panel, on: bool) -> void:
	var s := UIKit.style(UIKit.GREEN if on else Color("6b5aa8"), 26, Color.TRANSPARENT, 0, 0)
	for n in ["normal", "hover", "pressed", "hover_pressed"]:
		t.add_theme_stylebox_override(n, s)
	t.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	knob.position.x = 53.0 if on else 5.0


func refresh() -> void:
	for key in _toggles.keys():
		var t: Button = _toggles[key][0]
		var on := bool(SaveManager.get_v(key))
		t.set_pressed_no_signal(on)
		_style_toggle(t, _toggles[key][1], on)
