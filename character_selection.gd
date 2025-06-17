# res://CharacterSelection.gd
extends Control

var selected_chars = []
var _dm # DataManager instance
var _sm # ShopManager instance

# Helper function to get DataManager instance with fallback
func _get_dm_instance(context_msg: String = ""):
	var dm_instance = null
	if Engine.has_singleton("DataManager"):
		dm_instance = DataManager
		print("CharacterSelection (%s): Accessed DataManager via Engine.has_singleton." % context_msg)
	else:
		print("CharacterSelection (%s): Engine.has_singleton('DataManager') returned false. Attempting get_node_or_null('/root/DataManager')." % context_msg)
		dm_instance = get_node_or_null("/root/DataManager")
		if is_instance_valid(dm_instance):
			print("CharacterSelection (%s): Accessed DataManager via get_node_or_null('/root/DataManager')." % context_msg)
		else:
			printerr("CharacterSelection (%s): Failed to access DataManager via get_node_or_null('/root/DataManager') as well." % context_msg)
	return dm_instance

# Helper function to get ShopManager instance with fallback
func _get_sm_instance(context_msg: String = ""):
	var sm_instance = null
	if Engine.has_singleton("ShopManager"):
		sm_instance = ShopManager
		print("CharacterSelection (%s): Accessed ShopManager via Engine.has_singleton." % context_msg)
	else:
		print("CharacterSelection (%s): Engine.has_singleton('ShopManager') returned false. Attempting get_node_or_null('/root/ShopManager')." % context_msg)
		sm_instance = get_node_or_null("/root/ShopManager")
		if is_instance_valid(sm_instance):
			print("CharacterSelection (%s): Accessed ShopManager via get_node_or_null('/root/ShopManager')." % context_msg)
		else:
			printerr("CharacterSelection (%s): Failed to access ShopManager via get_node_or_null('/root/ShopManager') as well." % context_msg)
	return sm_instance


func _ready():
	_dm = _get_dm_instance("_ready")
	_sm = _get_sm_instance("_ready") # Initialize _sm as well

	if not is_instance_valid(_dm):
		printerr("CharacterSelection: DataManager instance NOT VALID. Character list cannot be populated.")
		return
	if not is_instance_valid(_sm):
		printerr("CharacterSelection: ShopManager instance NOT VALID. Costs may not be displayed.")
		# Allow continuation if _sm is not found, costs just won't show.

	update_character_list()
	$StartButton.pressed.connect(Callable(self, "_on_start_game"))

func update_character_list():
	if not is_instance_valid(_dm): 
		printerr("CharacterSelection.update_character_list: DataManager instance not valid.")
		return
	print("CharacterSelection.update_character_list: --- Entering function ---") 
	print("CharacterSelection.update_character_list: _dm.player_characters data: ", _dm.player_characters) 

	var character_list = $CharacterList
	
	# Clear existing cards
	for child in character_list.get_children():
		child.queue_free()
	
	for char_type_enum_val in _dm.player_characters: 
		print("CharacterSelection.update_character_list: Processing char_type_enum_val: ", char_type_enum_val) 
		var char_data = _dm.player_characters[char_type_enum_val]
		
		var card_scene = load("res://Card.tscn")
		if not card_scene:
			printerr("CharacterSelection: Failed to load Card.tscn")
			continue
		var card = card_scene.instantiate()
		print("CharacterSelection.update_character_list: Instantiated card for char_type_enum_val: ", char_type_enum_val) 
		
		card.is_player = true
		# card.type is set by card.update_appearance() if Card.gd handles int type for this
		# If Card.gd expects a string type immediately, then:
		# card.type = convert_type_to_string(char_type_enum_val) # Set string type for Card.gd's _ready or update_appearance
		card.type = char_type_enum_val # Set type to integer enum value
		card.health = char_data.health
		card.max_health = char_data.health
		card.attack = char_data.attack
		card.set_meta("char_type_enum", char_type_enum_val) 
		
		# Crucial: Call update methods AFTER setting initial data but BEFORE adding cost label
		if card.has_method("update_labels"):
			card.update_labels()
		if card.has_method("update_appearance"): # This should set card.type if it takes an int
			card.update_appearance() # Removed argument as per subtask
		# If update_appearance doesn't set card.type string, and Card.tscn needs it:
		# card.type = convert_type_to_string(char_type_enum_val) # This is now done above


		character_list.add_child(card) # Add to scene tree before accessing size for label positioning
		card.pressed.connect(Callable(self, "_on_char_selected").bind(card))
		
		if not char_data.unlocked:
			card.modulate = Color(0.5, 0.5, 0.5, 1)  
			card.disabled = true  
			
			var cost_label = Label.new()
			cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			cost_label.name = "CostLabel" # Give it a name for potential future reference
			
			var cost_text = "Locked"
			if is_instance_valid(_sm) and _sm.shop_item_definitions.has(ShopManager.TYPE_CHARACTER) and \
			   _sm.shop_item_definitions[ShopManager.TYPE_CHARACTER].has(char_type_enum_val):
				var item_cost = _sm.shop_item_definitions[ShopManager.TYPE_CHARACTER][char_type_enum_val].cost
				cost_text = "Cost: %d KC" % item_cost
			else:
				cost_text = "Locked (Unavailable)" 
				if not is_instance_valid(_sm):
					print("CharacterSelection: ShopManager instance not valid, cannot display cost for %s." % char_type_enum_val)

			cost_label.text = cost_text
			
			card.add_child(cost_label) 
			# Defer positioning slightly to allow card to get its size, or ensure Card.tscn has a min_size.
			# This can still be tricky if card size is not immediate.
			# A common pattern is to use call_deferred for positioning if size is determined late.
			# For now, direct positioning after add_child:
			cost_label.set_position(Vector2( (card.size.x - cost_label.size.x) / 2.0 , card.size.y - cost_label.size.y - 5.0))
		else:
			# Ensure any previously added cost labels are removed if the state changes (e.g. debug unlock)
			var existing_cost_label = card.find_child("CostLabel", false, false) # Non-recursive search
			if existing_cost_label:
				existing_cost_label.queue_free()


func convert_type_to_string(char_type_int: int) -> String:
	match char_type_int:
		Globals.CardType.PALADIN: return "PALADIN"
		Globals.CardType.MAGE: return "MAGE"
		Globals.CardType.KNIGHT: return "KNIGHT"
		Globals.CardType.ARCHER: return "ARCHER"
		Globals.CardType.ASSASSIN: return "ASSASSIN"
		Globals.CardType.CLERIC: return "CLERIC"
		Globals.CardType.ENEMY: return "ENEMY"
		Globals.CardType.BOSS: return "BOSS"
		_: return "UNKNOWN_TYPE_%d" % char_type_int 


func _on_char_selected(card_node): # card_node is the Card.tscn instance
	if not is_instance_valid(_dm):
		printerr("CharacterSelection: DataManager instance not valid in _on_char_selected.")
		return

	var char_type_enum = card_node.get_meta("char_type_enum")

	if not _dm.player_characters[char_type_enum].unlocked:
		var cost_text_info = "Locked"
		if is_instance_valid(_sm) and _sm.shop_item_definitions.has(ShopManager.TYPE_CHARACTER) and \
		   _sm.shop_item_definitions[ShopManager.TYPE_CHARACTER].has(char_type_enum):
			var item_cost = _sm.shop_item_definitions[ShopManager.TYPE_CHARACTER][char_type_enum].cost
			cost_text_info = "Unlock in shop for %d KC." % item_cost
		else:
			cost_text_info = "and unavailable in the shop."
			if not is_instance_valid(_sm):
				print("CharacterSelection: ShopManager instance not valid, cannot display cost for %s." % char_type_enum)
		
		print("Character %s is locked. %s" % [convert_type_to_string(char_type_enum), cost_text_info])
		return 
	
	if char_type_enum in selected_chars:
		selected_chars.erase(char_type_enum)
	elif selected_chars.size() < 3:
		selected_chars.append(char_type_enum)
	
	update_visual_feedback() 
	update_start_button()

func update_visual_feedback():
	if not is_instance_valid(_dm): 
		printerr("CharacterSelection: DataManager instance not valid in update_visual_feedback.")
		return

	for card_node in $CharacterList.get_children():
		var char_type_enum = card_node.get_meta("char_type_enum", -1) 
		if char_type_enum == -1: continue 
		
		if not _dm.player_characters[char_type_enum].unlocked:
			card_node.modulate = Color(0.5, 0.5, 0.5, 1) 
		elif char_type_enum in selected_chars:
			card_node.modulate = Color(0.8, 1.0, 0.8, 1) 
		else:
			card_node.modulate = Color(1, 1, 1, 1)  


# This function might still be needed if card.type is not used for logic after card creation,
# and we rely on card.get_meta("char_type_enum").
# However, if Card.tscn's internal logic uses its `type` (String) variable, keep it.
func convert_string_to_type(type_string: String) -> int: 
	match type_string:
		"PALADIN": return Globals.CardType.PALADIN
		"MAGE": return Globals.CardType.MAGE
		"KNIGHT": return Globals.CardType.KNIGHT
		"ARCHER": return Globals.CardType.ARCHER
		"ASSASSIN": return Globals.CardType.ASSASSIN
		"CLERIC": return Globals.CardType.CLERIC
		"ENEMY": return Globals.CardType.ENEMY
		"BOSS": return Globals.CardType.BOSS
		_: 
			printerr("CharacterSelection: Unknown card type string '%s' in convert_string_to_type." % type_string)
			return -1 

func update_start_button():
	$StartButton.disabled = selected_chars.size() != 3

func _on_start_game():
	if selected_chars.size() != 3:
		print("CharacterSelection: Start game attempted with %d characters selected. Need 3." % selected_chars.size())
		return
		
	# Globals.selected_characters is already declared in globals.gd as an empty array.
	# We just need to assign the player's selection to it.
	Globals.selected_characters = selected_chars
	print("CharacterSelection: Globals.selected_characters set to: ", Globals.selected_characters)
	Globals.game_has_started = true
	print("CharacterSelection: Globals.game_has_started set to true.")
	
	# Ensure CharacterSelection screen is hidden before changing scene
	# This might be redundant if change_scene_to_file handles it, but good for safety.
	# hide() # Replaced by queue_free() on success
	
	var scene_change_result = get_tree().change_scene_to_file("res://Main.tscn")
	
	if scene_change_result == OK:
		print("CharacterSelection: Successfully initiated scene change to Main.tscn. Queuing self for removal.")
		self.queue_free() # Remove the character selection screen
	else:
		printerr("CharacterSelection: Failed to change scene to Main.tscn. Error code: %s" % scene_change_result)
		# self.show() is not strictly needed here if it was never hidden, 
		# or if the failure means we stay on this screen.
		# If it was hidden before attempting scene change, then show() would be appropriate.
		# The previous `hide()` call was removed as `queue_free()` handles visibility.
