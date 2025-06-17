extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Button.pressed.connect(Callable(self, "_on_back_menu"))

func _on_back_menu():
	# Ensure shop is hidden if it was opened and game is started

	get_tree().change_scene_to_file("res://MainMenu.tscn")
