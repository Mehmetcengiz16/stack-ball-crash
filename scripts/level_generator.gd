class_name LevelGenerator
extends RefCounted
## Prosedürel seviye üretimi. Her halka SLICES dilimlik tip dizisidir.

const GAP := 0
const SAFE := 1
const BLACK := 2

## [platform, siyah, arka plan üst, arka plan alt, bitiş]
const PALETTES := [
	[Color("ffc824"), Color("23212e"), Color("3a1798"), Color("b46be0"), Color("ff5fa2")],
	[Color("ff6fae"), Color("221a2e"), Color("13308f"), Color("57b8f0"), Color("ffd23f")],
	[Color("7ee04a"), Color("1c2225"), Color("8a1f6b"), Color("ff9a7a"), Color("7b4dff")],
	[Color("4fd9ff"), Color("1c1c2a"), Color("2a1170"), Color("c04dd8"), Color("ffd23f")],
	[Color("ff9f2e"), Color("201a1a"), Color("0f5a6e"), Color("4fd6b0"), Color("ff4f6d")],
	[Color("c9a2ff"), Color("181826"), Color("7a1440"), Color("ff7aa8"), Color("4fd9ff")],
]


static func get_params(level: int) -> Dictionary:
	var t := clampf(float(level - 1) / 29.0, 0.0, 1.0)
	var extra := float(maxi(0, level - 30))
	var black := 0.0
	if level >= 2:
		black = lerpf(0.16, 0.42, t) + minf(extra * 0.004, 0.12)
	return {
		"rings": int(lerpf(18.0, 40.0, t) + minf(extra * 0.5, 25.0)),
		"black_ratio": black,
		"gap_chance": lerpf(0.40, 0.18, t),
		"gap_size": 3 if level <= 5 else (2 if level <= 20 else 1),
		"rot_speed": lerpf(0.75, 1.55, t) + minf(extra * 0.01, 0.6),
		"wobble": level > 15,
		"palette": PALETTES[int((level - 1) / 3) % PALETTES.size()],
		"seed": level * 7919 + 13,
	}


static func generate(level: int, slices: int) -> Array:
	var p := get_params(level)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p["seed"])
	var rings: Array = []
	var offset := 0
	var twist := rng.randi_range(1, 2) * (1 if rng.randf() < 0.5 else -1)
	var ring_count: int = p["rings"]
	for i in ring_count:
		var t := PackedInt32Array()
		t.resize(slices)
		t.fill(SAFE)
		if i > 0:
			var nb := int(round(slices * float(p["black_ratio"]) * rng.randf_range(0.6, 1.4)))
			nb = clampi(nb, 0, slices - 5)
			if nb > 0:
				var chunks := 1 if nb < 4 else 2
				var per := maxi(1, nb / chunks)
				var start := rng.randi_range(0, slices - 1)
				for c in chunks:
					for k in per:
						t[(start + k) % slices] = BLACK
					start = (start + per + rng.randi_range(2, 4)) % slices
			if rng.randf() < float(p["gap_chance"]):
				var gs: int = p["gap_size"]
				for _attempt in 12:
					var gst := rng.randi_range(0, slices - 1)
					var ok := true
					for k in gs:
						if t[(gst + k) % slices] != SAFE:
							ok = false
					if ok and _count(t, SAFE) - gs >= 3:
						for k in gs:
							t[(gst + k) % slices] = GAP
						break
		# Her halkada en az 3 güvenli dilim garantisi
		while _count(t, SAFE) < 3:
			for k in slices:
				if t[k] == BLACK:
					t[k] = SAFE
					break
		var rotated := PackedInt32Array()
		rotated.resize(slices)
		for k in slices:
			rotated[(k + offset + slices * 4) % slices] = t[k]
		offset += twist
		rings.append(rotated)
	return rings


static func _count(t: PackedInt32Array, v: int) -> int:
	var c := 0
	for x in t:
		if x == v:
			c += 1
	return c
