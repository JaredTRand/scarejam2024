extends CharacterBody3D

@onready var face_dir:Node3D = $face_dir
@onready var nav_agent:NavigationAgent3D = $NavigationAgent3D
@onready var player_view_state:String = "HIDDEN" # HIDDEN, NOTICED
@onready var previous_player_view_state:String = "HIDDEN" # HIDDEN, NOTICED
#@onready var billy_status:String = "WANDERING" # WANDERING, PURSUING, SEARCHING, WAITING, NOTICED, GOINGTOLASTPOS
@onready var navRegion:NavigationRegion3D = $"../NavigationRegion3D"
@onready var wait_in_pos_timer:Timer = $wait_in_pos_timer

@export var SPEED:float
@export var RUN_SPEED:float
@export var TURN_SPEED:float
@export var ENEMY_FOV = 70
@export var TELEPORT_PERC = 25

@onready var wander_pos = set_rand_wander_pos()
var player_pos
var last_player_pos
@onready var rng = RandomNumberGenerator.new()
@onready var cur_speed = RUN_SPEED
@onready var vision_cast:RayCast3D = $vision_cast
@onready var vision_cast2:RayCast3D = $vision_cast2
@onready var vision_cast3:RayCast3D = $vision_cast3
var player_in_view:bool
var player_noticed:bool

@onready var teleport_spots = get_tree().get_nodes_in_group("teleport_spot")
@onready var teleport_timer = $teleport_timer
var last_teleport_pad

func _ready():
	ENEMY_FOV = cos(deg_to_rad(ENEMY_FOV))

func _physics_process(delta):
	$"../Player/UserInterface/DebugPanel".add_property("Wandering POS", wander_pos)
	$"../Player/UserInterface/DebugPanel".add_property("Enemy POS", global_transform.origin)
	$"../Player/UserInterface/DebugPanel".add_property("Enemy State", player_view_state)
	$"../Player/UserInterface/DebugPanel".add_property("player_in_view", player_in_view)
	$"../Player/UserInterface/DebugPanel".add_property("player_noticed", player_noticed)
	$"../Player/UserInterface/DebugPanel".add_property("SPEED", SPEED)
	$"../Player/UserInterface/DebugPanel".add_property("last_player_pos", last_player_pos)

	if(player_view_state == "NOTICED"):
		if(!player_noticed): return
		if(previous_player_view_state == "PURSUING"):
			cur_speed = RUN_SPEED
		else:
			cur_speed = SPEED
		move_to_player()
	elif(player_view_state == "GOINGTOLASTPOS"):
		if(previous_player_view_state == "PURSUING"):
			cur_speed = RUN_SPEED
		else:
			cur_speed = SPEED
		cur_speed = RUN_SPEED
		
		if(abs(wander_pos.x - global_transform.origin.x) < 0.1 and abs(wander_pos.z - global_transform.origin.z) < 0.1): #if timer stopped or at pos, get new pos
			switch_state("WAITING")
			wait_in_pos_timer.start(rng.randf_range(1.0, 11.0))
		else:
			wander()
	elif(player_view_state == "PURSUING"): #
		if(!player_in_view): return
		cur_speed = RUN_SPEED
		move_to_player()
	elif(player_view_state == "WAITING"):
		return
	elif(player_view_state == "HIDDEN"):
		cur_speed = SPEED
		if(!wander_pos):
			set_rand_wander_pos()
		
		if(abs(wander_pos.x - global_transform.origin.x) < 0.1 and abs(wander_pos.z - global_transform.origin.z) < 0.1): #if timer stopped or at pos, get new pos
			switch_state("WAITING")
			wait_in_pos_timer.start(rng.randf_range(1.0, 11.0))
		else:
			wander()

func _process(delta):
	if(player_in_view or player_noticed):
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
	var new_velocity = (next_loc - current_loc).normalized() * cur_speed
	
	velocity = new_velocity
	move_and_slide()

func wander():
	if(!wander_pos):
		set_rand_wander_pos()
		
	face_dir.look_at(nav_agent.get_next_path_position(), Vector3.UP)
	rotate_y(deg_to_rad(face_dir.rotation.y * TURN_SPEED))
	var current_loc = global_transform.origin
	var next_loc = nav_agent.get_next_path_position()
	var new_velocity = (next_loc - current_loc).normalized() * cur_speed
	velocity = new_velocity
	move_and_slide()


func _on_wait_in_pos_timer_timeout():
	set_rand_wander_pos()
	switch_state("HIDDEN")

func check_if_player_in_sight():
		var direction = global_position.direction_to( player_pos )
		var facing = (global_transform.basis.tdotz(direction)) * -1
		var canseeya
		
		vision_cast.look_at(player_pos)
		vision_cast2.look_at(player_pos)
		vision_cast3.look_at(player_pos)
		var can_see = (vision_cast.get_collider() && vision_cast.get_collider().is_in_group("player")) || (vision_cast2.get_collider() && vision_cast2.get_collider().is_in_group("player")) || (vision_cast3.get_collider() && vision_cast3.get_collider().is_in_group("player"))
		
		if(facing > ENEMY_FOV && can_see):
			canseeya = "Im lookin at ya"
			if(player_in_view):
				switch_state("PURSUING")
			elif(player_noticed):
				switch_state("NOTICED")
		else:
			canseeya = "I cant see ya"
			if(!player_view_state == "GOINGTOLASTPOS"):
				lost_View_of_player()
			
		$"../Player/UserInterface/DebugPanel".add_property("Can enemy see you", canseeya)
		$"../Player/UserInterface/DebugPanel".add_property("behind wall? ", !can_see)
		
func lost_View_of_player():
	switch_state("GOINGTOLASTPOS")
	last_player_pos = player_pos
	wander_pos = last_player_pos
	nav_agent.target_position = wander_pos
	

func switch_state(newstate):
	previous_player_view_state = player_view_state
	player_view_state = newstate

func _on_see_player_body_entered(body):
	if(body.is_in_group("player")):
		player_in_view = true

func _on_see_player_body_exited(body):
	if(body.is_in_group("player")):
		player_in_view = false
		#player_view_state = "NOTICED"

func _on_notice_player_body_entered(body):
	if(body.is_in_group("player")):
		player_noticed = true

func _on_notice_player_body_exited(body):
	if(body.is_in_group("player")):
		player_noticed = false


func teleport():
	var teleport_to:Node3D = teleport_spots.pick_random()
	var enemy_y = global_transform.origin.y
	
	global_transform.origin = teleport_to.global_transform.origin
	global_transform.origin.y = enemy_y
	
	set_rand_wander_pos()
	teleport_timer.start()
	
func _on_teleport_check_timeout():
	var index = rng.randi_range(0, 100)
	$"../Player/UserInterface/DebugPanel".add_property("teleport index ", index)
	if(index < TELEPORT_PERC && teleport_timer.is_stopped() && (player_view_state != "PURSUING" && player_view_state != "SEARCHING"  && player_view_state != "NOTICED")):
		teleport()
