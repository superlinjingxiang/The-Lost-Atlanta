extends Node

const SAVE_PATH: String = "user://save.dat"

func _ready() -> void:
	pass

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func save_game(data: Dictionary) -> bool:
	return false

func load_game() -> Dictionary:
	return {}