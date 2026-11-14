extends Node
## Ekran görüntüsü yardımcısı: godot --path . res://tests/screenshot.tscn

func _ready() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(1.2).timeout
	_shot("menu")
	for n in ["shop", "map", "settings", "daily", "tasks"]:
		var scr = main.ui.get(n)
		scr.open()
		await get_tree().create_timer(0.6).timeout
		_shot(n)
		scr.close()
	main.ui.complete.show_result(12480, 120)
	await get_tree().create_timer(0.9).timeout
	_shot("complete")
	main.ui.complete.close()
	main.ui.over.show_result(6230, 48320)
	await get_tree().create_timer(0.6).timeout
	_shot("over")
	main.ui.over.close()
	main._on_play()
	await get_tree().create_timer(0.8).timeout
	await get_tree().create_timer(1.2).timeout
	_shot("bounce")
	main.player.holding = true
	await get_tree().create_timer(0.75).timeout
	_shot("play")
	await get_tree().create_timer(1.0).timeout
	_shot("end")
	get_tree().quit()


func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://shot_%s.png" % n)
