class_name PlatformSegment
extends MeshInstance3D
## Tek bir halka dilimi. Geometri SurfaceTool ile prosedürel üretilir ve paylaşılır.

var start_angle: float = 0.0
var end_angle: float = 0.0
var type: int = LevelGenerator.SAFE


static func point(a: float, r: float, y: float) -> Vector3:
	return Vector3(sin(a) * r, y, cos(a) * r)


static func _quad(st: SurfaceTool, v: Array, n: Array) -> void:
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n[idx])
		st.add_vertex(v[idx])


## a0..a1 açı aralığında kalın halka dilimi ekler (kapaklar dahil).
static func append_slice(st: SurfaceTool, a0: float, a1: float, rin: float, rout: float, h: float, steps: int = 4) -> void:
	var top := h * 0.5
	var bot := -h * 0.5
	for i in steps:
		var a := lerpf(a0, a1, float(i) / steps)
		var b := lerpf(a0, a1, float(i + 1) / steps)
		var na := Vector3(sin(a), 0, cos(a))
		var nb := Vector3(sin(b), 0, cos(b))
		_quad(st, [point(a, rin, top), point(a, rout, top), point(b, rout, top), point(b, rin, top)],
			[Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
		_quad(st, [point(a, rin, bot), point(b, rin, bot), point(b, rout, bot), point(a, rout, bot)],
			[Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN])
		_quad(st, [point(a, rout, top), point(a, rout, bot), point(b, rout, bot), point(b, rout, top)],
			[na, na, nb, nb])
		_quad(st, [point(a, rin, top), point(b, rin, top), point(b, rin, bot), point(a, rin, bot)],
			[-na, -nb, -nb, -na])
	var c0 := -Vector3(cos(a0), 0, -sin(a0))
	var c1 := Vector3(cos(a1), 0, -sin(a1))
	_quad(st, [point(a0, rin, top), point(a0, rin, bot), point(a0, rout, bot), point(a0, rout, top)], [c0, c0, c0, c0])
	_quad(st, [point(a1, rin, top), point(a1, rout, top), point(a1, rout, bot), point(a1, rin, bot)], [c1, c1, c1, c1])


static func build_mesh(a0: float, a1: float, rin: float, rout: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	append_slice(st, a0, a1, rin, rout, h)
	return st.commit()


func setup(a0: float, a1: float, t: int, m: Mesh, mat: Material) -> void:
	start_angle = a0
	end_angle = a1
	type = t
	mesh = m
	material_override = mat
