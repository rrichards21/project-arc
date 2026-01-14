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
	
	# Instance Arena (Static, everyone instantiates it or it should be part of the scene)
	# Ideally Arena is part of the map, but here we instantiate it. 
	# Since it's static and has no sync, it's fine if everyone instances it LOCALLY, 
	# UNLESS we want to sync it. For now, let's keep Arena local for everyone 
	# so it doesn't need network overhead, assuming it doesn't move.
	var arena = arena_scn.instantiate()
	add_child(arena)
	
	# Networked Objects: Only Server Spawns, Spawner Replicates
	if multiplayer.is_server():
		# Instance Players
		for id in GameManager.players:
			var player = player_scn.instantiate()
			player.name = str(id) # Important: Set name to peer ID logic
			player.position = Vector3(0, 1, 0)
			# Randomize/Distribute spawn positions based on team later
			add_child(player)
		
		# Instance Ball
		var ball = ball_scn.instantiate()
		ball.position = Vector3(0, 2, 0)
		ball.name = "Ball"
		add_child(ball)
		
		# Instance Goal 1
		var goal1 = goal_scn.instantiate()
		goal1.position = Vector3(0, 0.5, -12)
		goal1.rotation_degrees.y = 0
		goal1.team_id = 1
		goal1.name = "Goal1"
		goal1.connect("goal_scored", _on_goal_scored)
		add_child(goal1)

		# Instance Goal 2
		var goal2 = goal_scn.instantiate()
		goal2.position = Vector3(0, 0.5, 12)
		goal2.rotation_degrees.y = 180
		goal2.team_id = 2
		goal2.name = "Goal2"
		goal2.connect("goal_scored", _on_goal_scored)
		add_child(goal2)

func _process(_delta: float) -> void:
	# Camera setup for Client (since they don't spawn the player themselves anymore)
	if camera.target == null:
		var my_id = multiplayer.get_unique_id()
		if has_node(str(my_id)):
			camera.target = get_node(str(my_id))
			
	# Update HUD Timer
	var m = int(GameManager.time_remaining) / 60
	var s = int(GameManager.time_remaining) % 60
	$HUD/TimeLabel.text = "%02d:%02d" % [m, s]

func _on_goal_scored(team_id: int) -> void:
	GameManager.on_goal_scored(team_id)
	$HUD/ScoreLabel.text = "%d - %d" % [GameManager.score_team_1, GameManager.score_team_2]
