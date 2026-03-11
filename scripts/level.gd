extends Node2D

@onready var _hud: CanvasLayer = $HUD
@onready var _spawn_point: Marker2D = $SpawnPoint

var _lives: int = 3
var _player: CharacterBody2D

func _ready() -> void:
	_spawn_player()
	
	for item in get_tree().get_nodes_in_group("collectibles"):
		if item.has_signal("collected"):
			item.collected.connect(_on_item_collected)
	
func _spawn_player() -> void:
	var player_scene := preload("res://scenes/player.tscn")
	
	_player = player_scene.instantiate()
	_player.position = _spawn_point.position
	_player.died.connect(_on_player_died)
	add_child(_player)
	
func _on_player_died() -> void:
	_lives -= 1
	_hud.lose_life()
	
	if _lives > 0:
		await get_tree().create_timer(1.2).timeout
		_spawn_player()
		
func _on_item_collected() -> void:
	_hud.add_points(10)
