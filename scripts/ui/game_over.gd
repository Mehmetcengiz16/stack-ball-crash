extends UIScreen
## Oyun Bitti: çatlak top, kırmızı kurdele, skor + en yüksek skor, Tekrar Dene, ana menü.

signal retry_pressed
signal home_pressed

var _score: Label
var _best: Label


func _ready() -> void:
	add_backdrop()
	var vb := make_card(540, -20)
	var ball := UIKit.icon("ball", 150)
	ball.ball_color = UIKit.RED
	ball.cracked = true
	ball.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(ball)
	var rib := UIKit.ribbon("OYUN BİTTİ!", UIKit.RED, 58)
	rib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(rib)

	var ip := UIKit.inner_panel(22)
	ip.custom_minimum_size.x = 420
	ip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(ip)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 2)
	ip.add_child(iv)
	iv.add_child(UIKit.label("Skor", 30))
	_score = UIKit.label("0", 56, Color.WHITE, 8)
	iv.add_child(_score)
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 16)
	iv.add_child(bh)
	bh.add_child(UIKit.icon("crown", 56))
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", -6)
	bh.add_child(bv)
	bv.add_child(UIKit.label("En Yüksek Skor", 24))
	_best = UIKit.label("0", 34, Color.WHITE, 6)
	bv.add_child(_best)

	var retry := UIKit.button("Tekrar Dene", "replay", Vector2(440, 104), 44)
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.pressed.connect(func(): retry_pressed.emit())
	vb.add_child(retry)
	var home := UIKit.round_button("home", 92)
	home.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home.pressed.connect(func(): home_pressed.emit())
	vb.add_child(home)


func show_result(score: int, best: int) -> void:
	_score.text = UIKit.fmt(score)
	_best.text = UIKit.fmt(best)
	open()
