extends Resource
class_name EzParallaxLayerEntry

## Jedna warstwa dla EzParallaxBg — tekstura + jak szybko przewija się
## względem kamery.

@export var texture: Texture2D
## X < 1 = wolniej niż kamera (dalszy plan), X = 1 = rusza się z kamerą 1:1,
## X > 1 = szybciej (bliższy plan). Typowo Y zostaje 1.0 (bez przewijania w
## pionie) chyba że robisz też pionowy parallax.
@export var scroll_scale: Vector2 = Vector2(0.5, 1.0)
@export var z_index: int = 0
## Powiela teksturę w poziomie o jej własną szerokość (ParallaxLayer.motion_mirroring)
## — bez szwu przy przewijaniu w nieskończoność. Wyłącz dla warstw skończonych
## (np. sylwetka gór w tle, która nie ma się powtarzać).
@export var mirror_horizontally: bool = true
