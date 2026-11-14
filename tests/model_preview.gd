extends Node3D
## Tüm .glb modelleri ızgarada gösterir: godot --path . res://tests/model_preview.tscn

const NAMES := ["island_a", "island_b", "island_c", "tree_pine", "waterfall", "level_node", "lock", "cloud_a", "cloud_b", "cloud_c", "menu_swirl", "ring_slice"]


func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.look_at_from_position(Vector3(0, 6, 11), Vector3(0, 0, 0))
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-45, 30, 0)
	add_child(l)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("3a1798")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.5
	add_child(env)
	for i in NAMES.size():
		var ps: PackedScene = load("res://assets/models/%s.glb" % NAMES[i])
		var n: Node3D = ps.instantiate()
		n.position = Vector3((i % 3 - 1) * 3.2, 0, (i / 3) * 2.6 - 4.5)
		add_child(n)
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("user://models.png")
	get_tree().quit()
