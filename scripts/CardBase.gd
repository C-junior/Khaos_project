extends Button
class_name CardBase

signal died(card)
signal ability_activated(card, slot) # Added slot
signal stats_changed(card)
signal status_effect_applied(card, effect_type, effect_data) # Added effect_data

# Core properties
var type # Changed from String to Variant to allow int assignment
var is_player: bool
var has_attacked: bool = false
# var ability_used: bool = false # This might need to be per artifact slot if they share a turn-use limit

# Stats
var health: int = 0
var max_health: int = 0
var attack: int = 0
var base_attack: int = 0

# Status effects - now stores dictionaries for effects with value/duration
var status_effects = {
	# Name: {value: X, duration: Y} OR Name: bool OR Name: int (for simple counters)
	"poison": {"damage": 0, "duration": 0}, # Value here is damage per turn
	"bleed": {"damage": 0, "duration": 0},
	"burn": {"damage": 0, "duration": 0},
	"shield_flat": {"amount": 0, "duration": 0}, # For flat damage absorption like Iron Shield
	"damage_reduction_shield_percent": {"value": 0.0, "duration": 0}, # For Stone Barrier like effects
	"defense_boost": {"value": 0.0, "duration": 0}, # Percentage
	"attack_boost_percent": {"value": 0.0, "duration": 0}, # Percentage
	"attack_boost_fixed": {"value": 0, "duration": 0}, # Flat value
	"attack_reduction_percent": {"value": 0.0, "duration": 0},
	"dodge_chance_boost": {"value": 0.0, "duration": 0},
	"heal_over_time_percent": {"value": 0.0, "duration": 0}, # Percent of max_health
	"freeze": {"duration": 0}, # Skips turn
	"stun": {"duration": 0},   # Skips turn
	"attack_delay": {"duration": 0}, # Cannot attack
	"is_invisible": {"duration": 0}, # Cannot be targeted by most single target
	"special_ability": "" # For enemy special abilities, might be refactored
}

var abilities_used_this_turn: Array = [false, false] # Tracks if artifact in slot 0 or 1 was used

# Spell tracking for mage
var spell_count: int = 0 # This might need to be reset per turn or battle

# Artifacts - Array to hold up to two artifacts
var equipped_artifacts: Array = [null, null]

# UI References - Assuming VBoxContainer structure from original
@onready var health_bar = $VBoxContainer/HealthBar
@onready var health_label = $VBoxContainer/HealthLabel
@onready var attack_label = $VBoxContainer/AttackLabel
# Assuming two ability buttons now, e.g., AbilityButton1 and AbilityButton2
# These paths will need to be created in your Card.tscn scene for player cards
@onready var ability_button_1 = $VBoxContainer/AbilityButton1
@onready var ability_button_2 = $VBoxContainer/AbilityButton2

func get_text_name() -> String: # Helper for logging
	return self.text if not self.text.is_empty() else "UnnamedCard"

func _ready() -> void:
	await get_tree().process_frame
	connect_signals()
	update_appearance() # Sets text based on type
	setup_ui()
	base_attack = attack


func setup_ui() -> void:
	if not is_player: # Enemies typically don't have player-clickable ability buttons
		if ability_button_1: ability_button_1.hide()
		if ability_button_2: ability_button_2.hide()
	else: # For player cards, visibility depends on if an artifact is equipped
		update_ability_button_visibility(0)
		update_ability_button_visibility(1)
	update_labels()

func update_ability_button_visibility(slot: int):
	var button = ability_button_1 if slot == 0 else ability_button_2
	if not is_instance_valid(button): return

	if is_player and get_artifact(slot) != null:
		button.show()
		button.disabled = not get_artifact(slot).can_use() or abilities_used_this_turn[slot] or has_attacked
		# TODO: Add visual indication for cooldown (e.g. text on button)
	elif is_instance_valid(button):
		button.hide()


func connect_signals() -> void:
	mouse_entered.connect(_on_card_hover)
	mouse_exited.connect(_on_hover_exit)
	if ability_button_1:
		ability_button_1.pressed.connect(Callable(self, "_on_ability_button_pressed").bind(0))
	if ability_button_2:
		ability_button_2.pressed.connect(Callable(self, "_on_ability_button_pressed").bind(1))


func update_appearance() -> void:
	if not is_player:
		if text.is_empty(): # Enemies might have their text set by GameManager from ENEMY_TYPES
			var type_str = str(type) # type might be an enum from Globals
			text = type_str.capitalize() if type is String else Globals.CardType.keys()[type].capitalize()
	else:
		var type_str = str(type)
		text = type_str.capitalize() if type is String else Globals.CardType.keys()[type].capitalize()


func get_current_attack() -> int:
	var current_atk = base_attack
	if status_effects.attack_boost_fixed.duration > 0:
		current_atk += status_effects.attack_boost_fixed.value
	if status_effects.attack_boost_percent.duration > 0:
		current_atk = int(current_atk * (1.0 + status_effects.attack_boost_percent.value))
	if status_effects.attack_reduction_percent.duration > 0:
		current_atk = int(current_atk * (1.0 - status_effects.attack_reduction_percent.value))
	return max(0, current_atk)


# Returns actual damage taken after reductions/shields, or 0 if dodged/invisible
func take_damage(amount: int, attacker = null, is_lifesteal_source: bool = false) -> int:
	if status_effects.is_invisible.duration > 0 and not is_lifesteal_source: # Lifesteal might ignore invisibility
		print("%s is invisible and avoids the attack!" % get_text_name())
		return 0

	if status_effects.dodge_chance_boost.duration > 0 and randf() < status_effects.dodge_chance_boost.value:
		print("%s dodges the attack!" % get_text_name())
		# TODO: Add visual feedback for dodge
		return 0

	var modified_amount = float(amount)
	if status_effects.defense_boost.duration > 0:
		modified_amount *= (1.0 - status_effects.defense_boost.value)
	if status_effects.damage_reduction_shield_percent.duration > 0:
		modified_amount *= (1.0 - status_effects.damage_reduction_shield_percent.value)
	
	modified_amount = int(max(0, modified_amount)) # Ensure damage is not negative

	if status_effects.shield_flat.duration > 0 and status_effects.shield_flat.amount > 0:
		var blocked = min(status_effects.shield_flat.amount, modified_amount)
		modified_amount -= blocked
		status_effects.shield_flat.amount -= blocked
		print("%s's flat shield blocks %d damage! (%d remaining)" % [get_text_name(), blocked, status_effects.shield_flat.amount])
		if status_effects.shield_flat.amount <= 0:
			status_effects.shield_flat.duration = 0 # Shield depleted
	
	var actual_damage_taken = int(max(0, modified_amount))
	health -= actual_damage_taken
	health = max(0, health)

	print("%s takes %d damage." % [get_text_name(), actual_damage_taken])
	stats_changed.emit(self)
	update_labels()
	
	if health <= 0:
		died.emit(self)
		await get_tree().create_timer(0.1).timeout # Short delay for effects before freeing
		queue_free()

	return actual_damage_taken


func attack_target(target_card: CardBase) -> void:
	if has_attacked or health <= 0 or (status_effects.attack_delay.duration > 0) :
		print("%s cannot attack (already attacked, no health, or delayed)." % get_text_name())
		return

	var damage_to_deal = get_current_attack()
	print("%s attacks %s for %d base damage." % [get_text_name(), target_card.get_text_name(), damage_to_deal])
	target_card.take_damage(damage_to_deal, self)
	has_attacked = true # Standard attack consumes the turn's attack action

	# After attacking, check if any equipped artifacts should also prevent ability use
	# This depends on game rules: does normal attack also prevent artifact use same turn?
	# For now, let's say yes to simplify.
	abilities_used_this_turn = [true, true] # Consumes artifact uses too
	update_all_ability_button_states()


func use_ability(slot: int, targets: Array = []) -> void:
	var artifact_to_use = get_artifact(slot)
	if artifact_to_use and artifact_to_use.can_use() and not has_attacked and not abilities_used_this_turn[slot]:
		print("%s uses artifact in slot %d: %s" % [get_text_name(), slot, artifact_to_use.id])
		artifact_to_use.use(self, targets)
		abilities_used_this_turn[slot] = true
		has_attacked = true # Using an artifact counts as the main action for the turn
		ability_activated.emit(self, slot)
		update_all_ability_button_states()
	else:
		var reason = "cannot use ability: "
		if not artifact_to_use: reason += "no artifact. "
		if artifact_to_use and not artifact_to_use.can_use(): reason += "artifact on cooldown. "
		if has_attacked: reason += "already attacked. "
		if artifact_to_use and abilities_used_this_turn[slot]: reason += "artifact slot already used."
		print("%s %s" % [get_text_name(), reason])

# data is typically {"value": X, "duration": Y}
func apply_status_effect(effect_name: String, data: Dictionary) -> void:
	if not status_effects.has(effect_name):
		printerr("CardBase: Status effect '%s' not defined in status_effects dictionary." % effect_name)
		return

	# For effects that stack duration or value, specific logic would be needed here.
	# Default is to overwrite.
	status_effects[effect_name] = data
	
	# Special handling for immediate effects or setup
	if effect_name == "shield_flat": # Ensure 'amount' is used for shield value
		status_effects.shield_flat.amount = data.get("value", 0) # Value from effect def becomes amount for shield
	
	print("%s gets status '%s': Value %s, Duration %d" % [get_text_name(), effect_name, str(data.get("value")), data.get("duration")])
	status_effect_applied.emit(self, effect_name, data)
	update_labels() # Might need more specific UI updates for statuses

func remove_debuffs(count: int):
	var debuffs_removed = 0
	# Define what counts as a debuff
	var debuff_names = ["poison", "bleed", "burn", "attack_reduction_percent", "freeze", "stun", "attack_delay"]
	for name in debuff_names:
		if status_effects.has(name) and status_effects[name].get("duration", 0) > 0:
			status_effects[name].duration = 0 # Effectively remove by setting duration to 0
			# For boolean statuses like is_frozen, you'd set them to false.
			# This simple way clears duration. More complex statuses might need specific reset values.
			print("%s had debuff '%s' removed." % [get_text_name(), name])
			debuffs_removed += 1
			if debuffs_removed >= count:
				break
	if debuffs_removed > 0:
		update_labels() # Or specific status UI update


func process_turn_start_effects(): # New function for start-of-turn processing
	# Placeholder for effects that trigger at turn start
	pass

func process_turn_end_effects(): # Renamed from apply_poison, expanded
	if status_effects.poison.duration > 0 and status_effects.poison.damage > 0:
		var p_dmg = status_effects.poison.damage
		print("%s takes %d poison damage." % [get_text_name(), p_dmg])
		take_damage(p_dmg, self, true) # True indicates it's status damage (e.g. bypasses invis)
		status_effects.poison.duration -= 1

	if status_effects.bleed.duration > 0 and status_effects.bleed.damage > 0:
		var b_dmg = status_effects.bleed.damage
		print("%s takes %d bleed damage." % [get_text_name(), b_dmg])
		take_damage(b_dmg, self, true)
		status_effects.bleed.duration -= 1

	if status_effects.burn.duration > 0 and status_effects.burn.damage > 0:
		var brn_dmg = status_effects.burn.damage
		print("%s takes %d burn damage." % [get_text_name(), brn_dmg])
		take_damage(brn_dmg, self, true)
		status_effects.burn.duration -= 1

	if status_effects.heal_over_time_percent.duration > 0 and status_effects.heal_over_time_percent.value > 0:
		var heal_val = int(max_health * status_effects.heal_over_time_percent.value)
		heal(heal_val)
		print("%s heals %d from HoT." % [get_text_name(), heal_val])
		status_effects.heal_over_time_percent.duration -= 1

	# Decrement duration for other timed effects
	var timed_effects = ["shield_flat", "damage_reduction_shield_percent", "defense_boost",
						 "attack_boost_percent", "attack_boost_fixed", "attack_reduction_percent",
						 "dodge_chance_boost", "is_invisible", "freeze", "stun", "attack_delay"]
	for effect_name in timed_effects:
		if status_effects[effect_name].has("duration") and status_effects[effect_name].duration > 0:
			status_effects[effect_name].duration -= 1
			if status_effects[effect_name].duration == 0:
				print("%s's status '%s' expired." % [get_text_name(), effect_name])
				# Reset value if necessary, e.g. for percentage boosts, or rely on getters to ignore if duration is 0
				if effect_name in ["attack_boost_fixed", "attack_boost_percent", "defense_boost"]: # Example reset
					status_effects[effect_name].value = 0.0 if "percent" in effect_name else 0


	# Artifact cooldowns
	for i in range(equipped_artifacts.size()):
		if get_artifact(i) != null:
			get_artifact(i).turn_end()

	update_all_ability_button_states()
	update_labels()


func reset_turn_actions():
	has_attacked = false
	abilities_used_this_turn = [false, false]
	# spell_count = 0 # Reset mage spell count? Depends on design (per turn or per battle)
	update_all_ability_button_states()


func heal(amount: int) -> void:
	if amount <= 0: return
	health = min(max_health, health + amount)
	update_labels()
	print("%s heals for %d health! Now %d/%d" % [get_text_name(), amount, health, max_health])


func update_labels() -> void:
	if health_label: health_label.text = str(health) + "/" + str(max_health)
	if attack_label: attack_label.text = str(get_current_attack()) # Use getter for dynamic attack
	if health_bar: health_bar.value = float(health) / max_health * 100 if max_health > 0 else 0
	# TODO: Add UI updates for status effects icons


func _on_card_hover() -> void:
	var tooltip_node = get_node_or_null("/root/Tooltip") # Assuming Tooltip is a scene at this path
	if tooltip_node:
		var passive_desc = ""
		# Assuming Globals.passive_abilities is populated: CardType_Enum -> {name: "", description: ""}
		if Engine.has_singleton("Globals") and Globals.has("passive_abilities"):
			if Globals.passive_abilities.has(type): # type is enum value
				passive_desc = Globals.passive_abilities[type].get("name", "") + ": " + Globals.passive_abilities[type].get("description", "")

		var artifact_texts = []
		for i in range(equipped_artifacts.size()):
			var art = get_artifact(i)
			if art:
				artifact_texts.append("%s (L%d, CD:%d)" % [art.id, art.level, art.current_cooldown])
			else:
				artifact_texts.append("Slot %d: Empty" % (i+1))

		# Tooltip.gd set_card_data will need to be updated to accept this new structure
		tooltip_node.set_card_data(
			get_text_name(), health, max_health, get_current_attack(),
			passive_desc, # Pass the description string
			artifact_texts, # Pass array of artifact texts
			status_effects # Pass current status effects dict for detailed display
		)
		tooltip_node.show()


func _on_hover_exit() -> void:
	var tooltip_node = get_node_or_null("/root/Tooltip")
	if tooltip_node:
		tooltip_node.hide()


func _on_ability_button_pressed(slot: int) -> void: # slot is bound from connect_signals
	var artifact_to_use = get_artifact(slot)
	if artifact_to_use and artifact_to_use.can_use() and not abilities_used_this_turn[slot] and not has_attacked:
		var game_manager = get_node_or_null("/root/GameManager") # Standard path for GameManager
		if game_manager and game_manager.has_method("on_ability_button_pressed_for_card_slot"):
			# GameManager will handle targeting if required, then call card.use_ability(slot, targets)
			game_manager.on_ability_button_pressed_for_card_slot(self, slot)
	else:
		print("Cannot use ability for slot %d on %s - (On Cooldown / Already Acted)" % [slot, get_text_name()])
	update_ability_button_visibility(slot) # Update button state after press attempt


func update_all_ability_button_states():
	if is_player:
		update_ability_button_visibility(0)
		update_ability_button_visibility(1)

# --- Artifact Management ---
func equip_artifact(artifact_instance: Artifact, slot: int) -> bool:
	if slot < 0 or slot >= equipped_artifacts.size():
		printerr("CardBase: Invalid artifact slot %d for %s" % [slot, get_text_name()])
		return false
	if not artifact_instance is Artifact:
		printerr("CardBase: Attempted to equip invalid object to artifact slot %d for %s. Expected Artifact." % [slot, get_text_name()])
		return false

	# Optional: unequip existing artifact in slot if any, return it to inventory
	# if equipped_artifacts[slot] != null:
	#    InventoryManager.return_artifact(equipped_artifacts[slot])

	equipped_artifacts[slot] = artifact_instance
	print("CardBase: Equipped %s (Lvl %d) to slot %d for %s" % [artifact_instance.id, artifact_instance.level, slot, get_text_name()])
	if is_inside_tree() and is_player: update_ability_button_visibility(slot) # Update button if UI is ready
	return true

func unequip_artifact(slot: int) -> Artifact:
	if slot < 0 or slot >= equipped_artifacts.size():
		printerr("CardBase: Invalid slot %d for unequip on %s." % [slot, get_text_name()])
		return null

	var artifact_to_remove = equipped_artifacts[slot]
	equipped_artifacts[slot] = null
	if artifact_to_remove != null:
		print("CardBase: Unequipped %s from slot %d for %s" % [artifact_to_remove.id, slot, get_text_name()])
	if is_inside_tree() and is_player: update_ability_button_visibility(slot)
	return artifact_to_remove

func get_artifact(slot: int) -> Artifact:
	if slot < 0 or slot >= equipped_artifacts.size():
		return null
	return equipped_artifacts[slot]

func get_artifacts_for_save() -> Array:
	var artifacts_data = []
	for art_instance in equipped_artifacts:
		if art_instance != null and art_instance is Artifact:
			artifacts_data.append(art_instance.get_data_for_save())
		else:
			artifacts_data.append(null) # Keep null for empty slots
	return artifacts_data

func load_artifacts_from_save(artifacts_save_data: Array):
	if not artifacts_save_data is Array or artifacts_save_data.size() != 2:
		printerr("CardBase load_artifacts_from_save: Invalid data format.")
		return

	for i in range(artifacts_save_data.size()):
		var art_data = artifacts_save_data[i]
		if art_data != null and art_data is Dictionary:
			var loaded_artifact = Artifact.new_from_save_data(art_data)
			if loaded_artifact:
				equip_artifact(loaded_artifact, i)
		else:
			equipped_artifacts[i] = null # Ensure slot is empty if save data was null

	if is_inside_tree() and is_player:
		update_all_ability_button_states()
