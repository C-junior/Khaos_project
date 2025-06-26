# Card.gd
class_name Card
extends CardBase

# Remove duplicate properties that are already in CardBase
# Keep only Card-specific properties that aren't in CardBase

var passive_data: Dictionary = {
	"PALADIN": { "name": "Divine Intervention", "description": "Redirects 1/3 of ally damage to self" },
	"MAGE": { "name": "Arcane Echo", "description": "Every 3rd spell is doubled" },
	"KNIGHT": { "name": "Bloodlust", "description": "Bonus 5 attack points after killing enemy" },
	"ARCHER": { "name": "Hunter's Mark", "description": "+15% damage per consecutive hit (max 45%)" },
	"CLERIC": { "name": "Divine Aura", "description": "Heal allies below 25% HP" },
	"ASSASSIN": { "name": "Shadow Strike", "description": "+50% damage if target at full HP" }, # ROGUE renamed to ASSASSIN
	"BERSERKER": { "name": "Blood Frenzy", "description": "+20% attack per 25% HP lost" },
	"NECRODANCER": { "name": "Soul Harvest", "description": "Reduce cooldowns when enemies die" },
	"GUARDIAN": { "name": "Fortress Stance", "description": "25% less damage above 50% HP, 25% weaker attacks" },
	"ENEMY": { "name": "None", "description": "No passive ability" },
	"BOSS": { "name": "None", "description": "No passive ability" }
}

const ENEMY_TYPES = {
	"ENEMY": {"name": "Goblin", "sprite": "res://enemies.jpg"},
	"BOSS": {"name": "Orc Warlord", "sprite": "res://boss_orc_warlord.png"}
}

var current_tooltip = null

func _ready():
	super._ready()  # Call parent's _ready first
	
	# Additional Card-specific setup
	var card_texture = $VBoxContainer/ArtifactIcon
	if card_texture:
		card_texture.custom_minimum_size = Vector2(24, 24)
		card_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Debug print to verify card type
	print("Card created - Type: %s, Is Player: %s" % [type, is_player])
	
	if is_player:
		if has_node("VBoxContainer/AbilityButton"):
			$VBoxContainer/AbilityButton.show()
		if has_node("VBoxContainer/ArtifactIcon"):
			$VBoxContainer/ArtifactIcon.show()
	else:
		if has_node("VBoxContainer/AbilityButton"):
			$VBoxContainer/AbilityButton.hide()
		if has_node("VBoxContainer/ArtifactIcon"):
			$VBoxContainer/ArtifactIcon.hide()

# Override the parent's update_appearance to handle both player and enemy cards
func update_appearance():
	# type is now expected to be an integer (Globals.CardType enum value) for player cards
	print("Card.gd: Updating appearance for card.type: %s (is_player: %s)" % [type, is_player]) 

	if is_player:
		var character_name = ""
		var texture_path = ""

		match type: # type is an integer enum Globals.CardType
			Globals.CardType.PALADIN:
				character_name = "Paladin"
				texture_path = "res://paladin.webp"
			Globals.CardType.MAGE:
				character_name = "Mage"
				texture_path = "res://mage.jpg"
			Globals.CardType.KNIGHT:
				character_name = "Warrior" # Display name for Knight type
				texture_path = "res://knight.webp"
			Globals.CardType.ARCHER:
				character_name = "Archer"
				texture_path = "res://archer.webp"
			Globals.CardType.CLERIC:
				character_name = "Cleric"
				texture_path = "res://cleric.png"
			Globals.CardType.ASSASSIN: # Was ROGUE
				character_name = "Assassin"
				texture_path = "res://rogue.png" # Placeholder art
				print("Card.gd: Using Rogue art as placeholder for Assassin")
			Globals.CardType.BERSERKER:
				character_name = "Berserker"
				texture_path = "res://knight.webp" # Placeholder art
				print("Card.gd: Using Knight art as placeholder for Berserker")
			Globals.CardType.NECRODANCER:
				character_name = "Necrodancer"
				texture_path = "res://mage.jpg" # Placeholder art
				print("Card.gd: Using Mage art as placeholder for Necrodancer")
			Globals.CardType.GUARDIAN:
				character_name = "Guardian"
				texture_path = "res://paladin.webp" # Placeholder art
				print("Card.gd: Using Paladin art as placeholder for Guardian")
			_:
				character_name = "Unknown Hero (%s)" % str(type)
				texture_path = "" # No art for unknown
				print("Card.gd: Unknown player card type for appearance: %s" % type)

		self.text = character_name # Set Button's text
		if has_node("VBoxContainer/NameLabel"):
			get_node("VBoxContainer/NameLabel").text = character_name
		
		if texture_path != "" and has_node("ArtTexture"):
			if ResourceLoader.exists(texture_path):
				get_node("ArtTexture").texture = load(texture_path)
			else:
				print("Card.gd: Texture not found for %s at %s" % [character_name, texture_path])
		elif has_node("ArtTexture"):
			get_node("ArtTexture").texture = null # Clear texture if no path
		
	else: # Enemy card
		# Enemy text (name) is set by GameManager.
		# Enemy texture is set by GameManager via set_image(path).
		# This part can remain largely as is, but ensure NameLabel is updated if text was set directly.
		if has_node("VBoxContainer/NameLabel") and not self.text.is_empty(): # self.text is Button's text
			get_node("VBoxContainer/NameLabel").text = self.text
		print("Card.gd: Processing enemy card appearance - text: %s" % self.text)
		#if has_node("VBoxContainer/NameLabel"):
		# $VBoxContainer/NameLabel.text = text # This line was redundant with the one above if text is already set.

# Add a method to set the enemy image from a path
func set_image(image_path: String) -> void:
	if has_node("ArtTexture"):
		if ResourceLoader.exists(image_path):
			$ArtTexture.texture = load(image_path)
			print("Loaded enemy image: %s" % image_path)
		else:
			print("Warning: Enemy image not found at path: %s" % image_path)

# Override take_damage to add Paladin passive
func take_damage(amount: int, attacker = null) -> void:
	if status_effects.is_invisible:
		status_effects.is_invisible = false
		print("%s was invisible and avoided the attack!" % text)
		return
	
	var actual_damage = amount
	
	# Apply shield effects first
	if status_effects.shield > 0:
		var blocked = min(status_effects.shield, actual_damage)
		actual_damage -= blocked
		status_effects.shield -= blocked
		print("%s's shield blocks %d damage!" % [text, blocked])
	
	if status_effects.shield_active:
		actual_damage = max(0, actual_damage - 2)
		status_effects.shield_active = false
		print("%s's iron shield reduces damage by 2!" % text)
	
	# Paladin's Divine Intervention passive
	if is_player and type != Globals.CardType.PALADIN and get_parent(): # Use enum
		# The print might still show the integer type, which is fine for debugging.
		# To show string type in print: print("Checking for Paladin passive. Current card: %s (type: %s)" % [text, _get_type_as_string_for_passive(type)])
		print("Checking for Paladin passive. Current card: %s (type enum value: %s)" % [text, type]) 
		var paladin = null
		for p_card in get_parent().get_children(): # Renamed loop var to avoid conflict if 'card' is a class var elsewhere
			if p_card != self and p_card.is_player and p_card.type == Globals.CardType.PALADIN and p_card.health > 0: # Use enum
				paladin = p_card
				print("Found Paladin: %s with %d health" % [p_card.text, p_card.health]) # Use p_card
				break
		if paladin:
			var redirect_amount = int(actual_damage * 0.33)  # 1/3 of damage
			if redirect_amount > 0:
				actual_damage -= redirect_amount
				paladin.health -= redirect_amount
				paladin.update_labels()
				print("%s redirects %d damage from %s (Paladin takes %d damage)" % [paladin.text, redirect_amount, text, redirect_amount])
				# Visual feedback for Paladin
				paladin.modulate = Color.YELLOW
				await get_tree().create_timer(0.2).timeout
				paladin.modulate = Color.WHITE
	
	health -= actual_damage
	health = max(0, health)
	print("%s takes %d damage (health: %d)" % [text, actual_damage, health])
	
	if health <= 0:
		died.emit(self)
		if not is_player and attacker and attacker.type == Globals.CardType.KNIGHT: # Changed "KNIGHT" to Globals.CardType.KNIGHT
			attacker.attack += 1
			attacker.update_labels()
			print("%s's attack increases to %d (Bloodlust)" % [attacker.text, attacker.attack])
		# Queue the card for deletion after a short delay
		await get_tree().create_timer(0.5).timeout
		queue_free()
	else:
		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE
		update_labels()

# Override update_labels to handle Card-specific UI
func update_labels() -> void:
	super.update_labels()  # Call parent's update_labels first
	
	# Card-specific label updates
	if has_node("VBoxContainer/HealthLabel"):
		$VBoxContainer/HealthLabel.text = "Health: " + str(health)
	if has_node("VBoxContainer/AttackLabel"):
		$VBoxContainer/AttackLabel.text = "Attack: " + str(attack)
	if has_node("VBoxContainer/HealthBar"):
		$VBoxContainer/HealthBar.value = health
		$VBoxContainer/HealthBar.max_value = max_health
	
	# Note: ability_button_1 and ability_button_2 are inherited from CardBase
	# Their general visibility (if player) is handled by CardBase.setup_ui()
	# Here, we primarily set text and specific icons if they exist within Card.tscn's structure.

	var icon1_node_path = "VBoxContainer/HBoxContainer/ArtifactIcon1" # Assumed path for icon of artifact 1
	var icon2_node_path = "VBoxContainer/HBoxContainer/ArtifactIcon2" # Assumed path for icon of artifact 2

	if is_player:
		if ability_button_1: # Check if inherited button is valid
			if artifacts.size() >= 1 and artifacts[0]:
				var art_0 = artifacts[0]
				ability_button_1.text = "Use %s%s" % [art_0.name, " (CD: %d)" % art_0.current_cooldown if art_0.current_cooldown > 0 else ""]
				if has_node(icon1_node_path):
					get_node(icon1_node_path).texture = load(get_artifact_icon_path(art_0.name))
				# ability_button_1.visible = true # Visibility handled by CardBase.setup_ui
			#else:
				#ability_button_1.text = "Ability 1" # Default text or hide
				#if has_node(icon1_node_path):
					#get_node(icon1_node_path).texture = null
				# ability_button_1.visible = false # Visibility handled by CardBase.setup_ui
		
		if ability_button_2: # Check if inherited button is valid
			if artifacts.size() >= 2 and artifacts[1]:
				var art_1 = artifacts[1]
				ability_button_2.text = "Use %s%s" % [art_1.name, " (CD: %d)" % art_1.current_cooldown if art_1.current_cooldown > 0 else ""]
				if has_node(icon2_node_path):
					get_node(icon2_node_path).texture = load(get_artifact_icon_path(art_1.name))
				# ability_button_2.visible = true # Visibility handled by CardBase.setup_ui
			#else:
				#ability_button_2.text = "Ability 2" # Default text or hide
				#if has_node(icon2_node_path):
					#get_node(icon2_node_path).texture = null
				# ability_button_2.visible = false # Visibility handled by CardBase.setup_ui
	
	# Hide old single ArtifactIcon if it exists and is not one of the new ones
	if has_node("VBoxContainer/ArtifactIcon"):
		var old_icon = get_node("VBoxContainer/ArtifactIcon")
		if old_icon.get_path() != get_path_to(get_node_or_null(icon1_node_path)) and \
		   old_icon.get_path() != get_path_to(get_node_or_null(icon2_node_path)):
			old_icon.hide()


# Override hover functions
func _on_card_hover():
	if current_tooltip:
		current_tooltip.queue_free()
	current_tooltip = load("res://Tooltip.tscn").instantiate()
	current_tooltip.set_card_data(
		text, # Button's text, should be character_name for players
		health,
		max_health,
		attack,
		passive_data.get(_get_type_as_string_for_passive(type), {}), # Use helper for lookup
		# Pass the artifacts array. Tooltip.gd needs to be updated to handle this.
		# For now, to prevent crash and show something, pass info for the first artifact.
		artifacts[0].name if not artifacts.is_empty() and artifacts[0] else "",
		artifacts[0].current_cooldown if not artifacts.is_empty() and artifacts[0] else 0
		# The ideal call for a future Tooltip.gd update would be just: self.artifacts
	)
	get_tree().root.add_child(current_tooltip)
	current_tooltip.global_position = get_global_mouse_position() + Vector2(10, 10)

func _on_hover_exit():
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null

func get_artifact_icon_path(artifact_name: String) -> String:
	return "res://artifacts/" + artifact_name.to_lower().replace(" ", "_") + ".png"

# Helper function to convert integer type to string for passive_data lookup
func _get_type_as_string_for_passive(p_type: int) -> String:
	match p_type:
		Globals.CardType.PALADIN: return "PALADIN"
		Globals.CardType.MAGE: return "MAGE"
		Globals.CardType.KNIGHT: return "KNIGHT" # String key for passive_data
		Globals.CardType.ARCHER: return "ARCHER"
		Globals.CardType.CLERIC: return "CLERIC"
		Globals.CardType.ASSASSIN: return "ASSASSIN" # Was ROGUE
		Globals.CardType.BERSERKER: return "BERSERKER"
		Globals.CardType.NECRODANCER: return "NECRODANCER"
		Globals.CardType.GUARDIAN: return "GUARDIAN"
		Globals.CardType.ENEMY: return "ENEMY" 
		Globals.CardType.BOSS: return "BOSS"   
		_: 
			print("Card.gd: Unknown type enum value %s in _get_type_as_string_for_passive" % p_type)
			return "UNKNOWN" # Fallback key

func get_type_name() -> String: # This function might need adjustment if self.type is now consistently an int
	if type is String:
		return type.capitalize()
	elif type is int: # Globals.CardType
		return _get_type_as_string_for_passive(type).capitalize()
	return "UnknownType"


# Legacy methods for backward compatibility - Corrected to call super
func attack_target(target):
	print("DEBUG: %s attacking %s" % [text, target.text])
	print("DEBUG: Attacker stats - Health: %d, Attack: %d" % [health, attack])
	print("DEBUG: Target stats before - Health: %d, Max Health: %d" % [target.health, target.max_health])
	
	# Check if we can attack
	if health <= 0:
		print("DEBUG: Cannot attack - attacker is dead")
		return
	
	if target.health <= 0:
		print("DEBUG: Cannot attack - target is already dead")
		return
	
	# Apply the attack
	print("DEBUG: Calling take_damage with %d damage" % attack)
	target.take_damage(attack, self)
	
	print("DEBUG: Target stats after - Health: %d" % target.health)
#func attack_target(target):
	#super.attack_target(target)

func use_ability(targets = null): # This is Card.gd's override
	# If Card.gd's use_ability is meant to trigger the first artifact by default when called.
	if self.has_method("use_specific_artifact"): # Check if CardBase has the method
		if not artifacts.is_empty() and artifacts[0]:
			# Directly call CardBase's specific method, or let CardBase.use_ability handle it
			super.use_specific_artifact(0, targets) 
		else:
			print("%s tried to use ability (via Card.gd override) but has no first artifact." % text)
	else:
		printerr("CardBase missing use_specific_artifact; Card.gd's use_ability override cannot function.")


func apply_poison():
	super.apply_poison()
