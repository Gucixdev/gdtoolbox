# mats

One material node (`Mat`) driven by layers, on top of a modular shader.

```
mat.gdshader              the uber-shader: orchestration only
inc/
  common.gdshaderinc      hashes, value noise, voronoi
  mapping.gdshaderinc     UV tiling/offset/rotation/scroll, atlas, stochastic anti-tiling, triplanar (world/object)
  normal.gdshaderinc      bump-from-height, detail normal blending
  parallax.gdshaderinc    parallax occlusion mapping: adaptive layers, bisection, reference plane, self-shadow, DEPTH
  occlusion.gdshaderinc   AO: baked / cavity (height) / curvature (normal) / vertex, multi-bounce, specular occlusion
  matcap.gdshaderinc      matcap + seamless blending + cel ramp
  npr.gdshaderinc         view-space specular, opal iridescence
shaders/                  standalone shaders built from the same modules
  pom_surface             PBR + POM + self-shadow + AO, writes DEPTH so geometry intersects the displaced surface
  triplanar_pbr           rock/snow triplanar PBR blended by slope and noise
  dissolve                noise or directional dissolve with a glowing edge
  outline                 constant-pixel-width outline, use as `next_pass`
  ssao_post               screen-space AO as a full-screen quad (fallback for renderers without built-in SSAO)
```

## Using it
`Mat` takes `MatcapLayer` / `PBRLayer` resources. The PBR layer has subgroups for Normal, Specular, Occlusion, Parallax,
and the newer *Parallax (advanced)*, *Occlusion (advanced)*, *Mapping*, *Bump & detail*. Layer property names are the shader uniform names.

By default `Mat` overrides the whole mesh (`material_override`) — fine for single-material meshes. For a mesh with several
surfaces (body/eyes/metal...), give each surface its own `Mat` node (same `targets`, different `surface_idx`); `surface_idx`
picks the one surface that node drives instead of blanking the rest.

Including a module in your own shader:
```glsl
shader_type spatial;
#include "res://addons/toolbox/tools/mats/inc/mapping.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/parallax.gdshaderinc"
void fragment() {
    vec2 uv = ez_map_uv(UV);
    PomResult pom = pom_apply(uv, pom_view_tangent(VIEW, TANGENT, BINORMAL, NORMAL), length(VERTEX), pom_refine);
    uv = pom.uv;
    ALBEDO = ez_tex(albedo_tex, uv).rgb;
}
```

## Notes
- **Renderer**: written for Forward+ / Mobile / Compatibility. Depth conventions differ per renderer; the includes branch on
  `CURRENT_RENDERER`. Built-in SSAO/SSIL exist only in Forward+; `ssao_post` is for Mobile and Compatibility exports.
- **POM and tangents**: parallax needs a tangent frame, so it is skipped in triplanar mapping. `DEPTH` is written only by
  `shaders/pom_surface` (writing it disables early-z, so the uber-shader leaves it off).
- **AO modes**: `ALBEDO` (default, legacy) paints occlusion into the colour so it shows with no lights; `AMBIENT` uses the engine's
  AO output and only dims ambient light (plus `ao_light_affect` of direct light).
- **Outline** uses an inverted hull: meshes with split (hard-edge) normals show gaps at corners. Use "Smooth Normals" on `Mat`.
- **SSAO post** has no blur pass (a post quad can't read its own output), so it is grainy; raise `samples` or enable
  `temporal_noise` with TAA. For quality in Forward+, use the Environment's SSAO instead.
- Regression harness: `tests/render_materials.gd` renders the legacy feature set to PNG; the refactor was verified bit-identical
  against the original shader for every non-POM case. `tests/render_shaders.gd` renders the standalone shaders.
