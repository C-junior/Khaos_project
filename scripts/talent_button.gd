extends TextureButton
class_name TalentNode

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D

var max_level = 5

func _ready() -> void:
	label.text = "0/" + str(max_level)
	if get_parent() is TalentNode:
		line_2d.add_point(global_position+ size/2)
		line_2d.add_point(get_parent().global_position + size/2)


var level: int =  0:
	set(value):
		level = value
		label.text = str(level)+ "/" + str(max_level)


func _on_pressed() -> void:
	level = min(level+1 , max_level)
	panel.show_behind_parent = true
	
	line_2d.default_color = Color(1, 1, 0.25)
	
	var talents = get_children()
	for talent in talents:
		if talent is TalentNode and  level == max_level:
			talent.disabled = false
