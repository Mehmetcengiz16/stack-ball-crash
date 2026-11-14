extends UIScreen
## Seviye Haritası: su üstünde yüzen adalar, kıvrımlı yol, seviye düğümleri.
## Tamamlanan = yeşil, mevcut = turuncu/sarı, kilitli = gri + kilit.

signal back_pressed
signal play_pressed

var _map: MapView
var _map3d: Map3D


func _ready() -> void:
	if ResourceLoader.exists("res://assets/models/island_a.glb"):
		var svc := SubViewportContainer.new()
		svc.set_anchors_preset(Control.PRESET_FULL_RECT)
		svc.stretch = true
		svc.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(svc)
		var sv := SubViewport.new()
		sv.own_world_3d = true
		sv.msaa_3d = Viewport.MSAA_2X
		svc.add_child(sv)
		_map3d = Map3D.new()
		sv.add_child(_map3d)
	else:
		_map = MapView.new()
		_map.set_anchors_preset(Control.PRESET_FULL_RECT)
		_map.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_map)
	var rib := UIKit.ribbon("SEVİYELER", UIKit.RIBBON, 52)
	UIKit.place(rib, Vector2(0.5, 0), Vector2(0, 90), rib.custom_minimum_size)
	add_child(rib)
	var back := UIKit.round_button("back", 80)
	UIKit.place(back, Vector2(0, 0), Vector2(64, 72), Vector2(92, 74))
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	var play := UIKit.button("OYNA", "play", Vector2(400, 108), 52)
	UIKit.place(play, Vector2(0.5, 1), Vector2(0, -110), Vector2(400, 108))
	play.pressed.connect(func(): play_pressed.emit())
	add_child(play)


func refresh() -> void:
	if _map3d:
		_map3d.build(GameManager.level)
	else:
		_map.current = GameManager.level
		_map.build_nodes()


## Blender modelleriyle 3D harita: su, yüzen adalar, ağaçlar, şelale, yol ve seviye jetonları.
class Map3D extends Node3D:
	const M := "res://assets/models/"
	var _content: Node3D
	var _current_node: Node3D
	var _font: Font
	var _t: float = 0.0

	func _ready() -> void:
		var cam := Camera3D.new()
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		cam.fov = 50
		add_child(cam)
		cam.current = true
		cam.look_at_from_position(Vector3(0, 9.5, 6.0), Vector3(0, 0, -1.4))
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-50, 35, 0)
		sun.light_energy = 1.0
		add_child(sun)
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color("2c3fa8")
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color("dfe8ff")
		e.ambient_light_energy = 0.55
		env.environment = e
		add_child(env)
		var water := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(120, 120)
		water.mesh = pm
		var wm := StandardMaterial3D.new()
		wm.albedo_color = Color("3a8fe0")
		wm.roughness = 0.15
		wm.metallic_specular = 1.0
		water.material_override = wm
		water.position.y = -0.9
		add_child(water)
		_font = UIKit.font()

	func _model(name: String) -> Node3D:
		return (load(M + name + ".glb") as PackedScene).instantiate()

	func _tint(n: Node, m: Material) -> void:
		if n is MeshInstance3D:
			(n as MeshInstance3D).material_override = m
		for c in n.get_children():
			_tint(c, m)

	func _flat(c: Color) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.35
		return m

	func build(current: int) -> void:
		if _content:
			_content.queue_free()
		_content = Node3D.new()
		add_child(_content)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		var first := maxi(1, current - 3)
		var pts: Array[Vector3] = []
		for k in 7:
			var t := float(k) / 6.0
			pts.append(Vector3(sin(t * PI * 2.2 + 0.4) * 2.6, 0.0, lerpf(2.6, -8.0, t)))
		var green := _flat(Color("5fd61f"))
		var grey := _flat(Color("8e8ea8"))
		var path_mat := _flat(Color("f2d9a0"))
		for k in pts.size():
			var lvl := first + k
			var p := pts[k]
			var isl := _model(["island_a", "island_b", "island_c"][k % 3])
			isl.position = p + Vector3(rng.randf_range(-0.3, 0.3), -0.3, 0.3)
			isl.rotation.y = rng.randf() * TAU
			isl.scale = Vector3.ONE * rng.randf_range(1.15, 1.4)
			_content.add_child(isl)
			for tr in rng.randi_range(1, 2):
				var tree := _model("tree_pine")
				var a := rng.randf() * TAU
				tree.position = isl.position + Vector3(cos(a), 0.15, sin(a)) * 0.95
				tree.scale = Vector3.ONE * rng.randf_range(0.8, 1.2)
				_content.add_child(tree)
			if k == 2:
				var wf := _model("waterfall")
				wf.position = isl.position + Vector3(-1.1, 0.1, 0.4)
				wf.rotation.y = PI * 0.5
				_content.add_child(wf)
			var node := _model("level_node")
			node.position = p + Vector3(0, 0.25, 0)
			var big := lvl == current
			node.scale = Vector3.ONE * (1.9 if big else 1.4)
			if lvl < current:
				_tint(node, green)
			elif lvl > current:
				_tint(node, grey)
				var lk := _model("lock")
				lk.position = Vector3(0.45, 0.25, 0.35)
				lk.scale = Vector3.ONE * 0.9
				node.add_child(lk)
			_content.add_child(node)
			if big:
				_current_node = node
			var lb := Label3D.new()
			lb.text = str(lvl)
			lb.font = _font
			lb.font_size = 120
			lb.outline_size = 34
			lb.outline_modulate = Color("8a4a00") if big else (Color("2f7410") if lvl < current else Color("4c4c68"))
			lb.pixel_size = 0.004
			lb.rotation_degrees = Vector3(-90, 0, 0)
			lb.position = Vector3(0, 0.13, 0)
			node.add_child(lb)
			if k < pts.size() - 1:
				var q := pts[k + 1]
				var steps := int(p.distance_to(q) / 0.35)
				for d in range(2, steps - 1):
					var dot := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radius = 0.07
					sm.height = 0.1
					dot.mesh = sm
					dot.material_override = path_mat
					dot.position = p.lerp(q, float(d) / steps) + Vector3(0, 0.12, 0)
					_content.add_child(dot)
		for c in 3:
			var cl := _model(["cloud_a", "cloud_b", "cloud_c"][c])
			cl.position = Vector3([-3.6, 3.8, -3.2][c], 1.6, [2.0, -2.5, -7.0][c])
			_tint(cl, _flat(Color(1, 1, 1)))
			_content.add_child(cl)

	func _process(delta: float) -> void:
		_t += delta
		if _current_node:
			_current_node.position.y = 0.35 + sin(_t * 3.0) * 0.12
			_current_node.rotation.y = sin(_t * 1.5) * 0.25


class MapView extends Control:
	var current: int = 1
	var _nodes: Array = []  # [pos, level]
	var _font: Font

	func build_nodes() -> void:
		_font = UIKit.font()
		_nodes.clear()
		var first := maxi(1, current - 3)
		for k in 7:
			var lvl := first + k
			var t := float(k) / 6.0
			var y := lerpf(size.y * 0.80, size.y * 0.24, t)
			var x := size.x * (0.5 + 0.28 * sin(t * PI * 2.2 + 0.4))
			_nodes.append([Vector2(x, y), lvl])
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED and size.x > 0:
			build_nodes()

	func _draw() -> void:
		# Su
		var bands := 40
		for k in bands:
			var t := float(k) / bands
			draw_rect(Rect2(0, size.y * t, size.x, size.y / bands + 1), Color("2c3fa8").lerp(Color("3fa0e0"), t))
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for k in 40:
			var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
			draw_line(p, p + Vector2(rng.randf_range(20, 50), 0), Color(1, 1, 1, 0.18), 3.0, true)
		# Adalar
		for n in _nodes:
			_island(n[0] + Vector2(rng.randf_range(-30, 30), 40), rng.randf_range(90, 130), rng)
		_island(Vector2(size.x * 0.12, size.y * 0.5), 80, rng)
		_island(Vector2(size.x * 0.9, size.y * 0.62), 70, rng)
		# Şelale
		var wf := Vector2(size.x * 0.12, size.y * 0.5)
		draw_rect(Rect2(wf + Vector2(-14, 30), Vector2(28, 120)), Color(0.85, 0.95, 1.0, 0.85))
		# Yol (kesikli)
		for i in _nodes.size() - 1:
			var a: Vector2 = _nodes[i][0]
			var b: Vector2 = _nodes[i + 1][0]
			draw_line(a, b, Color("f2d9a0"), 22.0, true)
			for d in range(0, int(a.distance_to(b)), 26):
				var p := a.move_toward(b, d)
				draw_circle(p, 5, Color("c9a060"))
		# Düğümler
		for n in _nodes:
			var p: Vector2 = n[0]
			var lvl: int = n[1]
			var r := 58.0 if lvl == current else 44.0
			var col := Color("5fd61f")
			var edge := Color("2f9410")
			if lvl == current:
				col = UIKit.YELLOW
				edge = UIKit.ORANGE
			elif lvl > current:
				col = Color("8e8ea8")
				edge = Color("5c5c78")
			draw_circle(p + Vector2(0, 7), r, Color(0, 0, 0, 0.3))
			draw_circle(p, r, edge)
			draw_circle(p + Vector2(0, -3), r * 0.84, col)
			draw_arc(p + Vector2(0, -3), r * 0.84, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.5), 5, true)
			var txt := str(lvl)
			var fs := 48 if lvl == current else 38
			var ts := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var tp := p + Vector2(-ts.x * 0.5, ts.y * 0.32)
			draw_string_outline(_font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, edge.darkened(0.3))
			draw_string(_font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
			if lvl > current:
				var lp := p + Vector2(r * 0.55, r * 0.5)
				draw_arc(lp + Vector2(0, -8), 10, PI, TAU, 10, Color("2a2a3a"), 5, true)
				draw_rect(Rect2(lp + Vector2(-13, -8), Vector2(26, 22)), Color("2a2a3a"))

	func _island(c: Vector2, r: float, rng: RandomNumberGenerator) -> void:
		var pts := PackedVector2Array()
		var cliff := PackedVector2Array()
		for k in 20:
			var a := k * TAU / 20.0
			var rr := r * rng.randf_range(0.85, 1.1)
			pts.append(c + Vector2(cos(a) * rr, sin(a) * rr * 0.45))
		for k in 20:
			cliff.append(pts[k] + Vector2(0, r * 0.35))
		draw_colored_polygon(cliff, Color("7a5230"))
		draw_colored_polygon(pts, Color("4fc23a"))
		draw_colored_polygon(_shrink(pts, c, 0.75), Color("6ad94a"))
		for k in 3:
			var tp := c + Vector2(rng.randf_range(-r * 0.7, r * 0.7), rng.randf_range(-r * 0.3, 0))
			if tp.distance_to(c) < r * 0.35:
				continue
			draw_colored_polygon(PackedVector2Array([tp + Vector2(0, -r * 0.55), tp + Vector2(r * 0.18, 0), tp + Vector2(-r * 0.18, 0)]), Color("1f7a3a"))

	func _shrink(pts: PackedVector2Array, c: Vector2, f: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append(c + (p - c) * f + Vector2(0, -4))
		return out

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			for n in _nodes:
				if (n[0] as Vector2).distance_to(event.position) < 60 and int(n[1]) == current:
					(get_parent() as Control).call("emit_signal", "play_pressed")
