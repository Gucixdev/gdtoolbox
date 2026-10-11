@tool
extends RefCounted
## What the Mesh Inspector shows, as plain data. No editor state, so it can be
## used and tested on its own. Counts come from the surface arrays, which stays
## cheap on big meshes (no per-vertex MeshDataTool pass).


## `world` is the node's global Transform3D, or null for a bare Mesh resource.
static func compute(mesh: Mesh, world: Variant = null) -> Dictionary:
	var surfaces: Array = []
	var vertices := 0
	var triangles := 0
	for i in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var elements: int = verts.size()
		var index: Variant = arrays[Mesh.ARRAY_INDEX]
		if index is PackedInt32Array and not (index as PackedInt32Array).is_empty():
			elements = (index as PackedInt32Array).size()
		var tris := 0
		# only ArrayMesh exposes the primitive type; the built-in shapes
		# (BoxMesh, SphereMesh, ...) are always plain triangle lists
		var primitive := Mesh.PRIMITIVE_TRIANGLES
		if mesh is ArrayMesh:
			primitive = (mesh as ArrayMesh).surface_get_primitive_type(i)
		match primitive:
			Mesh.PRIMITIVE_TRIANGLES:
				tris = elements / 3
			Mesh.PRIMITIVE_TRIANGLE_STRIP:
				tris = maxi(elements - 2, 0)
		vertices += verts.size()
		triangles += tris
		surfaces.append({
			"vertices": verts.size(),
			"triangles": tris,
			"material": material_name(mesh.surface_get_material(i)),
		})
	var aabb: AABB = mesh.get_aabb()
	var size: Vector3 = aabb.size.abs()
	var out := {
		"surfaces": surfaces,
		"vertices": vertices,
		"triangles": triangles,
		"size": size,
		"volume": size.x * size.y * size.z,
	}
	if world is Transform3D:
		var wsize: Vector3 = ((world as Transform3D) * aabb).size.abs()
		out["world_size"] = wsize
		out["world_volume"] = wsize.x * wsize.y * wsize.z
	return out


static func material_name(material: Material) -> String:
	if material == null:
		return "(none)"
	if material.resource_name != "":
		return material.resource_name
	if material.resource_path != "":
		return material.resource_path.get_file()
	return material.get_class()


## 1234567 -> "1 234 567"
static func group_digits(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += " "
		out += s[i]
	return ("-" if n < 0 else "") + out
