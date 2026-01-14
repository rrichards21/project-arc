extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Ensure cursor is visible
	$CenterContainer/VBoxContainer/BtnLocal.grab_focus()

func _on_btn_local_pressed() -> void:
	# Change to the main game scene
	get_tree().change_scene_to_file("res://core/Main.tscn")

func _on_btn_practice_pressed() -> void:
	# Change to the main game scene (Same as Local for now)
	# Future: Set GameManager.practice_mode = true
	get_tree().change_scene_to_file("res://core/Main.tscn")

func _on_btn_online_pressed() -> void:
	print("Online mode coming soon...")
	# For now, maybe just change text to "Coming Soon"
	$CenterContainer/VBoxContainer/BtnOnline.text = "Coming Soon..."

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
