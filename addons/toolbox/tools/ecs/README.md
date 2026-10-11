# ecs

Archetype-table Entity-Component-System. The actual storage (entities, component registration,
archetype tables, queries) is a native C core (`EcsWorld`/`EcsView`, a GDExtension binding over
a standalone C99 library) - this folder's GDScript is a thin, optional layer on top of it, not
the storage itself. Replaces the old `EzEntity`/`EzComponent`/`EzSystem` (Node + SceneTree-group
facade, O(n) scans) with real contiguous-column storage and bulk per-table iteration.

```
ecs.gdextension                 points at bin/ for each platform/config
bin/
  libecs_gdext.linux.template_debug.x86_64.so     editor + debug export
  libecs_gdext.linux.template_release.x86_64.so   release export
Ecs.gd                          autoload singleton: the shared EcsWorld + component-id cache
EcsComponent.gd                 base for a component definition (byte_size/to_bytes/from_bytes)
EcsEntity.gd                    Node wrapper around one native entity id
EcsSystem.gd                    Node wrapper that runs a query every _process()
test/
  EcsExampleStatComponent.gd    generic depletable/regenerating float stat (hp/mp/sp/...)
  EcsExampleHp.gd / Mp.gd / Sp.gd    one-line subclasses (class_name only, all logic inherited)
  EcsExampleStatTickSystem.gd   generic regen/decay tick for one stat component
```

The native core and this binding's source are in [`native/`](native/) (C99, `native/godot/gdext`
for the GDExtension); `native/godot/README.md` has the exact build commands, and the binaries in
`bin/` are built from it. The folder carries a `.gdignore`, so the editor does not scan the C sources.

Linux x86_64 and Windows x86_64 ship (debug + release binaries, cross-built via mingw-w64 for
Windows). macOS isn't set up - it needs Apple's SDK (osxcross) to cross-build from Linux, which
isn't available here; add a build under `bin/` and a matching entry in `ecs.gdextension` if you
get access to one. Building for Windows surfaced one real portability bug in the native core:
`ecs_mem.c`'s aligned allocator used POSIX's `posix_memalign`, which MinGW/MSVC don't have -
fixed with a `_WIN32` branch using `_aligned_malloc`/`_aligned_free` instead.

## Using it

Define a component by subclassing `EcsComponent`:

```gdscript
@tool
class_name Position
extends EcsComponent

static func byte_size() -> int:
	return 8 # 2x float32

static func to_bytes(data: Dictionary) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_float(0, data.get("x", 0.0))
	b.encode_float(4, data.get("y", 0.0))
	return b

static func from_bytes(bytes: PackedByteArray):
	return {"x": bytes.decode_float(0), "y": bytes.decode_float(4)}
```

A tag (pure presence/absence, e.g. `Dead`) only needs `byte_size()` left at the default 0 -
skip `to_bytes`/`from_bytes`. The script needs a `class_name`; that name is also the native
component's registered name (Godot's own global-class-name uniqueness is what keeps two
different component types from colliding).

Attach data to entities via `EcsEntity` (a plain `Node`, drop it anywhere in the tree - under a
`CharacterBody3D`, a UI root, whatever owns the entity conceptually):

```gdscript
var e := EcsEntity.new()
add_child(e)
e.add_component(Position, {"x": 1.0, "y": 2.0})
var p: Dictionary = e.get_component(Position)
e.remove_component(Position)
```

Write a system by subclassing `EcsSystem` and overriding `_process_batch()` - it's called once
per matching archetype table, not once per entity:

```gdscript
class_name MoveSystem
extends EcsSystem

func _ready() -> void:
	required_components = [Position, Velocity]
	super._ready()

func _process_batch(view: EcsView, delta: float) -> void:
	var pos_id := Ecs.register(Position)
	var vel_id := Ecs.register(Velocity)
	var pos := view.column_bytes(pos_id)   # a COPY - mutate it, then write it back
	var vel := view.column_bytes(vel_id)
	for i in view.count():
		pos.encode_float(i * 8, pos.decode_float(i * 8) + vel.decode_float(i * 8) * delta)
		pos.encode_float(i * 8 + 4, pos.decode_float(i * 8 + 4) + vel.decode_float(i * 8 + 4) * delta)
	view.set_column_bytes(pos_id, pos)
```

Drop one instance of a system node anywhere in the tree (an autoload, or under the level root);
it runs its query every `_process()` while `active` is true. `EcsExampleStatTickSystem` is a
ready-made example of this pattern (generic regen/decay for any `EcsExampleStatComponent`
subclass - set `stat_script` in the Inspector).

For a one-entity-at-a-time style instead of bulk columns, call `view.next()` yourself (returns
an entity id, or -1 once exhausted) rather than `next_table()`/`column_bytes()`.

## Rules the native core expects you to follow

- **One world per game is normal.** `Ecs.world` is the shared instance everything above uses;
  spin up your own `EcsWorld.new()` only if a project genuinely needs an isolated simulation.
- **`column_bytes()` returns a copy.** Mutating it does nothing until you call
  `set_column_bytes()` with the whole column back - this is the one real gotcha found and fixed
  in this binding (the native `ecs_view_column()` pointer is meant for in-place writes; the
  Godot binding has to copy out to hand you a `PackedByteArray`, so the write-back is explicit).
- **Don't add/remove a component on any entity while a view that queries it is still open** -
  same rule as mutating an array mid-loop. Build a fresh view per `_process()` call (which
  `EcsSystem` already does) rather than holding one across frames.
- **Not thread-safe.** One `EcsWorld` is meant to be driven from one thread - Godot's main
  thread, for normal gameplay code.
- A pointer/row from `add_component`/`get_component` on `EcsWorld` itself is only valid until
  the next add/remove on *any* entity sharing that archetype (it can move rows around);
  `get_component_bytes`/`set_component_bytes` copy, so they're the safe default outside a
  system's bulk column loop.

## Known gaps (tracked upstream, not yet surfaced here)

The native core (`/data/dev/setup/base/holyC/ecs`, see its own `ROADMAP.md`) has grown well past
this binding's current surface - query caching, a system scheduler, events, relationships,
hierarchies, change detection, and a souls-like stats/gameplay-effects module all exist natively
but aren't exposed through `EcsWorld`/`EcsView` yet. This binding only covers the base archetype
API (entities, components, tags, views) - the right slice for replacing `EzEntity`/`EzComponent`/
`EzSystem`, not yet a full port of everything the native core can do.
