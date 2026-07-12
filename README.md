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
auto-discovery mechanism — some are the author's own, several are third-party
(full credit below, each keeps its own license file where it shipped with one).

## Bundled tools

### Own tools (author: Gucixdev / pet)

- **dock_collapse** — collapse/expand arrows for the editor's left/right side
  docks (Godot 4.7 `EditorDock`), including the Toolbox dock itself.
- **ezanim** — UI animation node: fades, pops, slides, wiggles.
- **ezmaterials** — shader material system with matcap, PBR, phong, voronoi,
  opal, and POM shading.
- **ezdialogue** — JSON + signal based dialogue system with global bus,
  branches, choices, quests.
- **ezsave** — slot-based async save/load (`EzSave` + `EzLoad` nodes).
- **ezui** — NinePatch-based custom controls (panel, button, bar) plus a
  grab-bag of small reusable nodes merged in from the old `ui_tools`: radial
  menu, 3D progress bar, collapsible container/panel, UI anim, and now
  **EzParallaxBg** (generic parallax — works for 2D or 3D, since it doesn't
  create any geometry itself: add your own children — `Sprite2D`,
  `MeshInstance3D`, whole subtrees, anything — then in `layers` point an
  `EzParallaxLayerEntry` at each child's `NodePath` with a `shift` float
  [0 = static/background, 1 = moves with the camera 1:1, in between/above
  for depth]. Auto-detects whichever camera — 2D or 3D — is active in the
  viewport and offsets each layer from its starting position accordingly)
  **EzEquipment** (generic
  equipment-slot node: named slots holding arbitrary `Resource` items,
  `equip`/`unequip`/`get_equipped`, `equipped`/`unequipped` signals — not
  game-specific, just a slot manager), and **EzInventory** (generic hotbar:
  slot count is `backpack_level * 3` [lvl1=3, lvl2=6, lvl3=9, scales linearly
  beyond that], `select_next`/`select_prev` cycle the active slot with
  wraparound for a Minecraft-style scroll-to-select hotbar — items are plain
  `Resource`s, no shape assumed).
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
- **godot_3d_cursor** by Marco (license included) — Blender-style 3D cursor
  (Shift+Right Click to place, Shift+S for the pie menu).
- **dev-console** by cherttov (license included) — in-game developer console
  to run/output in-game commands.
- **zylann.hterrain** by Marc Gilleron (license included) — heightmap-based
  terrain.
- **tnowe_extra_controls** by Don Tnowe — now lives inside `ezui/` (was its
  own bundle under the now-retired `ui_tools`).

## License

No blanket license file yet — bundled third-party tools keep whatever license
they shipped with (see each tool's own folder). Ask before assuming anything
about the rest.
