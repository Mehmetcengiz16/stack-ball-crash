extends Node3D
## Ana sahne: dünya, kule, top, kamera ve UI'ı kurar; olayları GameManager'a bağlar.

const PlayerScene := preload("res://scenes/player.tscn")
const TowerScene := preload("res://scenes/tower.tscn")

var tower: TowerController
var player: PlayerController
var cam: CameraController
var ui: UIManager
var decor: Decor
var _bg: UIKit.Backdrop


func _ready() -> void:
	_setup_environment()
	tower = TowerScene.instantiate()
	add_child(tower)
	decor = Decor.new()
	add_child(decor)
	player = PlayerScene.instantiate()
	add_child(player)
	cam = CameraController.new()
	add_child(cam)
	cam.target = player
	cam.current = true

	ui = UIManager.new()
	add_child(ui)
	ui.play_requested.connect(_on_play)
	ui.next_requested.connect(func(): _load_level(true))
	ui.retry_requested.connect(func(): GameManager.reset_score(); _load_level(true))
	ui.home_requested.connect(func(): GameManager.reset_score(); _load_level(false))
	ui.skin_changed.connect(player.set_skin)

	player.ring_broken.connect(_on_ring_broken)
	player.ring_passed.connect(_on_ring_passed)
	player.bounced.connect(_on_bounced)
	player.died.connect(_on_died)
	player.finished.connect(_on_finished)
	player.fireball_started.connect(_on_fireball)
	player.fire_changed.connect(func(v, a): GameManager.fire_changed.emit(v, a))
	_load_level(false)


func _setup_environment() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	_bg = UIKit.Backdrop.new()
	layer.add_child(_bg)

	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = -1
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e9e0ff")
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_hdr_threshold = 1.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = false
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -150, 0)
	fill.light_energy = 0.35
	fill.light_color = Color("c8b8ff")
	add_child(fill)


func _load_level(start_playing: bool) -> void:
	var lvl := GameManager.level
	tower.build(lvl)
	var pal: Array = tower.palette
	_bg.set_colors(pal[2], pal[3])
	decor.build(tower.ring_count * tower.ring_spacing, pal[3])
	player.reset(tower)
	cam.reset_to(player.position.y)
	GameManager.set_combo(0)
	GameManager.progress_changed.emit(0.0)
	GameManager.level_loaded.emit(lvl)
	if start_playing:
		_on_play()
	else:
		GameManager.set_state(GameManager.State.MENU)
		decor.set_menu(true, tower.ring_top(0))
		ui.show_menu()


func _on_play() -> void:
	GameManager.set_state(GameManager.State.PLAYING)
	player.input_enabled = true
	decor.set_menu(false, 0.0)
	ui.show_hud()


func _progress() -> void:
	GameManager.progress_changed.emit(float(player.next_ring) / float(maxi(1, tower.ring_count)))


func _on_ring_broken(_idx: int, combo: int, fire: bool) -> void:
	GameManager.add_score((40 if fire else 20) + combo * 5)
	GameManager.set_combo(combo)
	SaveManager.data["rings_broken"] = int(SaveManager.get_v("rings_broken")) + 1
	_progress()
	cam.shake(0.25 + minf(combo, 15) * 0.03 + (0.25 if fire else 0.0))
	AudioManager.play("break", 0.9 + minf(combo, 12) * 0.04)
	if combo > 1 and combo % 4 == 0:
		AudioManager.play("combo", 1.0 + combo * 0.02)
	AudioManager.vibrate(15)


func _on_ring_passed(_idx: int) -> void:
	GameManager.add_score(10)
	_progress()


func _on_bounced() -> void:
	GameManager.set_combo(0)
	AudioManager.play("bounce", randf_range(0.95, 1.08))


func _on_fireball() -> void:
	SaveManager.data["fireballs"] = int(SaveManager.get_v("fireballs")) + 1
	AudioManager.play("fireball")
	AudioManager.vibrate(60)
	cam.shake(0.6)


func _on_died() -> void:
	player.input_enabled = false
	SaveManager.save_data()
	AudioManager.play("fail")
	AudioManager.vibrate(200)
	cam.shake(0.9)
	await get_tree().create_timer(0.7).timeout
	GameManager.fail()


func _on_finished() -> void:
	player.input_enabled = false
	GameManager.progress_changed.emit(1.0)
	AudioManager.play("complete")
	AudioManager.vibrate(80)
	GameManager.complete_level()
