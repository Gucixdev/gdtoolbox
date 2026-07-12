class_name EzSaveConfig
extends Resource

## Wspólna konfiguracja dla EzSave, EzLoad i EzAutoSave.
## Stwórz jeden plik .tres i przeciągnij do wszystkich trzech nodów —
## wtedy slot i entries są ustawione w jednym miejscu.

@export var slot: int = 0
@export var entries: Array[SaveEntry] = []
