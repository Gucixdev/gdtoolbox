@tool
extends EditorPlugin
## Mesh Inspector: surface, vertex and triangle counts plus bounding box size and
## volume at the top of the inspector for a MeshInstance3D or a Mesh resource.
## The numbers come from mesh_stats.gd.

const Stats := preload("mesh_stats.gd")

var _inspector: StatsInspector


func _enter_tree() -> void:
	_inspector = StatsInspector.new()
	add_inspector_plugin(_inspector)


func _exit_tree() -> void:
	remove_inspector_plugin(_inspector)
	_inspector = null


class StatsInspector extends EditorInspectorPlugin:
	func _can_handle(object: Object) -> bool:
		return object is MeshInstance3D or object is Mesh

	func _parse_begin(object: Object) -> void:
		add_custom_control(StatsPanel.new(object))


class StatsPanel extends VBoxContainer:
	var _target: Object
	var _body := VBoxContainer.new()

	func _init(target: Object) -> void:
		_target = target
		add_child(_body)
		var refresh := Button.new()
		refresh.text = "Refresh mesh stats"
		refresh.flat = true
		refresh.pressed.connect(_rebuild)
		add_child(refresh)

	func _ready() -> void:
		# a mesh edited in place emits `changed`: keep the numbers current
		var mesh := _mesh()
		if mesh != null and not mesh.changed.is_connected(_rebuild):
			mesh.changed.connect(_rebuild)
		_rebuild()

	func _mesh() -> Mesh:
		if _target is MeshInstance3D:
			return (_target as MeshInstance3D).mesh
		return _target as Mesh

	func _rebuild() -> void:
		for child in _body.get_children():
			child.queue_free()
		var mesh := _mesh()
		if mesh == null:
			_row("Mesh", "(none)")
			return
		var world: Variant = null
		if _target is MeshInstance3D and (_target as MeshInstance3D).is_inside_tree():
			world = (_target as MeshInstance3D).global_transform
		var s := Stats.compute(mesh, world)
		_row("Surfaces", str(s.surfaces.size()))
		_row("Vertices", Stats.group_digits(s.vertices))
		_row("Triangles", Stats.group_digits(s.triangles))
		_row("Size (local)", _vec(s.size))
		_row("Volume (local)", "%.3f m³" % s.volume)
		if s.has("world_size"):
			_row("Size (world)", _vec(s.world_size))
			_row("Volume (world)", "%.3f m³" % s.world_volume)
		if s.surfaces.size() > 1:
			for i in s.surfaces.size():
				var surf: Dictionary = s.surfaces[i]
				_row("  Surface %d" % i, "%s tris, %s" % [Stats.group_digits(surf.triangles), surf.material])

	func _vec(v: Vector3) -> String:
		return "%.3f × %.3f × %.3f m" % [v.x, v.y, v.z]

	func _row(label: String, value: String) -> void:
		var line := HBoxContainer.new()
		var l := Label.new()
		l.text = label
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := Label.new()
		v.text = value
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(l)
		line.add_child(v)
		_body.add_child(line)
