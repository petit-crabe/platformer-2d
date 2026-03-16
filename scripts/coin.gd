extends Area2D

signal collected

@onready var _collect_sfx: AudioStreamPlayer = $CollectSFX

@export var point_value: int = 1
@export var spin_speed: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("collectibles")
	
func _process(delta: float) -> void:
	rotation += spin_speed * delta
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()
		
func _collect() -> void:
	collected.emit()
	$CollisionShape2D.set_deferred("disabled", true)
	_collect_sfx.play()
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()
