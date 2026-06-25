extends CanvasLayer

@onready var intro_label: Label = $IntroLabel
@onready var countdown_label: Label = $CountdownLabel
@onready var timer: Timer = $CountdownTimer

var countdown: int = 3

func _ready() -> void:
	PhaseManager.transition_to("intro")
	intro_label.text = "—— 失落的亚特兰大 ——\n\n2026年，一场突如其来的瘟疫席卷了亚特兰大。\n短短几周内，城市沦陷，通讯中断，文明崩塌。\n你被困在城区边缘的一间废弃公寓里。\n窗外是游荡的感染者，耳边只有远处传来的零星枪声。\n食物和水正在减少，你不知道还能撑多久。\n但你还不想放弃。\n\n活下去，直到最后一刻。"

	countdown = 3
	countdown_label.text = str(countdown)
	timer.timeout.connect(_on_timer_timeout)
	timer.start(1.0)

func _on_timer_timeout() -> void:
	countdown -= 1
	countdown_label.text = str(countdown) if countdown > 0 else ""

	if countdown <= 0:
		timer.stop()
		GameManager.start_new_game()
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
