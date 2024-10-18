extends Node3D
@onready var player = $Player
@onready var map: RID = NavigationServer3D.map_create()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#NavigationServer3D.map_set_up(map, Vector3.UP)
	#NavigationServer3D.map_set_active(map, true)
	#
	#NavigationServer3D.region_set_transform($NavigationRegion3D, Transform3D())
	#NavigationServer3D.region_set_map($NavigationRegion3D, map)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	get_tree().call_group("enemy", "update_target_loc", player.global_transform.origin)
