extends UIScreen
## Duraklatma menüsü.

signal resume_pressed
signal home_pressed


func _ready() -> void:
	add_dim(0.6)
	var vb := make_card(520)
	var rib := UIKit.ribbon("DURAKLATILDI", UIKit.RIBBON, 50)
	rib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(rib)
	var res := UIKit.button("Devam Et", "play", Vector2(420, 104), 44)
	res.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	res.pressed.connect(func(): resume_pressed.emit())
	vb.add_child(res)
	var home := UIKit.button("Ana Menü", "home", Vector2(420, 92), 38, "purple")
	home.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home.pressed.connect(func(): home_pressed.emit())
	vb.add_child(home)
