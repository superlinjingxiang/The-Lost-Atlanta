extends CanvasLayer

@onready var title_label: Label = $VBoxContainer/CenterContainer/ContentVBox/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/CenterContainer/ContentVBox/SubtitleLabel
@onready var start_button: Button = $VBoxContainer/CenterContainer/ContentVBox/Buttons/StartButton
@onready var continue_button: Button = $VBoxContainer/CenterContainer/ContentVBox/Buttons/ContinueButton
@onready var quit_button: Button = $VBoxContainer/CenterContainer/ContentVBox/Buttons/QuitButton
@onready var confirm_dialog: AcceptDialog = $ConfirmDialog
@onready var bg_texture: TextureRect = $Background

func _ready() -> void:
	PhaseManager.transition_to(PhaseManager.PHASE_MAIN_MENU)
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	confirm_dialog.confirmed.connect(_on_quit_confirmed)
	_update_continue_button()
	_load_background()

func _load_background() -> void:
	var texture: Texture2D = load("res://assets/images/ui/main_menu_bg.png") as Texture2D
	if texture:
		bg_texture.texture = texture

func _update_continue_button() -> void:
	continue_button.disabled = not SaveManager.has_save()

func _on_start_pressed() -> void:
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/Intro.tscn")

func _on_continue_pressed() -> void:
	if SaveManager.has_save() and GameManager.continue_saved_game():
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit_pressed() -> void:
	confirm_dialog.popup_centered()

func _on_quit_confirmed() -> void:
	get_tree().quit()
