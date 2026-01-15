extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Ensure cursor is visible
	$CenterContainer/VBoxContainer/BtnLocal.grab_focus()

func _on_btn_local_pressed() -> void:
	# Local Play defaults
	# For now, start match directly or go to lobby as host?
	# Simple: Start Match single player logic if wanted, or just Host Local.
	# Let's direct to Lobby as "Local Host" for simplicity
	GameManager.host_game()
	get_tree().change_scene_to_file("res://core/Lobby.tscn")

func _on_btn_practice_pressed() -> void:
	# Change to the main game scene (Same as Local for now)
	# Future: Set GameManager.practice_mode = true
	get_tree().change_scene_to_file("res://core/Main.tscn")

func _on_btn_host_pressed() -> void:
	GameManager.host_game()
	get_tree().change_scene_to_file("res://core/Lobby.tscn")

func _on_btn_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://core/ControlsConfig.tscn")

func _on_btn_join_pressed() -> void:
	var ip = $CenterContainer/VBoxContainer/LineEditIP.text
	if ip.strip_edges() == "":
		ip = "save-needle.gl.at.ply.gg"
		
	GameManager.join_game(ip)
	get_tree().change_scene_to_file("res://core/Lobby.tscn")

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
