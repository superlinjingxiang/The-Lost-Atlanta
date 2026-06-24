extends CanvasLayer

@onready var title_label: Label = $VBoxContainer/CenterContainer/ContentVBox/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/CenterContainer/ContentVBox/SubtitleLabel
@onready var start_button: Button = $VBoxContainer/CenterContainer/ContentVBox/Buttons/StartButton
@onready var continue_button: Button = $VBoxContainer/CenterContainer/ContentVBox/Buttons/ContinueButton
@onready var quit_button: Button = $VBoxContainer/CenterContainer/ContentVBox/Buttons/QuitButton
@onready var confirm_dialog: AcceptDialog = $ConfirmDialog
@onready var bg_texture: TextureRect = $Background

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	confirm_dialog.confirmed.connect(_on_quit_confirmed)
	_update_continue_button()
	_load_background()

func _load_background() -> void:
	var texture := load("res://assets/images/ui/bg.png") as Texture2D
	if texture:
		bg_texture.texture = texture

func _update_continue_button() -> void:
	if SaveManager.has_save():
		continue_button.disabled = false
	else:
		continue_button.disabled = true

func _on_start_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit_pressed() -> void:
	confirm_dialog.popup_centered()

func _on_quit_confirmed() -> void:
	get_tree().quit()