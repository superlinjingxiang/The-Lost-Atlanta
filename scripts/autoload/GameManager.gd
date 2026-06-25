extends Node

signal game_started
signal day_changed(new_day)
signal game_over(reason)
signal state_changed
signal action_resolved(message)
signal night_event_resolved(message)

const MAX_ACTION_POINTS: int = 3
const WIN_DAY: int = 30

const ACTION_SEARCH: String = "search"
const ACTION_REST: String = "rest"
const ACTION_EXPLORE: String = "explore"
const ACTION_FORTIFY: String = "fortify"

var day: int = 1
var resources: Dictionary = {
	"food": 100,
	"morale": 80,
	"stamina": 100
}
var action_points: int = MAX_ACTION_POINTS
var is_game_active: bool = false
var last_action_id: String = ""
var last_night_message: String = ""

func reset() -> void:
	start_new_game()

func start_new_game() -> void:
	day = 1
	resources = {
		"food": 100,
		"morale": 80,
		"stamina": 100
	}
	action_points = MAX_ACTION_POINTS
	last_action_id = ""
	last_night_message = ""
	is_game_active = true
	game_started.emit()
	PhaseManager.transition_to(PhaseManager.PHASE_RUN_START)
	_start_day()
	state_changed.emit()

func continue_saved_game() -> bool:
	var data := SaveManager.load_game()
	if data.is_empty():
		return false

	var run_state: Dictionary = data.get("run_state", {})
	day = int(run_state.get("day", 1))
	resources = run_state.get("resources", {
		"food": 100,
		"morale": 80,
		"stamina": 100
	})
	action_points = int(run_state.get("action_points", MAX_ACTION_POINTS))
	is_game_active = true
	last_action_id = ""
	last_night_message = ""
	PhaseManager.transition_to(str(run_state.get("phase", PhaseManager.PHASE_DAY_ACTION_SELECT)))
	state_changed.emit()
	return true

func add_day() -> void:
	if not is_game_active:
		return
	day += 1
	day_changed.emit(day)
	state_changed.emit()

func modify_resource(resource_name: String, amount: int) -> void:
	if not resources.has(resource_name):
		return
	resources[resource_name] = clampi(resources[resource_name] + amount, 0, 100)
	state_changed.emit()

func perform_day_action(action_id: String) -> bool:
	if not is_game_active:
		return false
	if PhaseManager.current_phase != PhaseManager.PHASE_DAY_ACTION_SELECT:
		return false
	if action_points <= 0:
		return false

	last_action_id = action_id
	PhaseManager.transition_to(PhaseManager.PHASE_DAY_ACTION_RESOLVE, {"action_id": action_id})
	var message := _resolve_action(action_id)
	action_points -= 1
	action_resolved.emit(message)

	if _has_failed():
		trigger_game_over("资源耗尽")
		return true

	if action_points <= 0:
		PhaseManager.transition_to(PhaseManager.PHASE_NIGHT_EVENT)
	else:
		PhaseManager.transition_to(PhaseManager.PHASE_DAY_ACTION_SELECT)

	state_changed.emit()
	return true

func resolve_night_event() -> void:
	if not is_game_active:
		return
	if PhaseManager.current_phase != PhaseManager.PHASE_NIGHT_EVENT:
		return

	last_night_message = "夜里有东西撞上了临时路障。你们没睡踏实，精神下降了。"
	modify_resource("morale", -5)
	night_event_resolved.emit(last_night_message)
	_finish_day()

func trigger_game_over(reason: String = "") -> void:
	is_game_active = false
	PhaseManager.transition_to(PhaseManager.PHASE_GAME_OVER, {"reason": reason})
	SaveManager.delete_save()
	game_over.emit(reason)
	state_changed.emit()

func has_saved_game() -> bool:
	return SaveManager.has_save()

func build_save_data() -> Dictionary:
	return {
		"meta": {
			"version": 1,
			"save_time": Time.get_datetime_string_from_system(false, true)
		},
		"run_state": {
			"day": day,
			"phase": PhaseManager.current_phase,
			"resources": resources.duplicate(true),
			"action_points": action_points
		},
		"systems": {}
	}

func _start_day() -> void:
	action_points = MAX_ACTION_POINTS
	PhaseManager.transition_to(PhaseManager.PHASE_DAY_START, {"day": day})
	PhaseManager.transition_to(PhaseManager.PHASE_DAY_ACTION_SELECT, {"day": day})

func _finish_day() -> void:
	PhaseManager.transition_to(PhaseManager.PHASE_DAY_END, {"day": day})
	modify_resource("food", -10)
	modify_resource("stamina", -5)

	if _has_failed():
		trigger_game_over("资源耗尽")
		return

	if day >= WIN_DAY:
		trigger_game_over("你撑过了 30 天")
		return

	add_day()
	_start_day()
	SaveManager.save_game(build_save_data())
	state_changed.emit()

func _resolve_action(action_id: String) -> String:
	match action_id:
		ACTION_SEARCH:
			modify_resource("food", 15)
			modify_resource("stamina", -12)
			return "你在废弃便利店找到了一些罐头，但来回搬运消耗了体力。"
		ACTION_REST:
			modify_resource("stamina", 20)
			modify_resource("morale", 5)
			return "你们轮流守夜前小睡了一会儿，精神和体力都恢复了一些。"
		ACTION_EXPLORE:
			modify_resource("morale", 8)
			modify_resource("stamina", -10)
			return "你探索了附近街区，找到一条可能通往安全区的线索。"
		ACTION_FORTIFY:
			modify_resource("stamina", -8)
			modify_resource("morale", 3)
			return "你加固了入口。木板不算牢靠，但总比没有强。"
		_:
			return "你犹豫了一会儿，什么也没有改变。"

func _has_failed() -> bool:
	return int(resources.get("food", 0)) <= 0 or int(resources.get("morale", 0)) <= 0 or int(resources.get("stamina", 0)) <= 0
