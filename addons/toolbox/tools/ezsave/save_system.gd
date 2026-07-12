extends Node
## EzSave — autoload singleton. Slot-based save/load z threadingiem.
##
## Szybkie użycie:
##   SaveSystem.save(0, {"score": 100, "level": 3})
##   var data = SaveSystem.load(0)
##
## Async (nie blokuje głównego wątku):
##   await SaveSystem.save_async(0, {"score": 100})
##   var data = await SaveSystem.load_async(0)

signal saved(slot: int)
signal loaded(slot: int, data: Dictionary)
signal save_failed(slot: int, error: int)
signal load_failed(slot: int)

const SAVE_DIR  := "user://saves/"
const EXTENSION := ".sav"

# ── Sync API ──────────────────────────────────────────────────────────────────

func save(slot: int, data: Dictionary) -> bool:
	_ensure_dir()
	var res := _DictResource.new()
	res.data = data
	var err := ResourceSaver.save(res, _path(slot))
	if err != OK:
		push_error("[SaveSystem] save slot %d failed: %s" % [slot, error_string(err)])
		save_failed.emit(slot, err)
		return false
	saved.emit(slot)
	return true

func load(slot: int) -> Dictionary:
	var path := _path(slot)
	if not ResourceLoader.exists(path):
		push_warning("[SaveSystem] slot %d not found." % slot)
		load_failed.emit(slot)
		return {}
	var res := ResourceLoader.load(path) as _DictResource
	if not res:
		push_error("[SaveSystem] slot %d corrupt." % slot)
		load_failed.emit(slot)
		return {}
	loaded.emit(slot, res.data)
	return res.data

func delete(slot: int) -> void:
	var path := _path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))

func list_slots() -> Array[int]:
	_ensure_dir()
	var slots: Array[int] = []
	var dir := DirAccess.open(SAVE_DIR)
	if not dir: return slots
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(EXTENSION):
			var n := f.get_basename().to_int()
			slots.append(n)
		f = dir.get_next()
	slots.sort()
	return slots

# ── Async API ─────────────────────────────────────────────────────────────────

## Zapisuje na wątku. Awaytuj sygnał saved / save_failed lub po prostu awajtuj tę funkcję.
func save_async(slot: int, data: Dictionary) -> Signal:
	var sem  := Semaphore.new()
	var mtx  := Mutex.new()
	var ok   := false

	var thread := Thread.new()
	thread.start(func():
		_ensure_dir()
		var res := _DictResource.new()
		res.data = data
		var err := ResourceSaver.save(res, _path(slot))
		mtx.lock()
		ok = (err == OK)
		mtx.unlock()
		sem.post()
	)

	await _wait_sem(sem)
	thread.wait_to_finish()

	if ok: saved.emit(slot)
	else:  save_failed.emit(slot, FAILED)
	return saved if ok else save_failed

## Ładuje na wątku. Awaytuj sygnał loaded / load_failed lub po prostu awajtuj tę funkcję.
func load_async(slot: int) -> Signal:
	var path := _path(slot)
	if not ResourceLoader.exists(path):
		load_failed.emit(slot)
		return load_failed

	var sem    := Semaphore.new()
	var result := {}

	var thread := Thread.new()
	thread.start(func():
		var res := ResourceLoader.load(path)
		if res is _DictResource:
			result = res.data
		sem.post()
	)

	await _wait_sem(sem)
	thread.wait_to_finish()

	if result.is_empty(): load_failed.emit(slot)
	else:                  loaded.emit(slot, result)
	return loaded if not result.is_empty() else load_failed

# ── Internal ──────────────────────────────────────────────────────────────────

func _path(slot: int) -> String:
	return SAVE_DIR + str(slot) + EXTENSION

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _wait_sem(sem: Semaphore) -> void:
	while true:
		if sem.try_wait(): break
		await get_tree().process_frame

# wewnętrzny Resource trzymający dane
class _DictResource extends Resource:
	@export var data: Dictionary = {}
