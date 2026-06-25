extends Node

signal phase_changing(from_phase, to_phase, context)
signal phase_changed(current_phase, previous_phase, context)
signal hook_failed(hook_key, owner, method_name)

const PHASE_BOOT: String = "boot"
const PHASE_MAIN_MENU: String = "main_menu"
const PHASE_RUN_START: String = "run_start"
const PHASE_DAY_START: String = "day_start"
const PHASE_DAY_ACTION_SELECT: String = "day_action_select"
const PHASE_DAY_ACTION_RESOLVE: String = "day_action_resolve"
const PHASE_NIGHT_EVENT: String = "night_event"
const PHASE_DAY_END: String = "day_end"
const PHASE_GAME_OVER: String = "game_over"

const TIMING_BEFORE_ENTER: String = "before_enter"
const TIMING_AFTER_ENTER: String = "after_enter"
const TIMING_BEFORE_EXIT: String = "before_exit"
const TIMING_AFTER_EXIT: String = "after_exit"

var current_phase: String = PHASE_BOOT
var previous_phase: String = ""
var phase_context: Dictionary = {}

var _hooks: Dictionary = {}

func transition_to(next_phase: String, context: Dictionary = {}) -> void:
	if next_phase == "":
		return

	var from_phase := current_phase
	var next_context := context.duplicate(true)

	_run_hooks(from_phase, TIMING_BEFORE_EXIT, next_context)
	phase_changing.emit(from_phase, next_phase, next_context)
	_run_hooks(from_phase, TIMING_AFTER_EXIT, next_context)
	_run_hooks(next_phase, TIMING_BEFORE_ENTER, next_context)

	previous_phase = from_phase
	current_phase = next_phase
	phase_context = next_context.duplicate(true)

	phase_changed.emit(current_phase, previous_phase, phase_context)
	_run_hooks(next_phase, TIMING_AFTER_ENTER, phase_context)

func register_hook(
	phase_name: String,
	timing: String,
	owner: Object,
	method_name: StringName,
	priority: int = 0
) -> void:
	if phase_name == "" or timing == "" or not is_instance_valid(owner):
		return
	if not owner.has_method(method_name):
		return

	var hook_key := _get_hook_key(phase_name, timing)
	if not _hooks.has(hook_key):
		_hooks[hook_key] = []

	_hooks[hook_key].append({
		"owner": owner,
		"method_name": method_name,
		"priority": priority
	})
	_hooks[hook_key].sort_custom(_sort_hooks)

func unregister_hooks_for_owner(owner: Object) -> void:
	for hook_key in _hooks.keys():
		var entries: Array = _hooks[hook_key]
		var kept_entries: Array = []
		for entry in entries:
			if entry.get("owner") != owner:
				kept_entries.append(entry)
		_hooks[hook_key] = kept_entries

func emit_custom_hook(hook_name: String, context: Dictionary = {}) -> void:
	_run_hook_key(hook_name, context)

func get_hook_name(phase_name: String, timing: String) -> String:
	return _get_hook_key(phase_name, timing)

func _run_hooks(phase_name: String, timing: String, context: Dictionary) -> void:
	_run_hook_key(_get_hook_key(phase_name, timing), context)

func _run_hook_key(hook_key: String, context: Dictionary) -> void:
	if not _hooks.has(hook_key):
		return

	var entries: Array = _hooks[hook_key]
	for entry in entries:
		var owner := entry.get("owner") as Object
		var method_name := entry.get("method_name") as StringName
		if not is_instance_valid(owner) or not owner.has_method(method_name):
			hook_failed.emit(hook_key, owner, method_name)
			continue
		owner.call(method_name, context)

func _get_hook_key(phase_name: String, timing: String) -> String:
	return "%s.%s" % [phase_name, timing]

func _sort_hooks(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("priority", 0)) > int(b.get("priority", 0))
