extends CharacterBody2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ─────────────────────────────────────────────
#  Movement constants
#  @export means they appear in the Inspector —
#  no need to touch the code to tweak the feel!
# ─────────────────────────────────────────────
@export_group("Movement")
@export var walk_speed: float = 250.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

@export_group("Jump")
@export var jump_force: float = -600.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 1000.0
@export var coyote_time: float = 0.15
@export var jump_buffer: float = 0.10

@export_group("Roll")
@export var roll_speed: float = 500.0
@export var roll_duration: float = 0.4

# ─────────────────────────────────────────────
#  Internal state
# ─────────────────────────────────────────────
var _is_rolling: bool = false
var _is_invicible: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _current_animation: String = ""

# ─────────────────────────────────────────────
#  Lifecycle
# ─────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	
func _physics_process(delta: float) -> void:
	if _is_rolling:
		move_and_slide()
		return
	
	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_movement(delta)
	_handle_roll()
	move_and_slide()
	_update_animation()

# ─────────────────────────────────────────────
#  Gravity & coyote time
# ─────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		_coyote_timer -= delta
	else:
		_coyote_timer = coyote_time

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
	
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * walk_speed, acceleration * delta)
		_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

# ─────────────────────────────────────────────
#  RollRoll — ground only, interrupts current action,
#  grants invincibility for its duration
# ─────────────────────────────────────────────
func _handle_roll() -> void:
	if Input.is_action_just_pressed("roll") and is_on_floor() and not _is_rolling:
		_perform_roll()
	
func _perform_roll() -> void:
	_is_rolling = true
	_is_invicible = true
	_play_animation("roll")
	
	var roll_dir := signf(velocity.x) if velocity.x != 0.0 else (-1.0 if _sprite.flip_h else 1.0)
	velocity = Vector2(roll_dir * roll_speed, 0.0)
	
	await get_tree().create_timer(roll_duration).timeout
	
	_is_rolling = false
	_is_invicible = false
	
# ─────────────────────────────────────────────
#  Animation
# ─────────────────────────────────────────────
func _update_animation() -> void:
	if _is_rolling:
		return
	
	if is_on_floor():
		if absf(velocity.x) > 10.0:
			_play_animation("run")
			_sprite.speed_scale = absf(velocity.x) / walk_speed
		else:
			_sprite.speed_scale = 1.0
			_play_animation("idle")
	else:
		_current_animation = ""
		_sprite.stop()

func _play_animation(animation: String) -> void:
	if _current_animation == animation:
		return
	_current_animation = animation
	_sprite.play(animation)
