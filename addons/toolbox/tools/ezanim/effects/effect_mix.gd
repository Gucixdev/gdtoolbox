@tool
class_name EffectMix
extends AnimEffect

@export var effects: Array[AnimEffect] = []
@export_enum("Parallel", "Sequential") var mode: int = 0
