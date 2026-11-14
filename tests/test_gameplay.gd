extends Node
## Headless duman testi: godot --headless --path . res://tests/test_gameplay.tscn

func _ready() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await _frames(5)
	var gm: Node = get_tree().root.get_node("GameManager")
	var p: PlayerController = main.player
	var t: TowerController = main.tower
	print("rings=", t.ring_count, " state=", gm.state)
	# 1) Bırakınca zıplamalı, düşmemeli
	main._on_play()
	await _frames(180)
	print("bounce test: next_ring=", p.next_ring, " y=", snappedf(p.position.y, 0.01), " state=", p.state)
	# 2) Seviye 1: basılı tut -> bitirmeli
	gm.level = 1
	main._load_level(true)
	p.holding = true
	var fire_seen := false
	for i in 900:
		await get_tree().physics_frame
		fire_seen = fire_seen or p.fire_active
		if p.state == PlayerController.State.FINISHED or p.state == PlayerController.State.DEAD:
			break
	print("L1 smash: state=", p.state, " next=", p.next_ring, "/", t.ring_count, " score=", gm.score, " fire=", fire_seen, " gm.state=", gm.state, " level=", gm.level)
	# 3) Seviye 12: sürekli basılı -> siyaha çarpıp ölmeli
	p.holding = false
	gm.level = 12
	gm.reset_score()
	main._load_level(true)
	p.fireball_duration = 0.01
	p.holding = true
	for i in 900:
		await get_tree().physics_frame
		if p.state == PlayerController.State.DEAD or p.state == PlayerController.State.FINISHED:
			break
	print("L12 smash: state=", p.state, " next=", p.next_ring)
	await get_tree().create_timer(1.0).timeout
	print("gm.state after death=", gm.state, " best=", gm.best())
	# 4) Seviye geçişinde eski nesneler temizleniyor mu
	main._load_level(false)
	await _frames(3)
	print("pivot children=", t.pivot.get_child_count(), " expected=", t.ring_count + 2, " effects=", t.effects.get_child_count())
	# 5) Bozuk kayıt dosyası
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	f.store_string("@@@ bozuk {{{")
	f.close()
	var sm: Node = get_tree().root.get_node("SaveManager")
	sm.load_data()
	print("corrupt save -> level=", sm.get_v("level"), " coins=", sm.get_v("coins"))
	gm.level = 1
	sm.set_v("level", 1)
	get_tree().quit()
