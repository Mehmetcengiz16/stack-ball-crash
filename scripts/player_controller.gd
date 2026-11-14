class_name PlayerController
extends Node3D
## Top: kendi dikey fiziğini yürütür ve halka düzlemlerini sürekli (swept) kontrol eder.
## Yüksek hızda tünelleme olmaz; her halka yalnızca bir kez işlenir.

signal ring_broken(index: int, combo: int, fire: bool)
signal ring_passed(index: int)
signal bounced
signal died
signal finished
signal fireball_started
signal fireball_ended
signal fire_changed(value: float, active: bool)

enum State { IDLE, BOUNCING, SMASHING, FALLING, FIREBALL, DEAD, FINISHED }

@export var gravity: float = 30.0
@export var bounce_velocity: float = 9.0
@export var smash_speed: float = 15.0
@export var smash_accel: float = 110.0
@export var max_fall_speed: float = 18.0
@export var fireball_speed_mult: float = 1.35
@export var combo_threshold: int = 8
@export var fireball_duration: float = 3.0
@export var fire_decay: float = 0.35
@export var radius: float = 0.3
@export var ball_distance: float = 1.32

var tower: TowerController
var state: int = State.IDLE
var vy: float = 0.0
var next_ring: int = 0
var combo: int = 0
var fire_charge: float = 0.0
var fire_active: bool = false
var fire_time: float = 0.0
var holding: bool = false
var input_enabled: bool = false
var skin: int = 0

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _fire_mat: StandardMaterial3D
var _trail: CPUParticles3D
var _light: OmniLight3D
var _squash: Vector3 = Vector3.ONE
var _hue: float = 0.0


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 32
	sm.rings = 16
	_mesh.mesh = sm
	add_child(_mesh)

	_fire_mat = StandardMaterial3D.new()
	_fire_mat.albedo_color = Color("ff7a1a")
	_fire_mat.emission_enabled = true
	_fire_mat.emission = Color("ff9d00")
	_fire_mat.emission_energy_multiplier = 2.2

	_trail = CPUParticles3D.new()
	var pm := QuadMesh.new()
	pm.size = Vector2(0.55, 0.55)
	_trail.mesh = pm
	var tm := StandardMaterial3D.new()
	tm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if ResourceLoader.exists("res://assets/textures/fx/flame.png"):
		tm.albedo_texture = load("res://assets/textures/fx/flame.png")
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.vertex_color_use_as_albedo = true
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_trail.material_override = tm
	_trail.amount = 70
	_trail.lifetime = 0.45
	_trail.local_coords = false
	_trail.direction = Vector3.UP
	_trail.spread = 45.0
	_trail.initial_velocity_min = 1.0
	_trail.initial_velocity_max = 3.0
	_trail.gravity = Vector3(0, 6, 0)
	_trail.scale_amount_min = 0.6
	_trail.scale_amount_max = 1.4
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.4, 1.0))
	g.set_color(1, Color(1.0, 0.25, 0.0, 0.0))
	_trail.color_ramp = g
	_trail.emitting = false
	add_child(_trail)

	_light = OmniLight3D.new()
	_light.light_color = Color("ff8a1a")
	_light.omni_range = 4.0
	_light.light_energy = 0.0
	add_child(_light)
	set_skin(int(SaveManager.get_v("ball")))


func set_skin(idx: int) -> void:
	skin = idx
	_mat = BallSkins.make_material(idx)
	if not fire_active:
		_mesh.material_override = _mat


func reset(t: TowerController) -> void:
	tower = t
	next_ring = 0
	combo = 0
	fire_charge = 0.0
	fire_time = 0.0
	holding = false
	input_enabled = false
	_end_fire(false)
	vy = 0.0
	position = Vector3(0, tower.ring_top(0) + radius + 1.2, ball_distance)
	state = State.BOUNCING
	visible = true
	_mesh.scale = Vector3.ONE
	fire_changed.emit(0.0, false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		holding = event.pressed
	elif event is InputEventScreenTouch:
		holding = event.pressed


func _physics_process(delta: float) -> void:
	if tower == null or tower.ring_count == 0 or state == State.DEAD or state == State.FINISHED or state == State.IDLE:
		return
	var smash := holding and input_enabled
	if not input_enabled:
		holding = false

	if fire_active:
		fire_time -= delta
		fire_charge = maxf(fire_time / fireball_duration, 0.0)
		if fire_time <= 0.0:
			_end_fire(true)
	elif not smash and fire_charge > 0.0:
		fire_charge = maxf(0.0, fire_charge - delta * fire_decay)

	if smash:
		var sp := smash_speed * (fireball_speed_mult if fire_active else 1.0)
		vy = move_toward(vy, -sp, smash_accel * delta)
	else:
		vy = maxf(vy - gravity * delta, -max_fall_speed)

	var old_y := position.y
	var new_y := old_y + vy * delta
	if vy < 0.0:
		new_y = _resolve(old_y, new_y, smash)
	position.y = new_y

	if state != State.DEAD and state != State.FINISHED:
		if fire_active:
			state = State.FIREBALL
		elif smash:
			state = State.SMASHING
		elif vy < 0.0:
			state = State.FALLING
		else:
			state = State.BOUNCING
	fire_changed.emit(fire_charge, fire_active)


## Önceki ve yeni alt nokta arasında kalan tüm halka üst düzlemlerini sırayla işler.
func _resolve(_old_y: float, new_y: float, smash: bool) -> float:
	var y := new_y
	while true:
		var bottom := y - radius
		if next_ring >= tower.ring_count:
			var ft := tower.finish_top()
			if bottom <= ft:
				y = ft + radius
				_finish()
			return y
		var top := tower.ring_top(next_ring)
		if bottom > top:
			return y
		var t := tower.type_at(next_ring, 0.0)
		if t == LevelGenerator.GAP:
			ring_passed.emit(next_ring)
			next_ring += 1
			continue
		if smash and (t == LevelGenerator.SAFE or fire_active):
			var idx := next_ring
			next_ring += 1
			_on_break(idx)
			continue
		if smash and t == LevelGenerator.BLACK:
			y = top + radius
			_die()
			return y
		y = top + radius
		_bounce()
		return y
	return y


func _on_break(idx: int) -> void:
	combo += 1
	if not fire_active:
		fire_charge = minf(1.0, fire_charge + 1.0 / float(combo_threshold))
		if fire_charge >= 1.0:
			_start_fire()
	tower.break_ring(idx, 1.0 + minf(combo, 20) * 0.08 + (1.0 if fire_active else 0.0))
	_mesh.scale = Vector3(0.85, 1.25, 0.85)
	ring_broken.emit(idx, combo, fire_active)


func _bounce() -> void:
	vy = bounce_velocity
	combo = 0
	_mesh.scale = Vector3(1.3, 0.7, 1.3)
	if tower:
		tower.add_splat(next_ring, global_position - Vector3(0, radius - 0.01, 0), BallSkins.LIST[skin]["color"])
	bounced.emit()


func _start_fire() -> void:
	fire_active = true
	fire_time = fireball_duration
	fire_charge = 1.0
	_mesh.material_override = _fire_mat
	_trail.emitting = true
	_light.light_energy = 2.5
	fireball_started.emit()


func _end_fire(emit: bool) -> void:
	var was := fire_active
	fire_active = false
	fire_time = 0.0
	fire_charge = 0.0
	if _mesh:
		_mesh.material_override = _mat
		_trail.emitting = false
		_light.light_energy = 0.0
	if emit and was:
		fireball_ended.emit()


func _die() -> void:
	state = State.DEAD
	vy = 0.0
	_mesh.scale = Vector3(1.5, 0.45, 1.5)
	died.emit()


func _finish() -> void:
	state = State.FINISHED
	vy = 0.0
	_end_fire(false)
	finished.emit()


func _process(delta: float) -> void:
	if _mesh == null:
		return
	if state != State.DEAD:
		var target_scale := Vector3.ONE
		if state == State.SMASHING or state == State.FIREBALL:
			target_scale = Vector3(0.92, 1.12, 0.92)
		_mesh.scale = _mesh.scale.lerp(target_scale, 1.0 - exp(-14.0 * delta))
	if BallSkins.LIST[skin].has("rainbow") and not fire_active:
		_hue = wrapf(_hue + delta * 0.25, 0.0, 1.0)
		if _mat.albedo_texture == null:
			_mat.albedo_color = Color.from_hsv(_hue, 0.75, 1.0)
	_mesh.rotate_y(delta * 2.2)
	if fire_active:
		_light.light_energy = 2.2 + sin(Time.get_ticks_msec() * 0.03) * 0.5
