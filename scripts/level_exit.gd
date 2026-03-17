extends Area2D

@export_file("*.tscn") var next_level: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_load_next_level()
		
func _load_next_level() -> void:
	set_deferred("monitoring", false)
	
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.z_index = 100
	get_tree().root.add_child(overlay)
	
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file(next_level)
	
	var tween_out := overlay.create_tween()
	tween_out.tween_property(overlay, "color:a", 0.0, 0.5)
	tween_out.tween_callback(overlay.queue_free)
