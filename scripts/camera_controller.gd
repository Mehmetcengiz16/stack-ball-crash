class_name CameraController
extends Camera3D
## Topu yumuşak takip eden, yalnızca aşağı inen eğimli kamera + sarsıntı.

@export var offset: Vector3 = Vector3(0, 3.8, 8.8)
@export var look_offset: Vector3 = Vector3(0, -1.2, 0)
@export var follow_speed: float = 9.0

var target: Node3D
var follow_y: float = 0.0
var _shake: float = 0.0


func _ready() -> void:
	keep_aspect = Camera3D.KEEP_WIDTH
	fov = 52.0
	near = 0.1
	far = 80.0


func reset_to(y: float) -> void:
	follow_y = y
	_shake = 0.0
	_apply(Vector3.ZERO)


func shake(amount: float) -> void:
	_shake = minf(1.0, maxf(_shake, amount))


func _process(delta: float) -> void:
	if target:
		var ty := target.position.y
		if ty < follow_y:
			follow_y = lerpf(follow_y, ty, 1.0 - exp(-follow_speed * delta))
	_shake = maxf(0.0, _shake - delta * 3.0)
	var s := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * _shake * 0.35
	_apply(s)


func _apply(s: Vector3) -> void:
	var c := Vector3(0, follow_y, 0)
	global_position = c + offset + s
	look_at(c + look_offset + s * 0.5, Vector3.UP)
