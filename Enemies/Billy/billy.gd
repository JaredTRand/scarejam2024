extends CharacterBody3D

@onready var face_dir:Node3D = $face_dir
@onready var nav_agent:NavigationAgent3D = $NavigationAgent3D
@onready var player_view_state:String = "HIDDEN" # HIDDEN, PURSUING, SEARCHING, WAITING
@onready var navRegion:NavigationRegion3D = $"../NavigationRegion3D"
@onready var wait_in_pos_timer:Timer = $wait_in_pos_timer

@export var SPEED:float
@export var RUN_SPEED:float
@export var TURN_SPEED:float
@export var ENEMY_FOV = 70
@onready var wander_pos = set_rand_wander_pos()
var player_pos
@onready var rng = RandomNumberGenerator.new()

var player_in_view

func _ready():
	ENEMY_FOV = cos(deg_to_rad(ENEMY_FOV))

func _physics_process(delta):
	$"../Player/UserInterface/DebugPanel".add_property("Wandering POS", wander_pos, 5)
	$"../Player/UserInterface/DebugPanel".add_property("Enemy POS", global_transform.origin, 6)
	$"../Player/UserInterface/DebugPanel".add_property("Enemy State", player_view_state, 7)
	if(player_view_state == "WAITING"):
		return
	elif(player_view_state == "PURSUING"): #
		move_to_player()
	elif(player_view_state == "HIDDEN"):
		if(!wander_pos):
			set_rand_wander_pos()
		if(snapped(wander_pos.x, 0.1) == snapped(global_transform.origin.x, 0.1) and snapped(wander_pos.z, 0.1)): #if timer stopped or at pos, get new pos
			player_view_state = "WAITING"
			wait_in_pos_timer.start(rng.randf_range(1.0, 11.0))
		else:
			wander()

func _process(delta):
	if(player_in_view):
		check_if_player_in_sight()

func update_target_loc(target_loc):
	player_pos = target_loc

func set_rand_wander_pos():
	wander_pos = NavigationServer3D.region_get_random_point(navRegion.get_rid(), 1, false)
	nav_agent.target_position = wander_pos
	
func move_to_player():
	nav_agent.target_position = player_pos
	
	face_dir.look_at(nav_agent.target_position, Vector3.UP)
	rotate_y(deg_to_rad(face_dir.rotation.y * TURN_SPEED))
	var current_loc = global_transform.origin
	var next_loc = nav_agent.get_next_path_position()
	var new_velocity = (next_loc - current_loc).normalized() * SPEED
	
	velocity = new_velocity
	move_and_slide()

func wander():
	if(!wander_pos):
		set_rand_wander_pos()
		
	face_dir.look_at(nav_agent.get_next_path_position(), Vector3.UP)
	rotate_y(deg_to_rad(face_dir.rotation.y * TURN_SPEED))
	var current_loc = global_transform.origin
	var next_loc = nav_agent.get_next_path_position()
	var new_velocity = (next_loc - current_loc).normalized() * SPEED
	velocity = new_velocity
	move_and_slide()


func _on_wait_in_pos_timer_timeout():
	set_rand_wander_pos()
	player_view_state = "HIDDEN"

func check_if_player_in_sight():
		var direction = global_position.direction_to( player_pos )
		var facing = (global_transform.basis.tdotz(direction)) * -1
		print(facing)
		print(ENEMY_FOV)
		print("")
		var canseeya
		if(facing > ENEMY_FOV):
			canseeya = "Im lookin at ya"
		else:
			canseeya = "I cant see ya"
		$"../Player/UserInterface/DebugPanel".add_property("Can enemy see you", canseeya, 8)
		
		player_view_state = "PURSUING"

func _on_see_player_body_entered(body):
	if(body.is_in_group("player")):
		player_in_view = true

func _on_see_player_body_exited(body):
	if(body.is_in_group("player")):
		player_in_view = false
