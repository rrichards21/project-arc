class_name Main
extends Node3D

@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var env: WorldEnvironment = $WorldEnvironment
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	print("Main Scene Ready")
	GameManager.match_started.connect(_on_match_started)
	# Auto-start for MVP testing
	GameManager.call_deferred("start_match")

func _on_match_started() -> void:
	print("Main: Setting up match...")
	
	# Load resources
	var arena_scn = load("res://objects/Arena.tscn")
	var player_scn = load("res://objects/Player.tscn")
	var ball_scn = load("res://objects/Ball.tscn")
	var goal_scn = load("res://objects/Goal.tscn")
	
	# Instance Arena
	var arena = arena_scn.instantiate()
	add_child(arena)
	
	# Instance Player
	var player = player_scn.instantiate()
	player.position = Vector3(0, 1, 5)
	add_child(player)
	
	# Assign Camera Target
	if camera is CameraFollow:
		camera.target = player
	
	# Instance Ball
	var ball = ball_scn.instantiate()
	ball.position = Vector3(0, 2, 0)
	ball.name = "Ball" # Important for detection
	add_child(ball)
	
	# Instance Goal 1 (Team 1 Defends, North Side)
	var goal1 = goal_scn.instantiate()
	goal1.position = Vector3(0, 0.5, -12)
	goal1.rotation_degrees.y = 0 # Face South (Towards Center)
	goal1.team_id = 1
	goal1.connect("goal_scored", _on_goal_scored)
	add_child(goal1)

	# Instance Goal 2 (Team 2 Defends, South Side)
	var goal2 = goal_scn.instantiate()
	goal2.position = Vector3(0, 0.5, 12)
	goal2.rotation_degrees.y = 180 # Face North (Towards Center)
	goal2.team_id = 2
	goal2.connect("goal_scored", _on_goal_scored)
	add_child(goal2)

func _on_goal_scored(team_id: int) -> void:
	GameManager.on_goal_scored(team_id)
	$HUD/ScoreLabel.text = "%d - %d" % [GameManager.score_team_1, GameManager.score_team_2]
