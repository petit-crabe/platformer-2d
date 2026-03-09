extends CharacterBody2D

@export var move_speed: float = 100.0
@export var gravity: float = 1600.0

var _direction: int = 1

@onready var _ledge_ray: RayCast2D = $LedgeRay
@onready var _wall_ray: RayCast2D = $WallRay
@onready var _hit_area: Area2D = $HitArea

func _ready() -> void:
	add_to_group("enemies")
	_ledge_ray.target_position = Vector2(8.0 * _direction, 16.0)
	_wall_ray.target_position = Vector2(16.0 * _direction, 0.0)
	_hit_area.body_entered.connect(_on_hit_area_body_entered)
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	velocity.x = _direction * move_speed
	
	if is_on_floor() and not _ledge_ray.is_colliding():
		_flip_direction()
		
	if _wall_ray.is_colliding():
		_flip_direction()
	
	move_and_slide()
		
func _flip_direction() -> void:
	_direction *= -1
	_wall_ray.target_position.x = 16.0 * _direction
	_ledge_ray.target_position.x = 8.0 * _direction
	
func die() -> void:
	queue_free()

func _on_hit_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
		
	if body.last_velocity.y > 0.0:
		die()
		body.velocity.y = -380.0
	else:
		body.take_damage()
