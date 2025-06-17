# res://Tooltip.gd
extends Panel

func _ready():
	modulate = Color(1, 1, 1, 0)  # Start invisible
	
	# Create stylish tooltip background
	var tooltip_bg = load("res://assets/frame-tooltip.png")
	var style = StyleBoxFlat.new()  # Change to StyleBoxFlat
	style.bg_color = Color(0.04, 0.04, 0.04, 0.84)  # Set a background color if needed
	
	add_theme_stylebox_override("panel", style)
	
	# Fade in animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

# For artifacts
func set_artifact_data(icon_path: String, name: String, effect: String, cooldown: int) -> void:
	$VBoxContainer/HBoxContainer/TextureRect.texture = load(icon_path)
	$VBoxContainer/HBoxContainer/LabelName.text = name
	$VBoxContainer/LabelEffect.text = "Effect: " + effect
	$VBoxContainer/LabelCooldown.text = "Cooldown: " + str(cooldown) + " turns"

# For player cards
func set_card_data(name: String, health: int, max_health: int, attack: int, passive: Dictionary, artifact_name: String, artifact_cooldown: int) -> void:
	$VBoxContainer/HBoxContainer/TextureRect.texture = null
	$VBoxContainer/HBoxContainer/LabelName.text = name
	$VBoxContainer/LabelEffect.text = "Health: " + str(health) + "/" + str(max_health) + " | Attack: " + str(attack)
	
	# Format passive text nicely - Safely access keys
	var passive_name = passive.get("name", "None")
	var passive_desc = passive.get("description", "No description")
	var passive_text = "Passive - %s:\n%s" % [passive_name, passive_desc]
	$VBoxContainer/LabelPassive.text = passive_text
	
	# Format artifact text
	var artifact_text = "Artifact: " + (artifact_name + " (CD: " + str(artifact_cooldown) + ")" if artifact_name else "None")
	$VBoxContainer/LabelCooldown.text = artifact_text
