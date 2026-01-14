extends Control

@onready var item_list: ItemList = $CenterContainer/VBoxContainer/ItemList
@onready var btn_ready: Button = $CenterContainer/VBoxContainer/BtnReady
@onready var btn_start: Button = $CenterContainer/VBoxContainer/BtnStart

func _ready() -> void:
	GameManager.player_list_changed.connect(refresh_list)
	
	# Only Host sees Start button
	if multiplayer.is_server():
		btn_start.visible = true
		btn_start.disabled = true
	else:
		btn_start.visible = false
		
	refresh_list()

func refresh_list() -> void:
	item_list.clear()
	var all_ready = true
	var player_count = 0
	
	for id in GameManager.players:
		var p = GameManager.players[id]
		var status = "READY" if p.ready else "WAITING"
		item_list.add_item("%s [%s]" % [p.name, status])
		
		# Check if everyone is ready (for host)
		if not p.ready:
			all_ready = false
		player_count += 1
			
	if multiplayer.is_server():
		btn_start.disabled = (not all_ready) or (player_count < 1)

func _on_btn_ready_pressed() -> void:
	rpc("toggle_ready", multiplayer.get_unique_id())

@rpc("any_peer", "call_local")
func toggle_ready(id: int) -> void:
	if GameManager.players.has(id):
		GameManager.players[id].ready = not GameManager.players[id].ready
		
		# Update local UI button if it's me
		if id == multiplayer.get_unique_id():
			var is_ready = GameManager.players[id].ready
			btn_ready.text = "NOT READY" if is_ready else "READY"
			
		GameManager.player_list_changed.emit()

func _on_btn_start_pressed() -> void:
	rpc("start_game_rpc")

@rpc("authority", "call_local")
func start_game_rpc() -> void:
	get_tree().change_scene_to_file("res://core/Main.tscn")
	GameManager.start_match()

func _on_btn_leave_pressed() -> void:
	GameManager.reset_networking()
	GameManager.current_state = GameManager.GameState.MENUS
	get_tree().change_scene_to_file("res://core/Menu.tscn")
