class_name UIKit
extends RefCounted
## Tasarımdaki stil öğeleri: mor paneller, yeşil ana buton, mor ikincil buton,
## yuvarlak ikon butonlar, kurdele başlıklar ve vektör ikonlar (harici asset yok).

const BG_DARK := Color("1e0f55")
const PANEL := Color("3a1f9a")
const PANEL_BORDER := Color("7c5cff")
const INNER := Color("4a2bbd")
const INNER_BORDER := Color("6d4dff")
const GREEN := Color("5fd61f")
const GREEN_DARK := Color("2f9410")
const PURPLE_BTN := Color("6b4cf0")
const PURPLE_BTN_DARK := Color("3f27a8")
const YELLOW := Color("ffd23f")
const ORANGE := Color("ff9a1f")
const RIBBON := Color("8e2ff0")
const RED := Color("e3233c")
const OUTLINE := Color("2a1470")

static var _font: Font


static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Baloo 2", "Poppins", "Nunito", "Arial Rounded MT Bold", "Segoe UI", "Roboto", "Helvetica", "sans-serif"])
		f.font_weight = 800
		_font = f
	return _font


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 30
	return t


static func style(bg: Color, radius: int = 24, border: Color = Color.TRANSPARENT, bw: int = 0, shadow: int = 6, bottom: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 10
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	if bottom > 0:
		s.border_color = border
		s.border_width_bottom = bottom
	if shadow > 0:
		s.shadow_color = Color(0.05, 0.0, 0.2, 0.45)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.6)
	s.anti_aliasing = true
	return s


static func label(text: String, size: int, color: Color = Color.WHITE, outline: int = 0, outline_color: Color = OUTLINE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", outline_color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _btn_styles(b: Button, c: Color, dark: Color, radius: int, border: Color = Color.TRANSPARENT, bw: int = 0) -> void:
	var n := style(c, radius, dark, 0, 6, 8)
	if bw > 0:
		n.set_border_width_all(bw)
		n.border_color = border
		n.border_width_bottom = 8
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = c.lightened(0.1)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = c.darkened(0.1)
	p.border_width_bottom = 3
	p.content_margin_top = 5
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", n)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Yeşil ana buton (OYNA, Sonraki Seviye, Tekrar Dene, Ödülü Al).
static func button(text: String, icon_kind: String = "", size: Vector2 = Vector2(440, 108), font_size: int = 46, kind: String = "green") -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	b.focus_mode = Control.FOCUS_NONE
	if kind == "green":
		_btn_styles(b, GREEN, GREEN_DARK, int(size.y * 0.5), Color("9dff5c"), 3)
	else:
		_btn_styles(b, PURPLE_BTN, PURPLE_BTN_DARK, int(size.y * 0.5), Color("9b85ff"), 3)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 16)
	b.add_child(hb)
	if icon_kind == "play":
		hb.add_child(icon("play", size.y * 0.42))
	var l := label(text, font_size, Color.WHITE, 8, GREEN_DARK.darkened(0.2) if kind == "green" else PURPLE_BTN_DARK)
	hb.add_child(l)
	if icon_kind != "" and icon_kind != "play":
		hb.add_child(icon(icon_kind, size.y * 0.4))
	b.pressed.connect(func(): AudioManager.play("click"))
	b.button_down.connect(func(): b.pivot_offset = b.size * 0.5; b.scale = Vector2(0.96, 0.96))
	b.button_up.connect(func(): b.scale = Vector2.ONE)
	return b


## Mor yuvarlak ikon buton (ev, tekrar, duraklat, ayar, geri).
static func round_button(kind: String, size: float = 86.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size * 1.15, size * 0.92)
	b.focus_mode = Control.FOCUS_NONE
	_btn_styles(b, PURPLE_BTN, PURPLE_BTN_DARK, int(size * 0.3), Color("a593ff"), 3)
	var ic := icon(kind, size * 0.5)
	ic.position = Vector2(size * 0.325, size * 0.17)
	b.add_child(ic)
	b.pressed.connect(func(): AudioManager.play("click"))
	return b


## Menüdeki kare kutucuk buton (Günlük Ödül / Görevler / Toplar).
static func tile_button(kind: String, text: String, badge: bool = false) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(124, 124)
	b.focus_mode = Control.FOCUS_NONE
	_btn_styles(b, Color("5a3be0"), PURPLE_BTN_DARK, 26, Color("9b85ff"), 3)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 2)
	b.add_child(vb)
	var ic := icon(kind, 56)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(ic)
	vb.add_child(label(text, 21, Color.WHITE, 5))
	if badge:
		var d := Panel.new()
		d.add_theme_stylebox_override("panel", style(RED, 16, Color.WHITE, 3, 0))
		d.size = Vector2(32, 32)
		d.position = Vector2(100, -10)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dl := label("1", 18)
		dl.set_anchors_preset(Control.PRESET_FULL_RECT)
		d.add_child(dl)
		b.add_child(d)
	b.pressed.connect(func(): AudioManager.play("click"))
	return b


static func panel(bg: Color = PANEL, radius: int = 40, border: Color = PANEL_BORDER, bw: int = 4, pad: int = 28) -> PanelContainer:
	var p := PanelContainer.new()
	var s := style(bg, radius, border, bw, 14)
	s.set_content_margin_all(pad)
	p.add_theme_stylebox_override("panel", s)
	return p


static func inner_panel(pad: int = 18) -> PanelContainer:
	return panel(INNER, 24, INNER_BORDER, 3, pad)


## Kurdele başlık (kıvrık uçlu, kemerli bant) — SEVİYE TAMAMLANDI!, TOPLAR, AYARLAR...
static func ribbon(text: String, color: Color = RIBBON, size: int = 46, text_color: Color = Color.WHITE, icon_kind: String = "") -> Control:
	var b := Banner.new()
	b.color = color
	var lines := text.split("
")
	var longest := 0
	for l in lines:
		longest = maxi(longest, l.length())
	var icon_w := size * 1.3 if icon_kind != "" else 0.0
	b.custom_minimum_size = Vector2(longest * size * 0.56 + icon_w + 110, lines.size() * size * 1.12 + 44)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_bottom = -14
	hb.offset_top = 2
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(hb)
	if icon_kind != "":
		var ic := icon(icon_kind, size * 1.2)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
	var l := label(text, size, text_color, 12, color.darkened(0.6))
	l.add_theme_constant_override("line_spacing", -int(size * 0.3))
	l.add_theme_constant_override("shadow_offset_y", 4)
	l.add_theme_color_override("font_shadow_color", color.darkened(0.6))
	hb.add_child(l)
	b.label = l
	return b


## Defne yaprağı (Seviye Tamamlandı kenarları).
static func laurel(flip: bool, size: float = 110.0) -> Control:
	var i := icon("laurel", size)
	i.flip = flip
	return i


class Banner extends Control:
	var color: Color = UIKit.RIBBON
	var label: Label

	func _draw() -> void:
		var w := size.x
		var h := size.y - 12.0
		var tail := 34.0
		var arch := h * 0.16
		var dark := color.darkened(0.45)
		# Arka kuyruklar
		for side in [0, 1]:
			var x0 := 0.0 if side == 0 else w
			var sgn := 1.0 if side == 0 else -1.0
			var ty := h * 0.3 + arch
			var pts := PackedVector2Array([Vector2(x0, ty), Vector2(x0 + sgn * tail * 1.6, ty), Vector2(x0 + sgn * tail * 1.6, h + 10 + arch),
				Vector2(x0, h + 10 + arch), Vector2(x0 + sgn * tail * 0.55, (ty + h + 10 + arch) * 0.5)])
			draw_colored_polygon(pts, color.darkened(0.25))
			draw_colored_polygon(PackedVector2Array([Vector2(x0 + sgn * tail, h + arch * 0.9), Vector2(x0 + sgn * tail * 1.6, h + 10 + arch),
				Vector2(x0 + sgn * tail * 1.6, h * 0.8 + arch)]), dark)
		# Gövde (kemerli)
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		var n := 24
		for k in n + 1:
			var t := float(k) / n
			var x := lerpf(tail, w - tail, t)
			var y := arch * (1.0 - sin(PI * t))
			top.append(Vector2(x, y))
			bot.append(Vector2(x, y + h * 0.82))
		var body := PackedVector2Array(top)
		for k in range(n, -1, -1):
			body.append(bot[k])
		draw_colored_polygon(body, color)
		var hi := PackedVector2Array()
		for k in n + 1:
			hi.append(top[k] + Vector2(0, 5))
		draw_polyline(hi, color.lightened(0.35), 5.0, true)
		draw_polyline(body + PackedVector2Array([body[0]]), color.lightened(0.5), 3.0, true)


## Coin göstergesi (sağ üst: coin + sayı + yeşil artı).
static func coin_pill() -> Array:
	var p := PanelContainer.new()
	var s := style(Color(0.08, 0.02, 0.25, 0.6), 30, Color("6d4dff"), 2, 0)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	p.add_child(hb)
	hb.add_child(icon("coin", 44))
	var l := label("0", 30, Color.WHITE, 6)
	l.custom_minimum_size.x = 92
	hb.add_child(l)
	var plus := Panel.new()
	plus.custom_minimum_size = Vector2(40, 40)
	plus.add_theme_stylebox_override("panel", style(GREEN, 10, GREEN_DARK, 0, 0, 4))
	var pi := icon("plus", 28)
	pi.position = Vector2(6, 5)
	plus.add_child(pi)
	hb.add_child(plus)
	return [p, l]


static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


## Kontrolü ekran içinde bir çapa noktasına göre ortalar.
static func place(c: Control, anchor: Vector2, center: Vector2, size: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = center.x - size.x * 0.5
	c.offset_right = center.x + size.x * 0.5
	c.offset_top = center.y - size.y * 0.5
	c.offset_bottom = center.y + size.y * 0.5


static func icon(kind: String, size: float, color: Color = Color.WHITE) -> Icon:
	var i := Icon.new()
	i.kind = kind
	i.tint = color
	i.custom_minimum_size = Vector2(size, size)
	i.size = Vector2(size, size)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


## Vektör ikon çizici.
class Icon extends Control:
	var kind: String = "coin"
	var tint: Color = Color.WHITE
	var ball_color: Color = Color.RED
	var pattern: bool = false
	var ball_style: String = ""
	var flip: bool = false
	var cracked: bool = false

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size * 0.5
		var r := s * 0.5
		match kind:
			"coin":
				draw_circle(c, r, Color("e08a00"))
				draw_circle(c + Vector2(0, -r * 0.06), r * 0.86, Color("ffc928"))
				draw_circle(c + Vector2(0, -r * 0.06), r * 0.6, Color("ffdc5a"))
				draw_arc(c + Vector2(0, -r * 0.06), r * 0.6, 0, TAU, 24, Color("e5a100"), r * 0.08, true)
			"star", "star_off":
				var col := Color("ffd23f") if kind == "star" else Color("b6aee0")
				var pts := _star(c, r, r * 0.48)
				draw_colored_polygon(pts, col.darkened(0.3))
				draw_colored_polygon(_star(c + Vector2(0, -r * 0.05), r * 0.86, r * 0.4), col)
			"crown":
				var pts := PackedVector2Array([
					c + Vector2(-r * 0.9, -r * 0.45), c + Vector2(-r * 0.45, 0), c + Vector2(0, -r * 0.75),
					c + Vector2(r * 0.45, 0), c + Vector2(r * 0.9, -r * 0.45), c + Vector2(r * 0.75, r * 0.6),
					c + Vector2(-r * 0.75, r * 0.6)])
				draw_colored_polygon(pts, Color("ffcf2e"))
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color("e08a00"), r * 0.08, true)
				for p in [pts[0], pts[2], pts[4]]:
					draw_circle(p, r * 0.13, Color("ffe46b"))
				draw_rect(Rect2(c + Vector2(-r * 0.75, r * 0.38), Vector2(r * 1.5, r * 0.22)), Color("e5a100"))
			"flame":
				draw_colored_polygon(_flame(c, r), Color("ff4a14"))
				draw_colored_polygon(_flame(c + Vector2(0, r * 0.2), r * 0.62), Color("ffb01f"))
				draw_colored_polygon(_flame(c + Vector2(0, r * 0.42), r * 0.32), Color("fff3a0"))
			"play":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.8), c + Vector2(r * 0.85, 0), c + Vector2(-r * 0.6, r * 0.8)]), tint)
			"pause":
				draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.75), Vector2(r * 0.4, r * 1.5)), tint)
				draw_rect(Rect2(c + Vector2(r * 0.2, -r * 0.75), Vector2(r * 0.4, r * 1.5)), tint)
			"home":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.9), c + Vector2(r * 0.95, 0), c + Vector2(r * 0.65, 0),
					c + Vector2(r * 0.65, r * 0.85), c + Vector2(-r * 0.65, r * 0.85), c + Vector2(-r * 0.65, 0), c + Vector2(-r * 0.95, 0)]), tint)
				draw_rect(Rect2(c + Vector2(-r * 0.2, r * 0.3), Vector2(r * 0.4, r * 0.55)), UIKit.PURPLE_BTN)
			"replay":
				draw_arc(c, r * 0.62, -PI * 0.35, PI * 1.45, 28, tint, r * 0.24, true)
				var a := -PI * 0.35
				var tip := c + Vector2(cos(a), sin(a)) * r * 0.62
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-r * 0.4, -r * 0.2), tip + Vector2(r * 0.25, -r * 0.35), tip + Vector2(r * 0.1, r * 0.35)]), tint)
			"gear":
				for k in 8:
					var ang := k * TAU / 8.0
					var d := Vector2(cos(ang), sin(ang))
					var t := Vector2(-d.y, d.x)
					draw_colored_polygon(PackedVector2Array([c + d * r * 0.5 + t * r * 0.17, c + d * r * 0.98 + t * r * 0.14,
						c + d * r * 0.98 - t * r * 0.14, c + d * r * 0.5 - t * r * 0.17]), tint)
				draw_circle(c, r * 0.68, tint)
				draw_circle(c, r * 0.3, UIKit.PURPLE_BTN)
			"check":
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, 0), c + Vector2(-r * 0.15, r * 0.5), c + Vector2(r * 0.7, -r * 0.55)]), tint, r * 0.32, true)
			"back":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.9, 0), c + Vector2(-r * 0.1, -r * 0.75), c + Vector2(-r * 0.1, -r * 0.3),
					c + Vector2(r * 0.85, -r * 0.3), c + Vector2(r * 0.85, r * 0.3), c + Vector2(-r * 0.1, r * 0.3), c + Vector2(-r * 0.1, r * 0.75)]), tint)
			"lock":
				draw_arc(c + Vector2(0, -r * 0.15), r * 0.42, PI, TAU, 16, tint, r * 0.18, true)
				draw_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.15), Vector2(r * 1.24, r * 0.95)), tint)
				draw_circle(c + Vector2(0, r * 0.3), r * 0.14, UIKit.PANEL)
			"plus":
				draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.17), Vector2(r * 1.4, r * 0.34)), tint)
				draw_rect(Rect2(c + Vector2(-r * 0.17, -r * 0.7), Vector2(r * 0.34, r * 1.4)), tint)
			"gift":
				draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.25), Vector2(r * 1.6, r * 1.05)), Color("a24dff"))
				draw_rect(Rect2(c + Vector2(-r * 0.9, -r * 0.5), Vector2(r * 1.8, r * 0.35)), Color("c07bff"))
				draw_rect(Rect2(c + Vector2(-r * 0.14, -r * 0.5), Vector2(r * 0.28, r * 1.3)), Color("ffd23f"))
				draw_circle(c + Vector2(-r * 0.3, -r * 0.65), r * 0.22, Color("ffd23f"))
				draw_circle(c + Vector2(r * 0.3, -r * 0.65), r * 0.22, Color("ffd23f"))
			"calendar":
				draw_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.6), Vector2(r * 1.7, r * 1.45)), Color.WHITE)
				draw_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.75), Vector2(r * 1.7, r * 0.45)), UIKit.RED)
				for k in 2:
					draw_circle(c + Vector2(-r * 0.25 + k * r * 0.5, r * 0.25), r * 0.2, UIKit.RED)
			"target":
				draw_circle(c, r * 0.9, UIKit.RED)
				draw_circle(c, r * 0.65, Color.WHITE)
				draw_circle(c, r * 0.4, UIKit.RED)
				draw_circle(c, r * 0.16, Color.WHITE)
				draw_line(c, c + Vector2(r * 0.85, -r * 0.85), Color("ffd23f"), r * 0.12, true)
			"note":
				draw_line(c + Vector2(-r * 0.3, r * 0.5), c + Vector2(-r * 0.3, -r * 0.7), tint, r * 0.14)
				draw_line(c + Vector2(r * 0.6, r * 0.3), c + Vector2(r * 0.6, -r * 0.9), tint, r * 0.14)
				draw_line(c + Vector2(-r * 0.3, -r * 0.7), c + Vector2(r * 0.6, -r * 0.9), tint, r * 0.24)
				draw_circle(c + Vector2(-r * 0.5, r * 0.55), r * 0.26, tint)
				draw_circle(c + Vector2(r * 0.4, r * 0.35), r * 0.26, tint)
			"speaker":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.9, -r * 0.3), c + Vector2(-r * 0.45, -r * 0.3), c + Vector2(0, -r * 0.75),
					c + Vector2(0, r * 0.75), c + Vector2(-r * 0.45, r * 0.3), c + Vector2(-r * 0.9, r * 0.3)]), tint)
				draw_arc(c, r * 0.45, -0.8, 0.8, 12, tint, r * 0.12, true)
				draw_arc(c, r * 0.8, -0.8, 0.8, 12, tint, r * 0.12, true)
			"phone":
				draw_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.8), Vector2(r * 0.8, r * 1.6)), tint, false, r * 0.14)
				draw_line(c + Vector2(-r * 0.9, -r * 0.3), c + Vector2(-r * 0.9, r * 0.3), tint, r * 0.12)
				draw_line(c + Vector2(r * 0.9, -r * 0.3), c + Vector2(r * 0.9, r * 0.3), tint, r * 0.12)
			"globe":
				draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.8), Vector2(r * 1.4, r * 1.6)), tint, false, r * 0.12)
				for k in 3:
					draw_line(c + Vector2(-r * 0.4, -r * 0.4 + k * r * 0.4), c + Vector2(r * 0.4, -r * 0.4 + k * r * 0.4), tint, r * 0.1)
			"gem":
				var pts := PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.3), c + Vector2(-r * 0.4, -r * 0.75), c + Vector2(r * 0.4, -r * 0.75),
					c + Vector2(r * 0.8, -r * 0.3), c + Vector2(0, r * 0.85)])
				draw_colored_polygon(pts, Color("e24dff"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.4, -r * 0.3), c + Vector2(r * 0.4, -r * 0.3), c + Vector2(0, r * 0.85)]), Color("f59bff"))
			"coins":
				for k in 3:
					var o := c + Vector2((k - 1) * r * 0.45, r * 0.25 - (1 if k == 1 else 0) * r * 0.3)
					draw_circle(o, r * 0.42, Color("e08a00"))
					draw_circle(o + Vector2(0, -r * 0.05), r * 0.35, Color("ffc928"))
			"ball":
				_draw_ball(c, r)
			"swirl":
				draw_arc(c, r * 0.9, PI * 0.85, PI * 2.15, 48, Color(0.45, 0.85, 1.0, 0.45), r * 0.07, true)
				draw_arc(c, r * 0.78, PI * 0.95, PI * 2.05, 48, Color(1, 0.6, 0.2, 0.55), r * 0.05, true)
				draw_arc(c, r * 0.66, PI * 1.05, PI * 1.95, 48, Color(1, 1, 1, 0.35), r * 0.035, true)
			"laurel":
				var sg := -1.0 if flip else 1.0
				var pts := PackedVector2Array()
				for k in 9:
					var t := float(k) / 8.0
					pts.append(c + Vector2(sg * (-r * 0.2 - sin(t * PI * 0.9) * r * 0.55), r * 0.9 - t * r * 1.8))
				draw_polyline(pts, Color("e5a100"), r * 0.08, true)
				for k in range(1, 8):
					var p0 := pts[k]
					for side in [-1.0, 1.0]:
						var dir := (pts[k + 1] - pts[k - 1]).normalized().rotated(side * 0.9)
						var leaf := _leaf(p0, dir, r * 0.32)
						draw_colored_polygon(leaf, Color("ffcf2e"))
						draw_polyline(leaf, Color("e08a00"), 2.0, true)

	func _leaf(p: Vector2, dir: Vector2, l: float) -> PackedVector2Array:
		var n := Vector2(-dir.y, dir.x)
		return PackedVector2Array([p, p + dir * l * 0.5 + n * l * 0.28, p + dir * l, p + dir * l * 0.5 - n * l * 0.28])

	func _band(c: Vector2, r: float, y0: float, y1: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var steps := 10
		for k in steps + 1:
			var y := lerpf(y0, y1, float(k) / steps)
			pts.append(c + Vector2(sqrt(maxf(0.0, r * r - y * y)), y))
		for k in range(steps, -1, -1):
			var y := lerpf(y0, y1, float(k) / steps)
			pts.append(c + Vector2(-sqrt(maxf(0.0, r * r - y * y)), y))
		return pts

	func _draw_ball(c: Vector2, r: float) -> void:
		var rr := r * 0.86
		draw_circle(c + Vector2(r * 0.04, r * 0.08), r * 0.92, Color(0, 0, 0, 0.28))
		draw_circle(c, rr, ball_color.darkened(0.35))
		draw_circle(c + Vector2(-r * 0.05, -r * 0.06), rr * 0.9, ball_color)
		match ball_style:
			"soccer":
				draw_colored_polygon(_ngon(c, r * 0.28, 5, -PI / 2), Color("1e1e1e"))
				for k in 5:
					var ang := -PI / 2 + k * TAU / 5
					draw_colored_polygon(_ngon(c + Vector2(cos(ang), sin(ang)) * rr * 0.86, r * 0.17, 5, ang + PI / 2), Color("1e1e1e"))
					draw_line(c + Vector2(cos(ang), sin(ang)) * r * 0.28, c + Vector2(cos(ang), sin(ang)) * rr * 0.7, Color("888888"), 2.0, true)
			"stripe":
				draw_colored_polygon(_band(c, rr * 0.9, -rr * 0.2, rr * 0.12), ball_color.lightened(0.35))
				draw_colored_polygon(_band(c, rr * 0.9, rr * 0.4, rr * 0.55), ball_color.darkened(0.25))
			"lava":
				draw_circle(c, rr * 0.9, Color("3a0d06"))
				var rng := RandomNumberGenerator.new()
				rng.seed = 7
				for k in 9:
					var a := rng.randf() * TAU
					var p0 := c + Vector2(cos(a), sin(a)) * rr * rng.randf_range(0.0, 0.5)
					var pts := PackedVector2Array([p0])
					for j in 3:
						p0 += Vector2(cos(a + rng.randf_range(-0.8, 0.8)), sin(a + rng.randf_range(-0.8, 0.8))) * rr * 0.22
						if p0.distance_to(c) < rr * 0.88:
							pts.append(p0)
					if pts.size() > 1:
						draw_polyline(pts, Color("ff8a1a"), r * 0.08, true)
			"galaxy":
				draw_circle(c, rr * 0.9, Color("3a1580"))
				draw_arc(c, rr * 0.5, 0.3, 4.0, 20, Color("ff5fd8"), r * 0.18, true)
				draw_arc(c, rr * 0.25, 3.0, 6.5, 16, Color("8fd0ff"), r * 0.12, true)
				var rng2 := RandomNumberGenerator.new()
				rng2.seed = 3
				for k in 14:
					var a2 := rng2.randf() * TAU
					draw_circle(c + Vector2(cos(a2), sin(a2)) * rr * rng2.randf_range(0.1, 0.85), r * 0.04, Color.WHITE)
			"gold":
				for k in range(-3, 4):
					draw_line(c + Vector2(k * rr * 0.26, -rr * 0.8), c + Vector2(k * rr * 0.26, rr * 0.8), ball_color.darkened(0.3), 2.0)
					draw_line(c + Vector2(-rr * 0.8, k * rr * 0.26), c + Vector2(rr * 0.8, k * rr * 0.26), ball_color.darkened(0.3), 2.0)
			"neon":
				draw_circle(c, rr * 0.9, Color("0b3a44"))
				for k in 6:
					var a3 := k * TAU / 6
					draw_colored_polygon(_ngon(c + Vector2(cos(a3), sin(a3)) * rr * 0.5, r * 0.2, 6, 0), Color("00e5ff", 0.0))
					draw_polyline(_ngon(c + Vector2(cos(a3), sin(a3)) * rr * 0.5, r * 0.2, 6, 0) + PackedVector2Array([_ngon(c + Vector2(cos(a3), sin(a3)) * rr * 0.5, r * 0.2, 6, 0)[0]]), Color("3ff3ff"), 2.5, true)
				draw_polyline(_ngon(c, r * 0.2, 6, 0) + PackedVector2Array([_ngon(c, r * 0.2, 6, 0)[0]]), Color("3ff3ff"), 2.5, true)
			"rainbow":
				var cols := [Color("ff3b3b"), Color("ff9a1f"), Color("ffe03f"), Color("5fd61f"), Color("2fb7ff"), Color("9b4dff")]
				for k in cols.size():
					var y0 := lerpf(-rr * 0.9, rr * 0.9, float(k) / cols.size())
					var y1 := lerpf(-rr * 0.9, rr * 0.9, float(k + 1) / cols.size())
					draw_colored_polygon(_band(c, rr * 0.9, y0, y1), cols[k])
			"crystal":
				draw_colored_polygon(_star_n(c, r * 0.98, r * 0.6, 8), Color("cfe8ff"))
				draw_colored_polygon(_star_n(c, r * 0.75, r * 0.45, 8), Color("8ec8ff"))
		if cracked:
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.1, -rr * 0.85), c + Vector2(r * 0.05, -r * 0.4), c + Vector2(-r * 0.15, -r * 0.1),
				c + Vector2(r * 0.12, r * 0.15), c + Vector2(-r * 0.05, r * 0.45)]), Color("4a0410"), r * 0.08, true)
			draw_polyline(PackedVector2Array([c + Vector2(r * 0.05, -r * 0.4), c + Vector2(r * 0.4, -r * 0.5)]), Color("4a0410"), r * 0.06, true)
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.15, -r * 0.1), c + Vector2(-r * 0.5, 0)]), Color("4a0410"), r * 0.06, true)
		draw_circle(c + Vector2(-r * 0.3, -r * 0.34), r * 0.17, Color(1, 1, 1, 0.7))
		draw_circle(c + Vector2(-r * 0.4, -r * 0.18), r * 0.07, Color(1, 1, 1, 0.5))

	func _star_n(c: Vector2, ro: float, ri: float, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in n * 2:
			var ang := -PI / 2 + k * PI / n
			pts.append(c + Vector2(cos(ang), sin(ang)) * (ro if k % 2 == 0 else ri))
		return pts

	func _star(c: Vector2, ro: float, ri: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in 10:
			var ang := -PI / 2 + k * PI / 5
			var rr := ro if k % 2 == 0 else ri
			pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
		return pts

	func _ngon(c: Vector2, r: float, n: int, start: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in n:
			var ang := start + k * TAU / n
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		return pts

	func _flame(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in 24:
			var t := float(k) / 24.0 * TAU
			var x := sin(t) * r * 0.62
			var y := -cos(t) * r * 0.75
			if y < 0:
				x *= (1.0 + y / (r * 0.75)) * 0.95 + 0.05
				y *= 1.35
			pts.append(c + Vector2(x, y + r * 0.15))
		return pts


## Mockup'taki derin mor gökyüzü: dikey gradyan + yumuşak bulutlar + parıltılar.
class Backdrop extends Control:
	var top_color: Color = Color("3d189a")
	var bottom_color: Color = Color("b56ee0")
	var clouds: bool = true

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func set_colors(t: Color, b: Color) -> void:
		top_color = t
		bottom_color = b
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var bands := 48
		for k in bands:
			var t := float(k) / bands
			draw_rect(Rect2(0, size.y * t, size.x, size.y / bands + 1), top_color.lerp(bottom_color, t * t * 0.9 + t * 0.1))
		if not clouds:
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		# Swirl / ışık halkası
		draw_arc(Vector2(size.x * 0.5, size.y * 0.16), size.x * 0.42, PI * 0.9, PI * 2.1, 40, Color(0.6, 0.85, 1.0, 0.10), 26, true)
		draw_arc(Vector2(size.x * 0.5, size.y * 0.16), size.x * 0.32, PI * 1.0, PI * 2.0, 40, Color(1, 1, 1, 0.07), 14, true)
		for layer in 3:
			var y := size.y * (0.55 + layer * 0.17)
			var a := 0.07 + layer * 0.05
			var col := bottom_color.lightened(0.25 + layer * 0.1)
			col.a = a
			for k in 7:
				var x := size.x * (float(k) / 6.0) + rng.randf_range(-40, 40)
				var rad := size.x * rng.randf_range(0.14, 0.24)
				draw_circle(Vector2(x, y + rng.randf_range(-30, 30)), rad, col)
		for k in 26:
			var p := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.7)
			var s := rng.randf_range(1.5, 3.5)
			draw_circle(p, s, Color(1, 1, 1, rng.randf_range(0.25, 0.7)))
