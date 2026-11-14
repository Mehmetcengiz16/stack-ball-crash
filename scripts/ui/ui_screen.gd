class_name UIScreen
extends Control
## Ekranlar için ortak taban: tam ekran, açılış animasyonu, isteğe bağlı karartma.

var dim: ColorRect
var card: Control


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func add_backdrop() -> void:
	var b := UIKit.Backdrop.new()
	b.set_colors(Color("2a1188"), Color("6a34c8"))
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(b)


func add_dim(alpha: float = 0.55) -> void:
	dim = ColorRect.new()
	dim.color = Color(0.07, 0.02, 0.2, alpha)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)


## Ortada bir dikey kart oluşturur (overlay ekranlar için).
func make_card(width: float, center_y: float = 0.0) -> VBoxContainer:
	var holder := CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.offset_top = center_y
	holder.offset_bottom = center_y
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size.x = width
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 22)
	holder.add_child(vb)
	card = vb
	return vb


func open() -> void:
	visible = true
	refresh()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	if card:
		await get_tree().process_frame
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.8, 0.8)
		var t2 := create_tween()
		t2.tween_property(card, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	visible = false


func refresh() -> void:
	pass


static func centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc
