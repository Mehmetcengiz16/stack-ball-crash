class_name TowerController
extends Node3D
## Kule: merkez kolon + dönen halkalar. Halka verisi (dilim tipleri) burada tutulur.

signal built(ring_count: int)

const SLICES := 12
const SLICE_ANGLE := TAU / SLICES
const INSET := 0.035  ## dilimler arası küçük açı boşluğu (blok görünümü)

@export var ring_spacing: float = 0.82
@export var ring_thickness: float = 0.46
@export var inner_radius: float = 0.55
@export var outer_radius: float = 2.05
@export var visible_range: float = 16.0

var rotation_speed: float = 0.8
var wobble: bool = false
var ring_count: int = 0
var palette: Array = []
var pivot: Node3D
var effects: Node3D
var rings: Array = []  # {node, types, broken}

var _slice_mesh: ArrayMesh
var _safe_mat: StandardMaterial3D
var _black_mat: StandardMaterial3D
var _finish_mat: StandardMaterial3D
var _pole_mat: StandardMaterial3D
var _shard_mesh: Mesh
var _model_slice: Mesh  ## Blender'dan gelen dilim (yoksa prosedürel)
var _model_shards: Array[Mesh] = []
var _time: float = 0.0
var _splat_tex: Texture2D
var _spark_tex: Texture2D
var _splat_mesh: QuadMesh


func _ready() -> void:
	pivot = Node3D.new()
	pivot.name = "Pivot"
	add_child(pivot)
	effects = Node3D.new()
	effects.name = "Effects"
	add_child(effects)
	_slice_mesh = PlatformSegment.build_mesh(INSET, SLICE_ANGLE - INSET, inner_radius, outer_radius, ring_thickness)
	_safe_mat = _mat(Color("ffd23f"), 0.35)
	_black_mat = _mat(Color("1d1a2b"), 0.25)
	_finish_mat = _mat(Color("ff5fa2"), 0.3)
	_pole_mat = _mat(Color("f6f2ff"), 0.4)
	_pole_mat.emission_enabled = true
	_pole_mat.emission = Color("e6dcff")
	_pole_mat.emission_energy_multiplier = 0.15
	var box := BoxMesh.new()
	box.size = Vector3(0.14, 0.14, 0.14)
	_shard_mesh = box
	_model_slice = _load_mesh("res://assets/models/ring_slice.glb")
	if _model_slice:
		_slice_mesh = _model_slice
	for lab in ["a", "b", "c"]:
		var m := _load_mesh("res://assets/models/ring_slice_shard_%s.glb" % lab)
		if m:
			_model_shards.append(m)
	if ResourceLoader.exists("res://assets/textures/fx/splat.png"):
		_splat_tex = load("res://assets/textures/fx/splat.png")
	if ResourceLoader.exists("res://assets/textures/fx/spark.png"):
		_spark_tex = load("res://assets/textures/fx/spark.png")
	_splat_mesh = QuadMesh.new()
	_splat_mesh.size = Vector2(0.75, 0.75)
	_splat_mesh.orientation = PlaneMesh.FACE_Y
	var deb := _load_mesh("res://assets/models/debris_cube.glb")
	if deb:
		_shard_mesh = deb


## .glb sahnesindeki ilk MeshInstance3D'nin mesh'ini döndürür; dosya yoksa null.
func _load_mesh(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var inst := ps.instantiate()
	var found: Mesh = null
	var stack: Array = [inst]
	while stack.size() > 0 and found == null:
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			found = (n as MeshInstance3D).mesh
		stack.append_array(n.get_children())
	inst.free()
	return found


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = 0.85
	m.rim_enabled = true
	m.rim = 0.1
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _process(delta: float) -> void:
	if ring_count == 0:
		return
	_time += delta
	var spd := rotation_speed
	if wobble:
		spd *= 0.55 + 0.75 * sin(_time * 0.9)
	pivot.rotation.y = wrapf(pivot.rotation.y + spd * delta, 0.0, TAU)


func clear() -> void:
	for c in pivot.get_children():
		pivot.remove_child(c)
		c.queue_free()
	for c in effects.get_children():
		effects.remove_child(c)
		c.queue_free()
	rings.clear()
	ring_count = 0
	pivot.rotation.y = 0.0


func build(level: int) -> void:
	clear()
	var p := LevelGenerator.get_params(level)
	var data: Array = LevelGenerator.generate(level, SLICES)
	rotation_speed = float(p["rot_speed"])
	wobble = bool(p["wobble"])
	palette = p["palette"]
	_safe_mat.albedo_color = palette[0]
	_black_mat.albedo_color = palette[1]
	_finish_mat.albedo_color = palette[4]
	ring_count = data.size()

	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var height := ring_count * ring_spacing + 6.0
	cyl.top_radius = inner_radius * 0.98
	cyl.bottom_radius = inner_radius * 0.98
	cyl.height = height
	cyl.radial_segments = 32
	pole.mesh = cyl
	pole.material_override = _pole_mat
	pole.position.y = 4.0 - height * 0.5
	pivot.add_child(pole)

	for i in ring_count:
		var types: PackedInt32Array = data[i]
		var ring := MeshInstance3D.new()
		ring.name = "Ring%d" % i
		ring.position.y = ring_y(i)
		ring.mesh = _build_ring_mesh(types)
		ring.visibility_range_end = visible_range
		pivot.add_child(ring)
		rings.append({"node": ring, "types": types, "broken": false})

	var fin := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = outer_radius + 0.15
	disk.bottom_radius = outer_radius + 0.15
	disk.height = ring_thickness
	disk.radial_segments = 48
	fin.mesh = disk
	fin.material_override = _finish_mat
	fin.position.y = finish_y()
	pivot.add_child(fin)
	built.emit(ring_count)


## Halkayı tek mesh'te birleştirir (güvenli + siyah = 2 yüzey) -> düşük draw call.
func _build_ring_mesh(types: PackedInt32Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for t in [LevelGenerator.SAFE, LevelGenerator.BLACK]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var any := false
		for s in SLICES:
			if types[s] == t:
				if _model_slice:
					for si in _model_slice.get_surface_count():
						st.append_from(_model_slice, si, Transform3D(Basis(Vector3.UP, s * SLICE_ANGLE), Vector3.ZERO))
				else:
					PlatformSegment.append_slice(st, s * SLICE_ANGLE + INSET, (s + 1) * SLICE_ANGLE - INSET, inner_radius, outer_radius, ring_thickness)
				any = true
		if any:
			st.commit(am)
			am.surface_set_material(am.get_surface_count() - 1, _safe_mat if t == LevelGenerator.SAFE else _black_mat)
	return am


func ring_y(i: int) -> float:
	return -i * ring_spacing


func ring_top(i: int) -> float:
	return ring_y(i) + ring_thickness * 0.5


func finish_y() -> float:
	return ring_y(ring_count)


func finish_top() -> float:
	return finish_y() + ring_thickness * 0.5


## Dünya açısındaki (topun açısı) dilim tipi; kule dönüşü hesaba katılır.
func type_at(i: int, world_angle: float) -> int:
	if i < 0 or i >= ring_count or rings[i]["broken"]:
		return LevelGenerator.GAP
	var local := wrapf(world_angle - pivot.rotation.y, 0.0, TAU)
	var s := int(local / SLICE_ANGLE) % SLICES
	var types: PackedInt32Array = rings[i]["types"]
	return types[s]


## Halkayı parçalar: dilimler dışarı savrulur, küçük parçacıklar saçılır.
func break_ring(i: int, strength: float = 1.0) -> void:
	if i < 0 or i >= ring_count or rings[i]["broken"]:
		return
	rings[i]["broken"] = true
	var node: MeshInstance3D = rings[i]["node"]
	var types: PackedInt32Array = rings[i]["types"]
	var base := node.global_transform
	var rot := pivot.rotation.y
	for s in SLICES:
		if types[s] == LevelGenerator.GAP:
			continue
		var seg := PlatformSegment.new()
		seg.setup(s * SLICE_ANGLE, (s + 1) * SLICE_ANGLE, types[s], _slice_mesh,
			_safe_mat if types[s] == LevelGenerator.SAFE else _black_mat)
		effects.add_child(seg)
		seg.global_transform = base * Transform3D(Basis(Vector3.UP, s * SLICE_ANGLE), Vector3.ZERO)
		var mid := rot + (s + 0.5) * SLICE_ANGLE
		var dir := Vector3(sin(mid), 0, cos(mid))
		var dist := randf_range(1.6, 2.8) * (0.8 + strength * 0.25)
		if _model_shards.size() > 0:
			_spawn_shards(seg.global_transform, mid, dir, dist, seg.material_override)
			seg.queue_free()
			continue
		var tw := seg.create_tween().set_parallel(true)
		tw.tween_property(seg, "position", seg.position + dir * dist + Vector3(0, randf_range(0.4, 1.4), 0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(seg, "rotation", seg.rotation + Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2)), 0.5)
		tw.tween_property(seg, "scale", Vector3.ONE * 0.05, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.chain().tween_callback(seg.queue_free)
	node.queue_free()
	var col: Color = palette[0] if palette.size() > 0 else Color.YELLOW
	_burst(Vector3(0, ring_y(i), 1.3), col, int(14 + 10 * strength))


func _spawn_shards(base: Transform3D, mid: float, dir: Vector3, dist: float, m: Material) -> void:
	for k in _model_shards.size():
		if randf() < 0.55:
			continue
		var piece := MeshInstance3D.new()
		piece.mesh = _model_shards[k]
		piece.material_override = m
		effects.add_child(piece)
		var r := lerpf(inner_radius, outer_radius, 0.55)
		piece.global_position = base.origin + Vector3(sin(mid + (k - 1) * 0.15) * r, 0, cos(mid + (k - 1) * 0.15) * r)
		piece.rotation.y = mid
		var d := dir.rotated(Vector3.UP, (k - 1) * 0.35) * dist * randf_range(0.8, 1.2)
		var tw := piece.create_tween().set_parallel(true)
		tw.tween_property(piece, "position", piece.position + d + Vector3(0, randf_range(0.3, 1.5), 0), 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(piece, "rotation", piece.rotation + Vector3(randf_range(-3, 3), randf_range(-2, 2), randf_range(-3, 3)), 0.42)
		tw.tween_property(piece, "scale", Vector3.ONE * 0.05, 0.42).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.chain().tween_callback(piece.queue_free)


## Topun zıpladığı yere halkayla birlikte dönen ve sönen leke bırakır.
func add_splat(i: int, world_pos: Vector3, color: Color) -> void:
	if _splat_tex == null or i < 0 or i >= ring_count or rings[i]["broken"]:
		return
	var ring: Node3D = rings[i]["node"]
	var s := MeshInstance3D.new()
	s.mesh = _splat_mesh
	var m := StandardMaterial3D.new()
	m.albedo_texture = _splat_tex
	m.albedo_color = color.darkened(0.1)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s.material_override = m
	ring.add_child(s)
	s.global_position = world_pos + Vector3(0, ring_thickness * 0.5 - (world_pos.y - ring_top(i)) + 0.012, 0)
	s.rotation.y = randf() * TAU
	s.scale = Vector3.ONE * randf_range(0.8, 1.1)
	var tw := s.create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.8)
	tw.tween_callback(s.queue_free)


func _burst(pos: Vector3, color: Color, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.mesh = _shard_mesh
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.7
	p.direction = Vector3(0, 1, 1)
	p.spread = 70.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.5
	p.gravity = Vector3(0, -18, 0)
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	p.material_override = m
	effects.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.0, false).timeout.connect(p.queue_free)
	if _spark_tex:
		var sp := CPUParticles3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.35, 0.35)
		sp.mesh = q
		var sm := StandardMaterial3D.new()
		sm.albedo_texture = _spark_tex
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.vertex_color_use_as_albedo = true
		sp.material_override = sm
		sp.amount = maxi(6, amount / 3)
		sp.one_shot = true
		sp.explosiveness = 1.0
		sp.lifetime = 0.45
		sp.spread = 90.0
		sp.direction = Vector3(0, 1, 0.5)
		sp.initial_velocity_min = 2.0
		sp.initial_velocity_max = 5.0
		sp.gravity = Vector3(0, -6, 0)
		sp.scale_amount_min = 0.5
		sp.scale_amount_max = 1.3
		sp.color = color.lightened(0.5)
		effects.add_child(sp)
		sp.global_position = pos
		sp.emitting = true
		get_tree().create_timer(0.8, false).timeout.connect(sp.queue_free)
