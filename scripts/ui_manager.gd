class_name UIManager
extends CanvasLayer
## Tüm UI ekranlarını yükler, geçişleri yönetir ve olayları ana sahneye iletir.

signal play_requested
signal next_requested
signal retry_requested
signal home_requested
signal skin_changed(idx: int)

var menu
var hud
var complete
var over
var shop
var settings
var pause
var daily
var tasks
var map
var _root: Control


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIKit.make_theme()
	add_child(_root)
	hud = _add("game_hud")
	menu = _add("main_menu")
	complete = _add("level_complete")
	over = _add("game_over")
	pause = _add("pause_menu")
	shop = _add("ball_shop")
	settings = _add("settings_panel")
	daily = _add("daily_reward")
	tasks = _add("tasks_panel")
	map = _add("level_map")

	menu.play_pressed.connect(func(): play_requested.emit())
	menu.shop_pressed.connect(func(): shop.open())
	menu.settings_pressed.connect(func(): settings.open())
	menu.daily_pressed.connect(func(): daily.open())
	menu.tasks_pressed.connect(func(): tasks.open())
	menu.map_pressed.connect(func(): map.open())
	map.back_pressed.connect(map.close)
	map.play_pressed.connect(func(): play_requested.emit())
	shop.back_pressed.connect(func(): shop.close(); menu.refresh())
	shop.skin_selected.connect(func(i): skin_changed.emit(i))
	settings.close_pressed.connect(settings.close)
	daily.close_pressed.connect(func(): daily.close(); menu.refresh())
	tasks.close_pressed.connect(func(): tasks.close(); menu.refresh())
	hud.pause_pressed.connect(_on_pause)
	pause.resume_pressed.connect(_on_resume)
	pause.home_pressed.connect(func(): _hide_all(); home_requested.emit())
	complete.next_pressed.connect(func(): _hide_all(); next_requested.emit())
	complete.replay_pressed.connect(func(): GameManager.level = maxi(1, GameManager.level - 1); _hide_all(); retry_requested.emit())
	complete.home_pressed.connect(func(): _hide_all(); home_requested.emit())
	over.retry_pressed.connect(func(): _hide_all(); retry_requested.emit())
	over.home_pressed.connect(func(): _hide_all(); home_requested.emit())

	GameManager.level_completed.connect(func(_l, s, c): hud.close(); complete.show_result(s, c))
	GameManager.game_over.connect(func(s, b): hud.close(); over.show_result(s, b))


func _add(n: String) -> UIScreen:
	var s: UIScreen = load("res://scenes/ui/%s.tscn" % n).instantiate()
	_root.add_child(s)
	return s


func _hide_all() -> void:
	for c in _root.get_children():
		(c as UIScreen).close()


func show_menu() -> void:
	_hide_all()
	menu.open()


func show_hud() -> void:
	_hide_all()
	hud.open()


func _on_pause() -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	GameManager.set_state(GameManager.State.PAUSED)
	pause.open()


func _on_resume() -> void:
	pause.close()
	GameManager.set_state(GameManager.State.PLAYING)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_pause()
