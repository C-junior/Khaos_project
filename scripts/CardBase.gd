extends Button
class_name CardBase

signal died(card)
signal ability_activated(card)  # Renamed to avoid conflict
signal stats_changed(card)
signal status_effect_applied(card, effect_type)

# Core properties
var type # Changed from String to Variant to allow int assignment
var is_player: bool
var has_attacked: bool = false
var ability_used: bool = false  # This is now just a variable

# Stats - Using direct properties for compatibility
var health: int = 0
var max_health: int = 0
var attack: int = 0
var base_attack: int = 0  # Store original attack for temporary modifications

# Status effects
var status_effects = {
	"poison_turns": 0,
	"poison_damage": 1,
	"shield": 0,
	"is_frozen": false,
	"attack_delay": 0,
	"is_invisible": false,
	"attack_boost": 0,
	"shield_active": false,
	"special_ability": ""
}

# Spell tracking for mage
var spell_count: int = 0

# Artifacts - can equip up to max_artifacts
var artifacts: Array = []
var max_artifacts: int = 2
# var active_artifact_index: int = 0 # Could be used if player can switch active artifact

# UI References - Use proper node paths based on your scene structure
@onready var health_bar = $VBoxContainer/HealthBar
@onready var health_label = $VBoxContainer/HealthLabel
@onready var attack_label = $VBoxContainer/AttackLabel
# Assuming the buttons are now inside an HBoxContainer, which itself is in the VBoxContainer
@onready var ability_button_1 = $VBoxContainer/HBoxContainer/AbilityButton1
@onready var ability_button_2 = $VBoxContainer/HBoxContainer/AbilityButton2

func _ready() -> void:
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	connect_signals()
	update_appearance()
	setup_ui()  # Call setup_ui AFTER update_appearance so text is set
	base_attack = attack  # Store original attack value

func setup_ui() -> void:
	if not is_player:
		if ability_button_1: ability_button_1.hide()
		if ability_button_2: ability_button_2.hide()
	else:
		# Manage visibility based on equipped artifacts
		if ability_button_1:
			ability_button_1.visible = artifacts.size() >= 1
		if ability_button_2:
			ability_button_2.visible = artifacts.size() >= 2
			
	update_labels()

func connect_signals() -> void:
	mouse_entered.connect(_on_card_hover)
	mouse_exited.connect(_on_hover_exit)
	
	if ability_button_1:
		ability_button_1.pressed.connect(_on_ability_button_1_pressed)
	if ability_button_2:
		ability_button_2.pressed.connect(_on_ability_button_2_pressed)

func update_appearance() -> void:
	# This method is meant to be overridden by child classes like Card
	# Just set basic text for CardBase
	if not is_player:
		# If text is already set (e.g., from enemy type data), don't override it
		if text.is_empty():
			var type_str = str(type)
			text = type_str.capitalize()
	else:
		var type_str = str(type) 
		text = type_str.capitalize()

func take_damage(amount: int, attacker = null) -> void:
	# Check for invisibility
	if status_effects.is_invisible:
		print("%s is invisible and cannot be targeted!" % text)
		return
	
	# Apply shield
	if status_effects.shield > 0:
		var blocked = mini(status_effects.shield, amount)
		amount -= blocked
		status_effects.shield -= blocked
		print("%s's shield blocks %d damage!" % [text, blocked])
	
	# Apply shield_active (Iron Shield effect)
	if status_effects.shield_active:
		amount = max(0, amount - 2)
		status_effects.shield_active = false
		print("%s's iron shield reduces damage by 2!" % text)
	
	health -= amount
	health = max(0, health)
	stats_changed.emit(self)
	update_labels()
	
	if health <= 0:
		died.emit(self)
		# Queue the card for deletion after a short delay to allow death animations/effects
		await get_tree().create_timer(0.5).timeout
		queue_free()

func attack_target(target) -> void:
	if has_attacked or health <= 0:
		return
	
	var damage = attack + status_effects.attack_boost
	target.take_damage(damage, self)
	has_attacked = true
	
	# Reset temporary attack boost
	if status_effects.attack_boost > 0:
		status_effects.attack_boost = 0
		attack = base_attack

# New method to use a specific artifact by index
func use_specific_artifact(artifact_index: int, targets = null) -> void:
	if artifact_index >= 0 and artifact_index < artifacts.size():
		var artifact_to_use = artifacts[artifact_index]
		if artifact_to_use and artifact_to_use.can_use():
			artifact_to_use.use(self, targets if targets else [])
			ability_activated.emit(self) # Consider passing which artifact was activated (e.g., by index or name)
	else:
		printerr("%s: Attempted to use artifact at invalid index %d" % [text, artifact_index])

# Old use_ability can be removed or repurposed if there's a concept of a "default" ability
# For now, let's remove it to avoid confusion, as GameManager will call use_specific_artifact.
func use_ability(targets = null) -> void: # Reinstated for super call from Card.gd
	if not artifacts.is_empty() and artifacts[0]: # Check if first artifact exists
		if has_method("use_specific_artifact"): # Ensure the method exists
			use_specific_artifact(0, targets) # Default to using the first artifact
		else:
			printerr("CardBase: use_specific_artifact method not found, cannot default use_ability.")
	else:
		print("%s: use_ability called but no first artifact available." % text)


func apply_status_effect(effect: String, value) -> void:
	status_effects[effect] = value
	status_effect_applied.emit(self, effect)
	update_labels()

func apply_poison() -> void:
	if status_effects.poison_turns > 0:
		take_damage(status_effects.poison_damage)
		status_effects.poison_turns -= 1
		print("%s takes %d poison damage! (%d turns remaining)" % [text, status_effects.poison_damage, status_effects.poison_turns])

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	update_labels()
	print("%s heals for %d health!" % [text, amount])

func update_labels() -> void:
	if health_label:
		health_label.text = str(health) + "/" + str(max_health)
	if attack_label:
		var display_attack = attack + status_effects.attack_boost
		attack_label.text = str(display_attack)
	if health_bar:
		health_bar.value = float(health) / max_health * 100

func _on_card_hover() -> void:
	var tooltip = get_node("/root/Tooltip")
	if tooltip:
		tooltip.set_card_data(
			text,
			health,
			max_health,
			attack,
			Data.passive_abilities.get(type, {}) if Data else {},
			# Pass the whole array; Tooltip.gd will need to be adapted later
			# For now, to prevent errors, we can pass info for the first artifact if it exists
			artifacts[0].name if not artifacts.is_empty() and artifacts[0] else "",
			artifacts[0].current_cooldown if not artifacts.is_empty() and artifacts[0] else 0
			# Ideal pass-through for later Tooltip.gd update:
			# artifacts
		)

func _on_hover_exit() -> void:
	var tooltip = get_node("/root/Tooltip")
	if tooltip:
		tooltip.hide()

# Remove old single button handler:
# func _on_ability_button_pressed() -> void:
	# ...

func _on_ability_button_1_pressed() -> void:
	if artifacts.size() >= 1 and artifacts[0] and artifacts[0].can_use():
		var game_manager = get_node("/root/GameManager") # Path to GameManager
		if game_manager and game_manager.has_method("on_ability_pressed"):
			# GameManager's on_ability_pressed will need to accept an artifact_index
			game_manager.on_ability_pressed(self, 0) # 0 for the first artifact
	else:
		print("%s: Cannot use artifact 1 (not equipped or on cooldown)." % text)

func _on_ability_button_2_pressed() -> void:
	if artifacts.size() >= 2 and artifacts[1] and artifacts[1].can_use():
		var game_manager = get_node("/root/GameManager") # Path to GameManager
		if game_manager and game_manager.has_method("on_ability_pressed"):
			game_manager.on_ability_pressed(self, 1) # 1 for the second artifact
	else:
		print("%s: Cannot use artifact 2 (not equipped or on cooldown)." % text)
