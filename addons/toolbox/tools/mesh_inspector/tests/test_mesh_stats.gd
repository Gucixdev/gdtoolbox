## Mesh Inspector tests. From the project root:
##   godot --headless --path . -s res://addons/toolbox/tools/mesh_inspector/tests/test_mesh_stats.gd
extends SceneTree
var fails := 0
func ck(name: String, ok: bool, got = null) -> void:
	if not ok:
		fails += 1
		print("FAIL ", name, " got ", got)
func _init() -> void:
	var S = load("res://addons/toolbox/tools/mesh_inspector/mesh_stats.gd")
	var box := BoxMesh.new()
	box.size = Vector3(1, 2, 3)
	var b: Dictionary = S.compute(box)
	ck("box counts", b.surfaces.size() == 1 and b.vertices == 24 and b.triangles == 12, b)
	ck("box size/volume", b.size.is_equal_approx(Vector3(1, 2, 3)) and is_equal_approx(b.volume, 6.0), b)
	ck("bare mesh has no world data", not b.has("world_size"), b.keys())
	var w: Dictionary = S.compute(box, Transform3D(Basis.from_scale(Vector3(2, 2, 2)), Vector3.ZERO))
	ck("world", w.world_size.is_equal_approx(Vector3(2, 4, 6)) and is_equal_approx(w.world_volume, 48.0), w)
	for m in [SphereMesh.new(), CapsuleMesh.new(), PlaneMesh.new(), CylinderMesh.new(), TorusMesh.new()]:
		var d: Dictionary = S.compute(m)
		ck(m.get_class() + " has triangles", d.triangles > 0 and d.vertices > 0, d)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0,0,0), Vector3(1,0,0), Vector3(1,1,0), Vector3(0,1,0)])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2, 0,2,3])
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	ck("indexed", S.compute(am).vertices == 4 and S.compute(am).triangles == 2, S.compute(am))
	var sarr := []
	sarr.resize(Mesh.ARRAY_MAX)
	sarr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0,0,0), Vector3(1,0,0), Vector3(0,1,0), Vector3(1,1,0), Vector3(0,2,0)])
	var sm := ArrayMesh.new()
	sm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, sarr)
	ck("strip", S.compute(sm).triangles == 3, S.compute(sm))
	var larr := []
	larr.resize(Mesh.ARRAY_MAX)
	larr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3(2,0,0), Vector3(3,3,3)])
	var lm := ArrayMesh.new()
	lm.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, larr)
	ck("lines", S.compute(lm).triangles == 0, S.compute(lm))
	var two := ArrayMesh.new()
	two.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	two.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	ck("two surfaces", S.compute(two).surfaces.size() == 2 and S.compute(two).triangles == 4, S.compute(two))
	var e: Dictionary = S.compute(ArrayMesh.new())
	ck("empty mesh", e.surfaces.size() == 0 and e.vertices == 0, e)
	var mat := StandardMaterial3D.new()
	mat.resource_name = "stone"
	box.material = mat
	ck("material name", S.compute(box).surfaces[0].material == "stone", S.compute(box).surfaces[0])
	ck("material none", S.material_name(null) == "(none)")
	ck("group digits", S.group_digits(0) == "0" and S.group_digits(999) == "999" and S.group_digits(1000) == "1 000" and S.group_digits(1234567) == "1 234 567" and S.group_digits(-12345) == "-12 345")
	var ps = load("res://addons/toolbox/tools/mesh_inspector/mesh_inspector.gd")
	ck("plugin script loads", ps != null and ps.can_instantiate(), ps)
	print("mesh inspector tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
