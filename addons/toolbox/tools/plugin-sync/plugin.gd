@tool
extends EditorPlugin

func _enter_tree() -> void:
	_run_sync()

func _run_sync() -> void:
	var output: Array = []
	var exit_code: int

	print("[Plugin Sync] Running sync script...")

	if OS.get_name() == "Windows":
		var ps1 = ProjectSettings.globalize_path("res://scripts/tools/sync-linter-plugin.ps1")
		exit_code = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ps1], output, true)
	else:
		var sh = ProjectSettings.globalize_path("res://scripts/tools/sync-linter-plugin.sh")
		if not FileAccess.file_exists(sh):
			push_warning("[Plugin Sync] No sync script at %s — nothing to do." % sh)
			return
		exit_code = OS.execute("bash", [sh], output, true)

	for line in output:
		print(line)

	if exit_code == 0:
		print("[Plugin Sync] Sync complete!")
		EditorInterface.get_resource_filesystem().scan()
	else:
		push_error("[Plugin Sync] Failed with exit code: %d" % exit_code)
