class_name Decor
extends Node3D
## Sahne dekoru: kule boyunca arkada süzülen bulutlar + menüde kule tepesinde dönen enerji halkası.
## Modeller yoksa sessizce hiçbir şey eklemez.

const CLOUDS := ["res://assets/models/cloud_a.glb", "res://assets/models/cloud_b.glb", "res://assets/models/cloud_c.glb"]
const SWIRL := "res://assets/models/menu_swirl.glb"

var _clouds: Array[Node3D] = []
var _swirl: Node3D
var _cloud_scenes: Array[PackedScene] = []
var _cloud_mat: StandardMaterial3D


func _ready() -> void:
	for p in CLOUDS:
		if ResourceLoader.exists(p):
			_cloud_scenes.append(load(p))
	_cloud_mat = StandardMaterial3D.new()
	_cloud_mat.albedo_color = Color(0.97, 0.92, 1.0, 0.55)
	_cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if ResourceLoader.exists(SWIRL):
		_swirl = (load(SWIRL) as PackedScene).instantiate()
		_swirl.scale = Vector3.ONE * 1.25
		add_child(_swirl)
		_swirl.visible = false


## Kule yüksekliği boyunca bulutları yeniden dağıtır (eski bulutlar temizlenir).
func build(tower_height: float, tint: Color) -> void:
	for c in _clouds:
		c.queue_free()
	_clouds.clear()
	if _cloud_scenes.is_empty():
		return
	_cloud_mat.albedo_color = Color(tint.lightened(0.55), 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tower_height * 100)
	var count := int(tower_height / 2.5) + 4
	for i in count:
		var c: Node3D = _cloud_scenes[i % _cloud_scenes.size()].instantiate()
		var side := -1.0 if i % 2 == 0 else 1.0
		c.position = Vector3(side * rng.randf_range(3.2, 6.5), 2.0 - i * 2.5 + rng.randf_range(-0.8, 0.8), rng.randf_range(-7.0, -2.5))
		c.scale = Vector3.ONE * rng.randf_range(0.9, 1.8)
		c.rotation.y = rng.randf_range(-0.4, 0.4)
		_apply_mat(c)
		c.set_meta("drift", rng.randf_range(0.15, 0.4) * side)
		c.set_meta("x0", c.position.x)
		add_child(c)
		_clouds.append(c)


func _apply_mat(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = _cloud_mat
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for ch in n.get_children():
		_apply_mat(ch)


func set_menu(on: bool, top_y: float) -> void:
	if _swirl:
		_swirl.visible = on
		_swirl.position = Vector3(0, top_y + 1.1, 0)


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for c in _clouds:
		c.position.x = float(c.get_meta("x0")) + sin(t * float(c.get_meta("drift"))) * 0.6
	if _swirl and _swirl.visible:
		_swirl.rotate_y(delta * 0.8)
