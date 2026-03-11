extends CanvasLayer

@onready var _score_label: Label = $ScoreLabel
@onready var _lives_container: HBoxContainer = $LivesContainer

var _score: int = 0
var _lives: int = 3

func _ready() -> void:
	_refresh_display()
	
func add_points(points: int) -> void:
	_score += points
	_refresh_display()
	
func lose_life() -> void:
	_lives -= 1
	_refresh_display()
	if _lives <= 0:
		_trigger_game_over()
	
func _refresh_display() -> void:
	_score_label.text = "Score: %d" % _score
	for i in _lives_container.get_child_count():
		_lives_container.get_child(i).visible = i < _lives
		
func _trigger_game_over() -> void:
	get_tree().reload_current_scene()
