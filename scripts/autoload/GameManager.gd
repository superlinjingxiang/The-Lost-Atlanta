extends Node

signal game_started
signal day_changed(new_day)
signal game_over(reason)

var day: int = 1
var resources: Dictionary = {
	"food": 100,
	"morale": 80,
	"stamina": 100
}
var is_game_active: bool = false

func _ready() -> void:
	pass

func reset() -> void:
	day = 1
	resources = {
		"food": 100,
		"morale": 80,
		"stamina": 100
	}
	is_game_active = true
	game_started.emit()

func add_day() -> void:
	if not is_game_active:
		return
	day += 1
	day_changed.emit(day)

func modify_resource(resource_name: String, amount: int) -> void:
	if not resources.has(resource_name):
		return
	resources[resource_name] = clampi(resources[resource_name] + amount, 0, 100)

func trigger_game_over(reason: String = "") -> void:
	is_game_active = false
	game_over.emit(reason)

func has_saved_game() -> bool:
	return SaveManager.has_save()