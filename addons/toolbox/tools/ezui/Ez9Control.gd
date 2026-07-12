@tool
class_name Ez9Control
extends NinePatchRect

## NinePatchRect + Control. Podmień `texture` w Inspektorze żeby użyć własnej.
## Domyślna tekstura: assets/panel_default.png (64×64, zaokrąglone rogi, ciemny panel).

const _ASSET  := "res://addons/toolbox/tools/ezui/assets/panel_default.png"
# 64px tekstura, promień rogu 11px + 2px obwódki -> margin musi objąć całą
# krzywiznę (inaczej NinePatchRect rozciąga zaokrąglony róg razem ze środkiem
# i wygląda to brzydko w dużych rozmiarach). Niższa rozdzielczość PNG (dawniej
# 20x20) to był właściwy powód brzydkiego skalowania, nie sam NinePatch.
const _MARGIN := 12

static var _default_tex: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if not texture:
		texture = _get_default_tex()
		patch_margin_left   = _MARGIN
		patch_margin_right  = _MARGIN
		patch_margin_top    = _MARGIN
		patch_margin_bottom = _MARGIN

static func _get_default_tex() -> Texture2D:
	if _default_tex: return _default_tex
	if ResourceLoader.exists(_ASSET):
		_default_tex = load(_ASSET)
	if not _default_tex:
		_default_tex = _generate_tex()
	return _default_tex

## Fallback gdyby PNG jeszcze nie zaimportowany przez Godot.
static func _generate_tex() -> ImageTexture:
	const S := 48; const R := 8.0; const B := 2.0
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var clear := Color(0,0,0,0); var border := Color(0.31,0.35,0.44,1)
	var top := Color(0.18,0.20,0.25,0.95); var bot := Color(0.11,0.13,0.16,0.95)
	for y in S:
		for x in S:
			var tl := x<R and y<R; var tr := x>=S-R and y<R
			var bl := x<R and y>=S-R; var br := x>=S-R and y>=S-R
			var ic := tl or tr or bl or br
			var d := 0.0
			if tl: d = sqrt((x-R)**2 + (y-R)**2)
			elif tr: d = sqrt((x-(S-R))**2 + (y-R)**2)
			elif bl: d = sqrt((x-R)**2 + (y-(S-R))**2)
			elif br: d = sqrt((x-(S-R))**2 + (y-(S-R))**2)
			if ic and d > R: img.set_pixel(x, y, clear)
			elif (ic and d > R-B) or (not ic and (x<B or x>=S-B or y<B or y>=S-B)):
				img.set_pixel(x, y, border)
			else: img.set_pixel(x, y, top.lerp(bot, float(y)/float(S-1)))
	return ImageTexture.create_from_image(img)
