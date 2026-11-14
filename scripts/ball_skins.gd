class_name BallSkins
extends RefCounted
## Top görünümleri: renk, fiyat ve özel efekt bilgisi.

## LIST ile aynı sırada doku dosyaları (assets/textures/balls/<isim>.png)
const TEXTURES := ["red", "soccer", "blue_stripe", "lava", "galaxy", "gold", "neon", "rainbow", "crystal"]

const LIST := [
	{"name": "Kırmızı", "color": Color("e8213a"), "price": 0},
	{"name": "Futbol", "color": Color("f4f4f4"), "price": 0, "pattern": true, "style": "soccer"},
	{"name": "Mavi", "color": Color("1f8bff"), "price": 0, "style": "stripe"},
	{"name": "Lav", "color": Color("ff5a1f"), "price": 1500, "emit": Color("ff7a00"), "style": "lava"},
	{"name": "Galaksi", "color": Color("8a3dff"), "price": 2000, "emit": Color("d24dff"), "style": "galaxy"},
	{"name": "Altın", "color": Color("ffc21f"), "price": 2500, "metal": true, "style": "gold"},
	{"name": "Neon", "color": Color("12c8d8"), "price": 3000, "emit": Color("00e5ff"), "style": "neon"},
	{"name": "Gökkuşağı", "color": Color("ff4fd0"), "price": 3500, "rainbow": true, "style": "rainbow"},
	{"name": "Kristal", "color": Color("8ec8ff"), "price": -30, "metal": true, "style": "crystal"},
]


static func make_material(idx: int) -> StandardMaterial3D:
	var d: Dictionary = LIST[clampi(idx, 0, LIST.size() - 1)]
	var m := StandardMaterial3D.new()
	m.albedo_color = d["color"]
	var tex_name := str(TEXTURES[clampi(idx, 0, TEXTURES.size() - 1)])
	var tex_path := "res://assets/textures/balls/%s.png" % tex_name
	if ResourceLoader.exists(tex_path):
		m.albedo_texture = load(tex_path)
		m.albedo_color = Color.WHITE
	m.roughness = 0.22
	m.metallic_specular = 0.9
	m.rim_enabled = true
	m.rim = 0.35
	if d.has("metal"):
		m.metallic = 0.35
		m.roughness = 0.18
	if d.has("emit"):
		m.emission_enabled = true
		m.emission = d["emit"]
		m.emission_energy_multiplier = 0.6
		var em_path := "res://assets/textures/balls/%s_emission.png" % tex_name
		if ResourceLoader.exists(em_path):
			m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_texture = load(em_path)
			m.emission_energy_multiplier = 1.4
	return m
