extends Control

func _ready() -> void:
	# Hide initially
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	var new_state = not get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	
	if new_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$CenterContainer/VBoxContainer/BtnResume.grab_focus()
	else:
		# Assuming we want to capture mouse again when playing
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Note: Main.gd might enforce mouse capture too, verify conflicts.

func _on_btn_resume_pressed() -> void:
	toggle_pause()

func _on_btn_restart_pressed() -> void:
	toggle_pause() # Unpause first
	GameManager.start_match() # Reset vars
	get_tree().reload_current_scene()

func _on_btn_menu_pressed() -> void:
	get_tree().paused = false # Unpause directly
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Force mouse visible for menu
	get_tree().change_scene_to_file("res://core/Menu.tscn")
