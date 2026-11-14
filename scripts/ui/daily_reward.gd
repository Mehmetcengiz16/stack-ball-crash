extends UIScreen
## Günlük Ödül: 7 günlük takvim, günde bir kez alınabilir.

signal close_pressed

const REWARDS := [100, 150, 200, 250, 300, 400, 1000]
const ICONS := ["coins", "coins", "gem", "coins", "star", "coins", "gift"]

var _cells: Array = []
var _claim: Button


func _ready() -> void:
	add_backdrop()
	var vb := make_card(640)
	var rib := UIKit.ribbon("GÜNLÜK ÖDÜL", UIKit.RIBBON, 48, Color.WHITE, "calendar")
	rib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(rib)
	var p := UIKit.panel(UIKit.PANEL, 40, UIKit.PANEL_BORDER, 4, 24)
	vb.add_child(p)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	p.add_child(pv)
	var r1 := HBoxContainer.new()
	r1.alignment = BoxContainer.ALIGNMENT_CENTER
	r1.add_theme_constant_override("separation", 12)
	var r2 := HBoxContainer.new()
	r2.alignment = BoxContainer.ALIGNMENT_CENTER
	r2.add_theme_constant_override("separation", 12)
	pv.add_child(r1)
	pv.add_child(r2)
	for i in 7:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(132, 150) if i < 6 else Vector2(150, 150)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(cv)
		cv.add_child(UIKit.label("%d. Gün" % (i + 1), 22))
		var ic := UIKit.icon(ICONS[i], 60)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cv.add_child(ic)
		cv.add_child(UIKit.label("+%d" % REWARDS[i], 28, Color.WHITE, 6))
		(r1 if i < 4 else r2).add_child(cell)
		_cells.append(cell)
	_claim = UIKit.button("Ödülü Al", "", Vector2(400, 96), 42)
	_claim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_claim.pressed.connect(_on_claim)
	vb.add_child(_claim)
	var close := UIKit.round_button("back", 80)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): close_pressed.emit())
	vb.add_child(close)


static func today() -> String:
	return Time.get_date_string_from_system()


static func can_claim() -> bool:
	return str(SaveManager.get_v("daily_last")) != today()


func refresh() -> void:
	var day := int(SaveManager.get_v("daily_day")) % 7
	var claimable := can_claim()
	for i in 7:
		var cell: PanelContainer = _cells[i]
		var done := i < day
		var current := i == day and claimable
		var col := UIKit.GREEN if done else (Color("6a49f0") if current else UIKit.INNER)
		var st := UIKit.style(col, 20, UIKit.YELLOW if current else UIKit.INNER_BORDER, 4 if current else 3, 4)
		st.set_content_margin_all(8)
		cell.add_theme_stylebox_override("panel", st)
	_claim.disabled = not claimable
	_claim.modulate = Color.WHITE if claimable else Color(1, 1, 1, 0.5)


func _on_claim() -> void:
	if not can_claim():
		return
	var day := int(SaveManager.get_v("daily_day")) % 7
	GameManager.add_coins(REWARDS[day])
	SaveManager.set_v("daily_day", day + 1)
	SaveManager.set_v("daily_last", today())
	AudioManager.play("complete")
	refresh()
