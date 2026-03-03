extends CharacterBody2D

# ─────────────────────────────────────────────
#  Movement constants
#  @export means they appear in the Inspector —
#  no need to touch the code to tweak the feel!
# ─────────────────────────────────────────────
@export_group("Movement")
@export var walk_speed: float = 250.0
@export var run_speed: float = 400.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

@export_group("Jump")
@export var jump_force: float = -600.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 1000.0
@export var coyote_time: float = 0.15
@export var jump_buffer: float = 0.10

@export_group("Roll")
@export var roll_speed: float = 800.0
@export var roll_duration: float = 0.20
@export var roll_cooldown: float = 1.00

# ─────────────────────────────────────────────
#  Internal state
# ─────────────────────────────────────────────
var _can_roll: bool = true
var _is_rolling: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0

# ─────────────────────────────────────────────
#  Node references
# ─────────────────────────────────────────────
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

signal died

# ─────────────────────────────────────────────
#  Lifecycle
# ─────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	
func _physics_process(delta: float) -> void:
	if _is_rolling:
		return
	
	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_movement(delta)
	_handle_roll()
	_update_animation()
	move_and_slide()

# ─────────────────────────────────────────────
#  Gravity & coyote time
# ─────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		_coyote_timer -= delta
	else:
		_coyote_timer = coyote_time
		_can_roll = true

# ─────────────────────────────────────────────
#  Jump — with coyote time + input buffer
# ─────────────────────────────────────────────
func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer
	
	_jump_buffer -= delta
	
	if _jump_buffer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_force
		_jump_buffer = 0.0
		_coyote_timer = 0.0
	
	# Variable height: releasing early = smaller jump
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

# ─────────────────────────────────────────────
#  Horizontal movement
# ─────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := run_speed if Input.is_action_pressed("roll") else walk_speed
	
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

# ─────────────────────────────────────────────
#  Roll
# ─────────────────────────────────────────────
func _handle_roll() -> void:
	if Input.is_action_just_pressed("roll") and _can_roll and not is_on_floor():
		_perform_roll()
	
func _perform_roll() -> void:
	_is_rolling = true
	_can_roll = false
	
	var roll_dir := -1.0 if _sprite.flip_h else 1.0
	velocity = Vector2(roll_dir * roll_speed, 0.0)
	modulate.a = 0.5
	
	await get_tree().create_timer(roll_duration).timeout
	_is_rolling = false
	modulate.a = 1.0
	
	await get_tree().create_timer(roll_cooldown).timeout
	_can_roll = true

# ─────────────────────────────────────────────
#  Animation state machine
#  Priority: dash > air > ground
# ─────────────────────────────────────────────
func _update_animation() -> void:
	if _is_rolling:
		_sprite.play("roll")
		return
		
	if not is_on_floor():
		_sprite.play("idle")
	else:
		if absf(velocity.x) > 10.0:
			_sprite.play("run")
			_sprite.speed_scale = absf(velocity.x) / walk_speed
		else:
			_sprite.play("idle")
			_sprite.speed_scale = 1.0
	
# ─────────────────────────────────────────────
#  Damage & death
# ─────────────────────────────────────────────
func take_damage(_amount: int = 1) -> void:
	die()
	
func die() -> void:
	died.emit()
	set_physics_process(false)
	queue_free()
	
# ─────────────────────────────────────────────
#  Screen shake utility
# ─────────────────────────────────────────────
func _camera_shake(intensity: float = 5.0, duration: float = 0.2) -> void:
	var camera: Camera2D = $Camera2D
	var tween := create_tween()
	for i in 8:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, duration / 8.0)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
