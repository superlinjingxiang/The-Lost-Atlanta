extends CanvasLayer

@onready var day_label: Label = $RootMargin/MainVBox/HeaderVBox/DayLabel
@onready var phase_label: Label = $RootMargin/MainVBox/HeaderVBox/PhaseLabel
@onready var food_label: Label = $RootMargin/MainVBox/StatsGrid/FoodLabel
@onready var morale_label: Label = $RootMargin/MainVBox/StatsGrid/MoraleLabel
@onready var stamina_label: Label = $RootMargin/MainVBox/StatsGrid/StaminaLabel
@onready var action_points_label: Label = $RootMargin/MainVBox/StatsGrid/ActionPointsLabel
@onready var story_label: Label = $RootMargin/MainVBox/StoryPanel/StoryLabel
@onready var search_button: Button = $RootMargin/MainVBox/ActionsVBox/SearchButton
@onready var rest_button: Button = $RootMargin/MainVBox/ActionsVBox/RestButton
@onready var explore_button: Button = $RootMargin/MainVBox/ActionsVBox/ExploreButton
@onready var fortify_button: Button = $RootMargin/MainVBox/ActionsVBox/FortifyButton
@onready var next_day_button: Button = $RootMargin/MainVBox/NextDayButton

func _ready() -> void:
	search_button.pressed.connect(_on_action_pressed.bind(GameManager.ACTION_SEARCH))
	rest_button.pressed.connect(_on_action_pressed.bind(GameManager.ACTION_REST))
	explore_button.pressed.connect(_on_action_pressed.bind(GameManager.ACTION_EXPLORE))
	fortify_button.pressed.connect(_on_action_pressed.bind(GameManager.ACTION_FORTIFY))
	next_day_button.pressed.connect(_on_next_day_pressed)

	GameManager.state_changed.connect(_refresh)
	GameManager.action_resolved.connect(_on_action_resolved)
	GameManager.night_event_resolved.connect(_on_night_event_resolved)
	GameManager.game_over.connect(_on_game_over)
	PhaseManager.phase_changed.connect(_on_phase_changed)

	if not GameManager.is_game_active:
		GameManager.start_new_game()

	_refresh()

func _exit_tree() -> void:
	if GameManager.state_changed.is_connected(_refresh):
		GameManager.state_changed.disconnect(_refresh)
	if GameManager.action_resolved.is_connected(_on_action_resolved):
		GameManager.action_resolved.disconnect(_on_action_resolved)
	if GameManager.night_event_resolved.is_connected(_on_night_event_resolved):
		GameManager.night_event_resolved.disconnect(_on_night_event_resolved)
	if GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.disconnect(_on_game_over)
	if PhaseManager.phase_changed.is_connected(_on_phase_changed):
		PhaseManager.phase_changed.disconnect(_on_phase_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		PhaseManager.transition_to(PhaseManager.PHASE_MAIN_MENU)
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_action_pressed(action_id: String) -> void:
	GameManager.perform_day_action(action_id)

func _on_next_day_pressed() -> void:
	GameManager.resolve_night_event()

func _on_action_resolved(message: String) -> void:
	story_label.text = message
	_refresh()

func _on_night_event_resolved(message: String) -> void:
	story_label.text = message
	_refresh()

func _on_phase_changed(_current_phase: String, _previous_phase: String, _context: Dictionary) -> void:
	_refresh()

func _on_game_over(_reason: String) -> void:
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _refresh() -> void:
	day_label.text = "第 %d 天" % GameManager.day
	phase_label.text = _get_phase_text(PhaseManager.current_phase)
	food_label.text = "食物：%d" % GameManager.resources.get("food", 0)
	morale_label.text = "精神：%d" % GameManager.resources.get("morale", 0)
	stamina_label.text = "体力：%d" % GameManager.resources.get("stamina", 0)
	action_points_label.text = "行动格：%d / %d" % [GameManager.action_points, GameManager.MAX_ACTION_POINTS]

	var can_act := PhaseManager.current_phase == PhaseManager.PHASE_DAY_ACTION_SELECT and GameManager.action_points > 0
	search_button.disabled = not can_act
	rest_button.disabled = not can_act
	explore_button.disabled = not can_act
	fortify_button.disabled = not can_act
	next_day_button.visible = PhaseManager.current_phase == PhaseManager.PHASE_NIGHT_EVENT
	next_day_button.disabled = not next_day_button.visible

	if story_label.text == "":
		story_label.text = "废墟里的广播只剩杂音。你需要规划今天的行动，并撑过夜晚。"

func _get_phase_text(phase_name: String) -> String:
	match phase_name:
		PhaseManager.PHASE_RUN_START:
			return "准备开始"
		PhaseManager.PHASE_DAY_START:
			return "清晨"
		PhaseManager.PHASE_DAY_ACTION_SELECT:
			return "白天行动"
		PhaseManager.PHASE_DAY_ACTION_RESOLVE:
			return "行动结算"
		PhaseManager.PHASE_NIGHT_EVENT:
			return "夜晚事件"
		PhaseManager.PHASE_DAY_END:
			return "日结"
		PhaseManager.PHASE_GAME_OVER:
			return "结局"
		_:
			return "未知阶段"
