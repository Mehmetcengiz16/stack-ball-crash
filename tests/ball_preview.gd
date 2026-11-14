extends Node3D
## Tüm top görünümlerini yan yana çizer: godot --path . res://tests/ball_preview.tscn

func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.look_at_from_position(Vector3(0, 0.3, 4.6), Vector3.ZERO)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, 30, 0)
	add_child(l)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("3a1798")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.5
	add_child(env)
	for i in BallSkins.LIST.size():
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.55
		sm.height = 1.1
		mi.mesh = sm
		mi.material_override = BallSkins.make_material(i)
		mi.position = Vector3((i % 3 - 1) * 1.4, 1.3 - (i / 3) * 1.3, 0)
		mi.rotation_degrees = Vector3(15, -30, 0)
		add_child(mi)
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("user://balls.png")
	get_tree().quit()
