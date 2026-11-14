extends Node
## Yerel kayıt sistemi (user://save.cfg). Bozuk/eksik dosyada varsayılanlara döner.

signal changed(key: String)

const PATH := "user://save.cfg"
const DEFAULTS := {
	"level": 1,
	"best": 0,
	"coins": 500,
	"unlocked": [0, 1, 2],
	"ball": 0,
	"music": true,
	"sfx": true,
	"vibration": true,
	"rings_broken": 0,
	"levels_done": 0,
	"fireballs": 0,
	"tasks_claimed": [],
	"daily_day": 0,
	"daily_last": "",
}

var data: Dictionary = {}


func _ready() -> void:
	load_data()


func load_data() -> void:
	data = DEFAULTS.duplicate(true)
	var cfg := ConfigFile.new()
	var err := cfg.load(PATH)
	if err != OK:
		save_data()
		return
	for k in DEFAULTS.keys():
		var v: Variant = cfg.get_value("save", k, DEFAULTS[k])
		if typeof(v) == typeof(DEFAULTS[k]):
			data[k] = v
	if int(data["level"]) < 1:
		data["level"] = 1


func save_data() -> void:
	var cfg := ConfigFile.new()
	for k in data.keys():
		cfg.set_value("save", k, data[k])
	cfg.save(PATH)


func get_v(key: String) -> Variant:
	return data.get(key, DEFAULTS.get(key))


func set_v(key: String, value: Variant) -> void:
	data[key] = value
	save_data()
	changed.emit(key)


func add_int(key: String, n: int) -> void:
	set_v(key, int(get_v(key)) + n)
