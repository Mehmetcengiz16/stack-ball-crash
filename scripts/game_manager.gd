extends Node
## Merkezi oyun durumu: seviye, skor, coin ve durum geçişleri (sinyal tabanlı).

signal state_changed(state: int)
signal score_changed(score: int)
signal combo_changed(combo: int)
signal coins_changed(coins: int)
signal progress_changed(value: float)
signal fire_changed(value: float, active: bool)
signal level_loaded(level: int)
signal level_completed(level: int, score: int, coins: int)
signal game_over(score: int, best: int)

enum State { MENU, PLAYING, PAUSED, COMPLETE, OVER }

var state: int = State.MENU
var level: int = 1
var score: int = 0
var combo: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level = int(SaveManager.get_v("level"))


func set_state(s: int) -> void:
	state = s
	get_tree().paused = (s == State.PAUSED)
	state_changed.emit(s)


func reset_score() -> void:
	score = 0
	combo = 0
	score_changed.emit(score)


func add_score(n: int) -> void:
	score += n
	score_changed.emit(score)


func set_combo(c: int) -> void:
	combo = c
	combo_changed.emit(c)


func coins() -> int:
	return int(SaveManager.get_v("coins"))


func add_coins(n: int) -> void:
	SaveManager.add_int("coins", n)
	coins_changed.emit(coins())


func spend_coins(n: int) -> bool:
	if coins() < n:
		return false
	add_coins(-n)
	return true


func best() -> int:
	return int(SaveManager.get_v("best"))


func _update_best() -> void:
	if score > best():
		SaveManager.set_v("best", score)


func complete_level() -> void:
	if state != State.PLAYING:
		return
	var earned := 20 + level * 5
	add_coins(earned)
	_update_best()
	SaveManager.add_int("levels_done", 1)
	var done_level := level
	level += 1
	SaveManager.set_v("level", level)
	set_state(State.COMPLETE)
	level_completed.emit(done_level, score, earned)


func fail() -> void:
	if state != State.PLAYING:
		return
	_update_best()
	set_state(State.OVER)
	game_over.emit(score, best())
