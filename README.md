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
  scans. Linux debug binary only for now.
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

### Third-party tools (bundled as-is, full credit to original authors)

- **script-ide** by Marius Hanl (MIT, license included) — transforms the
  Script UI into an IDE-like tabbed interface with an improved Outline.
- **InstanceDock** by KoBeWi — dedicated dock to keep scenes close at hand for
  instancing.
- **inspector_tabs** by PiCode — splits the Inspector's property classes into
  their own tabs.
- **mesh_inspector** by @Gamehooe — shows stats about the selected mesh.
- **dev-console** by cherttov (license included) — in-game developer console
  to run/output in-game commands.
- **tnowe_extra_controls** by Don Tnowe — folded into `ezui/utils/` as
  internal helper code (no longer its own sub-plugin).

## License

MIT (see `LICENSE`) for everything in this repo except the bundled third-party
tools under "Third-party tools" above, which keep whatever license they
shipped with (see each tool's own folder).
