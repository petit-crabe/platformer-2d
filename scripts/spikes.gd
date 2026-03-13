extends StaticBody2D

@onready var _damage_area: Area2D = $DamageArea

func _ready() -> void:
	_damage_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
