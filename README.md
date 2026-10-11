# gdtoolbox

Auto-loading plugin loader for the Godot 4.7 editor. Drop a sub-plugin folder
into `addons/toolbox/tools/` and it's picked up automatically — no manual
`project.godot` editing, no per-plugin enable dance. A "Toolbox" manager dock
shows every discovered tool with a per-tool enable/disable toggle.

Drop the `addons/` folder into your project's `res://` and enable **toolbox**
in Project Settings → Plugins.

## How it works

- `addons/toolbox/plugin.gd` continuously scans `addons/toolbox/tools/` for
  sub-folders with their own `plugin.cfg`, loads/unloads them, and writes the
  discovered state to `addons/toolbox/tools_config.cfg`.
- The **Toolbox** dock (bottom-right by default) lists every discovered tool
  with a checkbox — flip it to enable/disable that one tool without touching
  the others.
- **dock_collapse** (bundled, see below) also hides/shows the Toolbox dock
  itself along with the rest of the editor's side docks.

Ships with a bunch of tools pre-installed as a working demo of the
auto-discovery mechanism — some are own tools, several are third-party
(full credit below, each keeps its own license file where it shipped with one).

## Bundled tools

### Own tools

- **dock_collapse** — collapse/expand arrows for the editor's left/right side
  docks (Godot 4.7 `EditorDock`), including the Toolbox dock itself.
- **ezanim** — `AnimPlayer`: one node for fades, pops, slides, wiggles
  (replaces the old separate `EzAnim`/`EzAnimPlayer`/`UIAnim`).
- **mats** — `Mat`: shader material node (matcap/PBR layers over one uber-shader),
  with per-surface override (`surface_idx`) for multi-material meshes. Also ships
  standalone derivative shaders: POM, triplanar PBR, dissolve, outline, SSAO post.
- **ecs** — archetype-table ECS: a GDExtension binding (`EcsWorld`/`EcsView`) over
  a native C core, plus a thin GDScript layer (`EcsEntity`/`EcsComponent`/`EcsSystem`,
  behind the autoload `Ecs`) — bulk per-table iteration instead of SceneTree-group
  scans. Own `README.md` inside the tool folder. Ships Linux and Windows x86_64 (debug AND
  release); macOS not built (needs Apple's SDK to cross-build).
- **ezdialogue** — `DialogueSystem`: plays a `DialogueGraph` resource
  (`start()`/`advance()`/`choose()`, `line`/`choices` signals, branches and
  quests via `DialogueNode`/`DialogueChoice`).
- **ezsave** — `SaveSystem`: Skyrim/Witcher-style saves (manual/quick/rotating
  autosave, continue, thumbnails, `.bak`) behind the autoload `Saves` — track
  a node via group `"save"` + Inspector metadata `save_props`, or
  `Saves.track($Node, ["position", "hp"])` from code.
- **ezui** — `Control3D` puts any `Control` (a `ProgressBar`, a `Label`, a
  whole HUD) into 3D space via an internal `SubViewport` billboarded onto a
  `Sprite3D` — replaces the old separate `EzHealthBar3D`/`ProgressBar3D`
  (for a flat panel/button/bar, just use the built-in `Panel`/`Button`/
  `ProgressBar` directly — `Ez9*` is gone). `UIDynamics` is one-node spring
  physics for UI (hover/press/focus/appear react on their own, pure
  GDScript, no Tweens to hand-wire). `EzUI` is a plain marker node for a UI
  subtree's root. Also still here: **EzParallaxBg** (generic parallax for
  2D or 3D — point an `EzParallaxLayerEntry` at each child's `NodePath` with
  a `shift` float, 0=static/background to 1=moves with the camera 1:1),
  **EzEquipment** (named equipment slots over arbitrary `Resource` items),
  **EzInventory** (generic scroll-to-select hotbar, slot count scales with
  `backpack_level`), and a radial menu (`radial/RadialMenu.gd`).
- **godot_mcp_server** — WebSocket bridge exposing the editor (scene tree,
  properties, project settings, console/errors, running scenes) to an MCP
  client, with a locally-generated auth secret per session.
- **plugin-sync** — syncs a GDScript linter plugin in from a source project.
- **mesh_inspector** — surface, vertex and triangle counts plus local and world
  bounding box size/volume at the top of the Inspector for a `MeshInstance3D` or a
  `Mesh` resource. Counts come from the surface arrays (cheap on big meshes); the
  logic is in `mesh_stats.gd` with tests in `tests/`.

### Third-party tools (bundled with their MIT licenses and original authors)

Each of these is MIT licensed; the license text with the author's copyright line
sits next to the code (`LICENSE` in the tool folder).

- **script-ide** by Marius Hanl
  ([Maran23/script-ide](https://github.com/Maran23/script-ide)) — transforms the Script UI
  into an IDE-like tabbed interface with an improved Outline.
  ([`LICENSE`](addons/toolbox/tools/script-ide/LICENSE))
- **dev-console** by cherttov
  ([godot-dev-console](https://github.com/cherttov/godot-dev-console)) — in-game developer
  console to run/output in-game commands.
  ([`LICENSE`](addons/toolbox/tools/dev-console/LICENSE))
- **InstanceDock** by KoBeWi
  ([Godot-Instance-Dock](https://github.com/KoBeWi/Godot-Instance-Dock)) — dedicated
  dock to keep scenes close at hand for instancing.
  ([`LICENSE`](addons/toolbox/tools/InstanceDock/LICENSE))
- **inspector_tabs** by PiCode9560
  ([Godot-Inspector-Tabs](https://github.com/PiCode9560/Godot-Inspector-Tabs)) — splits
  the Inspector's property classes into their own tabs.
  ([`LICENSE`](addons/toolbox/tools/inspector_tabs/LICENSE))
- **Extra Controls** by Don Tnowe
  ([godot-extra-controls](https://github.com/don-tnowe/godot-extra-controls)) — the
  container and control helpers in `ezui/utils/`.
  ([`LICENSE.tnowe-extra-controls`](addons/toolbox/tools/ezui/utils/LICENSE.tnowe-extra-controls))

## License

MIT (see `LICENSE`). The bundled third-party tools above are MIT too and keep
their own copyright notices in their folders.
