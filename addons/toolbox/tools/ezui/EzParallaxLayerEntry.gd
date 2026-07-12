extends Resource
class_name EzParallaxLayerEntry

## Jedna warstwa dla EzParallaxBg. `target` wskazuje na DOWOLNY child node
## EzParallaxBg — Sprite2D, MeshInstance3D, cały poddrzewo, cokolwiek. Ten
## resource nie trzyma tekstury ani nie tworzy niczego samodzielnie, tylko
## mówi "ten node ma się przesuwać z tą siłą".

@export var target: NodePath
## Jak mocno warstwa reaguje na ruch kamery: 0 = nieruchoma (daleki plan),
## 1 = rusza się z kamerą 1:1, <1 wolniej (dalej), >1 szybciej (bliżej).
## Jedna liczba działa i dla Node2D (Vector2 * float), i dla Node3D
## (Vector3 * float).
@export var shift: float = 0.5
