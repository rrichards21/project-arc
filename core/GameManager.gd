extends Node

signal match_started
signal match_ended(winner_team: int)
signal score_updated(team_a: int, team_b: int)

enum GameState { MENUS, PLAYING, GAME_OVER }

var current_state: GameState = GameState.MENUS
var score_team_1: int = 0
var score_team_2: int = 0
var score_team_a: int = 0
var score_team_b: int = 0
var time_remaining: float = 0.0

func _ready() -> void:
	_setup_inputs()
	print("GameManager initialized.")

func _setup_inputs() -> void:
	# Define key mappings programmatically to avoid complex project.godot editing
	var inputs = {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"dash": [KEY_SPACE, KEY_SHIFT],
		"grab": [KEY_E, KEY_ENTER, MOUSE_BUTTON_LEFT],
		"reset_match": [KEY_R],
	}
	
	for action in inputs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in inputs[action]:
				var ev
				if typeof(key) == TYPE_INT and key < 10: # Mouse buttons are small ints
					ev = InputEventMouseButton.new()
					ev.button_index = key
				else:
					ev = InputEventKey.new()
					ev.keycode = key
				InputMap.action_add_event(action, ev)

func start_match() -> void:
	current_state = GameState.PLAYING
	score_team_1 = 0
	score_team_2 = 0
	time_remaining = GameConfigs.MATCH_DURATION
	match_started.emit()
	print("Match started!")

func on_goal_scored(team_scored_against: int) -> void:
	if team_scored_against == 1:
		score_team_2 += 1
		print("GOAL for Team 2! Score: %d - %d" % [score_team_1, score_team_2])
	else:
		score_team_1 += 1
		print("GOAL for Team 1! Score: %d - %d" % [score_team_1, score_team_2])
	
	# Future: Reset ball position signal?

func end_match() -> void:
	current_state = GameState.GAME_OVER
	var winner = 0
	if score_team_a > score_team_b:
		winner = 1
	elif score_team_b > score_team_a:
		winner = 2
	match_ended.emit(winner)
	print("Match ended. Winner: Team %d" % winner)

func add_score(team: int) -> void:
	if team == 1:
		score_team_a += 1
	else:
		score_team_b += 1
	score_updated.emit(score_team_a, score_team_b)
	print("Score updated: %d - %d" % [score_team_a, score_team_b])

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_match"):
		get_tree().reload_current_scene()
		start_match() # Reset internal vars

	if current_state == GameState.PLAYING:
		time_remaining -= delta
		if time_remaining <= 0:
			end_match()
