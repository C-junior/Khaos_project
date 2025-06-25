# GameManager.gd
extends Node
class_name GameManager
const Card = preload("res://card.gd")

# TODO: Consider adding a SHOP_PHASE for when the player is interacting with a Khaos Coins shop
enum State { PLAYER_TURN, ENEMY_TURN, UPGRADE_PHASE, GAME_OVER } #, SHOP_PHASE }

var default_cursor = load("res://cursors/cursor1.png")
var targeting_cursor = load("res://cursors/targeting1.png")
var current_state = State.PLAYER_TURN
var selected_card = null
var is_targeting_ability = false
var targeting_card = null
var current_wave = 0
var _dm_instance = null # Cache for DataManager instance

# Helper function to get DataManager instance with fallback and caching
func _get_dm_instance(context_msg: String = "") -> Object: # Added return type
	if is_instance_valid(_dm_instance):
		# print("GameManager (%s): Reusing cached DataManager instance." % context_msg) # Optional: verbose
		return _dm_instance

	var dm = null # Renamed from local 'dm_instance' to 'dm' to avoid confusion with class var
	if Engine.has_singleton("DataManager"):
		dm = DataManager
		print("GameManager (%s): Accessed DataManager via Engine.has_singleton." % context_msg)
	else:
		print("GameManager (%s): Engine.has_singleton('DataManager') returned false. Attempting get_node_or_null('/root/DataManager')." % context_msg)
		dm = get_node_or_null("/root/DataManager")
		if is_instance_valid(dm):
			print("GameManager (%s): Accessed DataManager via get_node_or_null('/root/DataManager')." % context_msg)
		else:
			printerr("GameManager (%s): Failed to access DataManager via get_node_or_null('/root/DataManager') as well." % context_msg)
	
	if is_instance_valid(dm):
		_dm_instance = dm # Cache the successfully obtained instance
	
	return dm # Return the fetched (or null) instance

func _ready():
	_dm_instance = _get_dm_instance("_ready") # Initialize here

	if is_instance_valid(_dm_instance):
		get_node("../SaveButton").pressed.connect(Callable(_dm_instance, "save_game"))
	else:
		printerr("GameManager: DataManager instance NOT VALID in _ready. Save button will not work.")
	
	
	get_node("../LoadButton").pressed.connect(Callable(self, "_on_load_game"))
	$"../EndTurnButton".pressed.connect(Callable(self, "player_end_turn"))
	Input.set_custom_mouse_cursor(default_cursor)

	var globals_node = null
	var game_should_start = false # Default to false

	print("GameManager._ready: Checking for Globals singleton to determine if game should start...")
	if Engine.has_singleton("Globals"):
		globals_node = Globals
		print("GameManager._ready: Accessed Globals via Engine.has_singleton.")
	else:
		print("GameManager._ready: Engine.has_singleton('Globals') returned false. Attempting get_node_or_null('/root/Globals').")
		globals_node = get_node_or_null("/root/Globals")
		if is_instance_valid(globals_node):
			print("GameManager._ready: Accessed Globals via get_node_or_null('/root/Globals').")
		else:
			printerr("GameManager._ready: CRITICAL - Failed to access Globals via get_node_or_null('/root/Globals') as well. Cannot determine if game should start.")
			# No 'return' here, let it fall through to the 'else' of 'if game_should_start' for cleanup.

	if is_instance_valid(globals_node):
		# Assumes 'game_has_started' is a declared var: var game_has_started: bool = false in globals.gd
		if globals_node.game_has_started == true: # Direct access as it's a declared var
			game_should_start = true
			print("GameManager._ready: Globals.game_has_started is true.")
		else:
			print("GameManager._ready: Globals.game_has_started is false.")
	else:
		printerr("GameManager._ready: Globals instance is NOT VALID. Defaulting to not starting game from _ready.")
		game_should_start = false # Explicitly ensure it's false if Globals node is not valid

	if game_should_start:
		print("GameManager._ready: Calling self.start_game().")
		self.start_game()
		if is_instance_valid(globals_node): # Reset the flag only if Globals was accessible
			globals_node.game_has_started = false 
			print("GameManager._ready: Reset Globals.game_has_started to false.")
	else:
		print("GameManager._ready: start_game() will NOT be called by _ready(). (Reason: game_should_start is false).")
		var player_cards_node = get_node_or_null("../PlayerCards")
		if player_cards_node:
			print("GameManager._ready: Clearing PlayerCards node because game is not starting now.")
			for child in player_cards_node.get_children():
				child.queue_free()
		var enemy_cards_node = get_node_or_null("../EnemyCards")
		if enemy_cards_node:
			print("GameManager._ready: Clearing EnemyCards node because game is not starting now.")
			for child in enemy_cards_node.get_children():
				child.queue_free()

func start_game():
	print("GameManager.start_game: --- Entering function ---")
	var player_cards_node = get_node_or_null("../PlayerCards")
	if not player_cards_node:
		printerr("GameManager.start_game: PlayerCards node not found (path: ../PlayerCards). Cannot create player cards.")
		return

	# Clear Existing Cards
	print("GameManager.start_game: Clearing existing cards from PlayerCards node...")
	for child in player_cards_node.get_children():
		child.queue_free()
	print("GameManager.start_game: Existing cards cleared.")

	# Check for DataManager and Globals
	print("GameManager.start_game: Checking for DataManager instance (from _dm_instance cache or emergency fetch)...")
	if not is_instance_valid(_dm_instance): # Check cached instance first
		_dm_instance = _get_dm_instance("start_game_emergency_fetch") # Attempt to fetch if not valid
		if not is_instance_valid(_dm_instance):
			printerr("GameManager.start_game: DataManager instance is NOT VALID even after emergency fetch. Cannot create player cards.")
			return
		else:
			print("GameManager.start_game: DataManager instance obtained via emergency fetch in start_game.")
	else:
		print("GameManager.start_game: DataManager instance found via _dm_instance cache.")
		
	print("GameManager.start_game: Checking Globals.selected_characters...")
	# Globals.selected_characters is now declared in globals.gd, initialized to an empty array.
	# character_selection.gd should populate it before calling start_game.
	if Globals.selected_characters == null: # Should not happen if globals.gd is parsed first
		printerr("GameManager.start_game: Globals.selected_characters is null! This indicates a severe issue with Globals script loading or it was somehow reset to null.")
		# Fallback to prevent crash, though this is a critical error state
		Globals.selected_characters = [Globals.CardType.PALADIN]
		print("GameManager.start_game: CRITICAL FALLBACK - using default Paladin because Globals.selected_characters was null.")
		# return # Consider returning if this state is too unstable
	elif Globals.selected_characters.is_empty():
		printerr("GameManager.start_game: Globals.selected_characters is empty. Character selection might not have run or failed to set characters.")
		# Fallback for testing, as per previous logic. Ideally, character selection ensures this isn't empty.
		Globals.selected_characters = [Globals.CardType.PALADIN]
		print("GameManager.start_game: Fallback - using default Paladin because selected_characters was empty.")
	else:
		print("GameManager.start_game: Globals.selected_characters found: ", Globals.selected_characters)


	print("GameManager.start_game: Attempting to load Card.tscn for card instances...")
	var card_scene = load("res://Card.tscn")
	if not card_scene:
		printerr("GameManager.start_game: Failed to load Card.tscn resource.")
		return
	print("GameManager.start_game: Card.tscn loaded successfully.")

	# Iterate Selected Characters
	print("GameManager.start_game: Starting iteration of Globals.selected_characters...")
	for char_type_enum in Globals.selected_characters:
		print("GameManager.start_game: Processing char_type_enum: ", char_type_enum)
		if not _dm_instance.player_characters.has(char_type_enum):
			printerr("GameManager.start_game: char_type_enum %s NOT FOUND in _dm_instance.player_characters." % char_type_enum)
			print("GameManager.start_game: Available character keys in _dm_instance.player_characters: ", _dm_instance.player_characters.keys())
			continue
		print("GameManager.start_game: char_type_enum %s FOUND in _dm_instance.player_characters." % char_type_enum)
		
		var char_data = _dm_instance.player_characters[char_type_enum]
		print("GameManager.start_game: char_data fetched: ", char_data)
		
		if not char_data.unlocked:
			printerr("GameManager.start_game: Character %s is LOCKED." % char_data.name if char_data.has("name") else str(char_type_enum))
			continue
		print("GameManager.start_game: Character %s is UNLOCKED." % char_data.name if char_data.has("name") else str(char_type_enum))
		
		# Before loading Card.tscn (already loaded, now instantiating)
		print("GameManager.start_game: Attempting to instantiate Card.tscn...")
		var card_instance = card_scene.instantiate()
		if not is_instance_valid(card_instance):
			printerr("GameManager.start_game: FAILED to instantiate Card.tscn.")
			continue
		print("GameManager.start_game: Card instance created. Setting properties...")
		
		# Set card properties
		card_instance.type = char_type_enum # Card.gd's set_type should handle string conversion if needed for display
		card_instance.is_player = true
		card_instance.health = char_data.health
		card_instance.max_health = char_data.health
		card_instance.attack = char_data.attack
		card_instance.base_attack = char_data.attack # Assuming base_attack should match initial attack
		# card_instance.text will be set by card_instance.update_appearance() which is called later
		
		player_cards_node.add_child(card_instance)
		card_instance.add_to_group("PlayerCards")
		card_instance.pressed.connect(Callable(self, "_on_card_pressed").bind(card_instance))
		print("GameManager.start_game: Card instance %s (type %s) added to scene and pressed signal connected." % [card_instance.name, char_type_enum]) # card_instance.name might be empty
		
		# Connect ability button
		var ability_button = card_instance.get_node_or_null("VBoxContainer/AbilityButton") # Adjust path as needed
		if ability_button:
			ability_button.pressed.connect(Callable(self, "_on_ability_pressed").bind(card_instance))
			print("GameManager.start_game: Ability button connected for card type %s." % char_type_enum)
		else:
			print("Warning: Could not find VBoxContainer/AbilityButton for card type: %s" % char_type_enum) 
		
		card_instance.update_labels()       # Initialize UI text elements on the card
		card_instance.update_appearance()   # Set texture and name label based on type
		print("GameManager.start_game: Labels and appearance updated for card. Final card text: '%s'" % card_instance.text)
		print("GameManager.start_game: Created player card: %s (Type: %s)" % [card_instance.text, char_type_enum]) # Duplicate of above for clarity

	print("GameManager.start_game: Finished iterating selected characters. Calling start_wave().")
	start_wave()
	print("GameManager.start_game: --- Exiting function ---")

	# Add new code below to hide CharacterSelection
	var character_selection_node = get_node_or_null("%CharacterSelection")
	if is_instance_valid(character_selection_node):
		print("GameManager.start_game: Hiding CharacterSelection node (%CharacterSelection).")
		character_selection_node.hide()
	else:
		printerr("GameManager.start_game: CharacterSelection node not found at path '%CharacterSelection'. Cannot hide it.")

func start_wave():
	if current_wave >= Data.waves.size():
		print("You win!")
		# Removed hardcoded character unlocks:
		# get_node("../DataManager").unlock_character(Globals.CardType.ARCHER)
		# get_node("../DataManager").unlock_character(Globals.CardType.ROGUE)
		show_victory_screen()
		return
	var enemy_cards = get_node("../EnemyCards")
	for child in enemy_cards.get_children():
		child.queue_free()
	var wave_data = Data.waves[current_wave]
	for enemy_type_key in wave_data.enemies:
		var enemy_data = Data.ENEMY_TYPES[enemy_type_key]
		var enemy = load("res://Card.tscn").instantiate()
		enemy.is_player = false
		
		# Determine if this is a boss type
		if enemy_type_key == "OrcBoss" or "Boss" in enemy_type_key:
			enemy.type = Globals.CardType.BOSS
		else:
			enemy.type = Globals.CardType.ENEMY
		
		# Set enemy properties from the enemy type data
		enemy.health = enemy_data.health
		enemy.max_health = enemy_data.health
		enemy.attack = enemy_data.attack
		enemy.base_attack = enemy_data.attack
		enemy.has_attacked = false
		enemy.ability_used = false
		
		# Set the enemy name for display
		enemy.text = enemy_data.name
		
		# Initialize all status effects
		enemy.status_effects = {
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
		
		# If the enemy has a special ability, store it
		if "ability" in enemy_data:
			enemy.status_effects.special_ability = enemy_data.ability
		
		enemy.spell_count = 0
		enemy_cards.add_child(enemy)
		enemy.pressed.connect(Callable(self, "_on_card_pressed").bind(enemy))
		
		# Set enemy image if available
		if "image" in enemy_data and enemy.has_method("set_image"):
			enemy.set_image(enemy_data.image)
		
		enemy.update_labels()
		enemy.update_appearance()
	current_state = State.PLAYER_TURN
	reset_player_attacks()
	get_node("../UIManager").update_turn_label()
	get_node("../UIManager").update_wave_progress()
	# Removed hardcoded character unlock:
	# if current_wave == 5:
		# get_node("../DataManager").unlock_character(Globals.CardType.CLERIC)
		
func perform_attack(attacker, defender):
	if attacker.ability_used:
		print("%s cannot attack after using an ability this turn." % attacker.name)
		return
	attacker.attack_target(defender)
	attacker.has_attacked = true
	get_node("../UIManager").update_wave_progress()
	if check_wave_cleared():
		var dm = _get_dm_instance("perform_attack_wave_cleared") # Use helper
		if is_instance_valid(dm): # Check instance validity
			if dm.has_method("add_khaos_coins"):
				dm.add_khaos_coins(10)
			else:
				# Fallback, though add_khaos_coins should exist
				dm.current_khaos_coins += 10 # This direct access is less ideal
			
			var ui_manager = get_node("../UIManager") # UIManager might also become an autoload later
			if ui_manager and ui_manager.has_method("update_khaos_coins_label"): # Check ui_manager valid
				ui_manager.update_khaos_coins_label(dm.current_khaos_coins)
		else:
			printerr("GameManager: DataManager instance NOT VALID in perform_attack. Cannot add Khaos Coins.")
			
		# TODO: Potentially, instead of or in addition to upgrade_phase, transition to a shop_phase
		# enter_shop_phase() 
		get_node("../UIManager").start_upgrade_phase()
	elif check_game_over():
		game_over()

func check_wave_cleared():
	for enemy in get_node("../EnemyCards").get_children():
		if enemy.health > 0:
			return false
	return true

func check_game_over():
	for card in get_node("../PlayerCards").get_children():
		if card.health > 0:
			return false
	return true

func reset_player_attacks():
	for card in get_node("../PlayerCards").get_children():
		card.has_attacked = false
		card.ability_used = false

func player_end_turn():
	for card in get_node("../PlayerCards").get_children():
		if card.is_player and not card.artifacts.is_empty(): # Check if it's a player card and has artifacts
			for artf in card.artifacts: # Iterate through the artifacts array
				if artf: # Ensure artifact exists
					artf.turn_end()
	current_state = State.ENEMY_TURN
	get_node("../UIManager").update_turn_label()
	perform_enemy_turn()

func perform_enemy_turn():
	for enemy in get_node("../EnemyCards").get_children():
		if enemy.health <= 0:
			continue
		
		# Apply poison damage
		enemy.apply_poison()
		if enemy.health <= 0:
			continue
		
		# Check if frozen
		if enemy.status_effects.is_frozen:
			enemy.status_effects.is_frozen = false
			print("%s is frozen and skips their turn!" % enemy.text)
			continue
		
		# Check attack delay
		if enemy.status_effects.attack_delay > 0:
			enemy.status_effects.attack_delay -= 1
			print("%s is delayed and cannot attack!" % enemy.text)
			continue
		
		# Check for special abilities - ONLY for enemies that actually have them
		if enemy.status_effects.special_ability != "" and enemy.type == Globals.CardType.BOSS:
			# Call the special ability function from Data
			var ability_name = enemy.status_effects.special_ability
			if Data.has_method(ability_name):
				print("%s uses special ability: %s" % [enemy.text, ability_name])
				Data.call(ability_name, enemy, [])
				await get_tree().create_timer(0.5).timeout
				continue
		
		# Find target and attack - SIMPLIFIED LOGIC
		var targets = get_node("../PlayerCards").get_children().filter(func(c): return c.health > 0)
		if targets.size() == 0:
			print("%s has no targets to attack!" % enemy.text)
			continue
		
		# Filter out invisible targets
		var visible_targets = targets.filter(func(t): return not t.status_effects.is_invisible)
		
		# Choose target (prefer visible targets, but attack invisible if no choice)
		var chosen_target
		if visible_targets.size() > 0:
			# Attack the weakest visible target
			chosen_target = visible_targets[0]
			for target in visible_targets:
				if target.health < chosen_target.health:
					chosen_target = target
		else:
			# All targets are invisible, pick the first one
			chosen_target = targets[0]
			print("%s attacks blindly at invisible targets!" % enemy.text)
		
		print("%s attacks %s!" % [enemy.text, chosen_target.text])
		print("Before attack - %s health: %d, %s attack: %d" % [chosen_target.text, chosen_target.health, enemy.text, enemy.attack])
		
		enemy.attack_target(chosen_target)
		
		print("After attack - %s health: %d" % [chosen_target.text, chosen_target.health])
		await get_tree().create_timer(0.5).timeout
	
	# Reset invisibility at end of turn
	for player in get_node("../PlayerCards").get_children():
		if player.status_effects.is_invisible:
			player.status_effects.is_invisible = false
			print("%s is no longer invisible." % player.text)
	
	# Reset any temporary status effects that should only last one turn
	for enemy in get_node("../EnemyCards").get_children():
		if enemy.status_effects.attack_boost > 0:
			enemy.attack = enemy.base_attack  # Reset attack to base
			enemy.status_effects.attack_boost = 0
		if enemy.status_effects.shield_active:
			enemy.status_effects.shield_active = false
	
	if check_game_over():
		game_over()
	else:
		current_state = State.PLAYER_TURN
		reset_player_attacks()
		get_node("../UIManager").update_turn_label()
		
func game_over():
	current_state = State.GAME_OVER
	get_node("../UIManager").update_turn_label()
	print("Game Over")
	show_game_over_screen()

func show_game_over_screen():
	# Create a simple restart button
	var restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.size = Vector2(200, 50)
	restart_button.position = Vector2(400, 300)
	get_tree().current_scene.add_child(restart_button)
	restart_button.pressed.connect(restart_game)

func show_victory_screen():
	# Create a simple restart button for victory
	var restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.size = Vector2(200, 50)
	restart_button.position = Vector2(400, 300)
	get_tree().current_scene.add_child(restart_button)
	restart_button.pressed.connect(restart_game)

func restart_game():
	# Reset game state variables in GameManager itself
	current_wave = 0
	current_state = State.PLAYER_TURN # Or whatever initial state is appropriate before _ready runs
	selected_card = null
	is_targeting_ability = false
	targeting_card = null
	
	# Reset the global flag so that when Main.tscn reloads,
	# GameManager._ready() doesn't immediately call start_game().
	var g = null
	if Engine.has_singleton("Globals"): # Check if Globals is available
		g = Globals
		print("GameManager.restart_game: Accessed Globals via Engine.has_singleton.")
	else: # Fallback if Engine.has_singleton itself fails for Globals
		g = get_node_or_null("/root/Globals")
		if is_instance_valid(g):
			print("GameManager.restart_game (fallback): Accessed Globals via get_node_or_null.")
		else:
			printerr("GameManager.restart_game (fallback): Could not get Globals instance to reset game_has_started flag.")

	if is_instance_valid(g):
		print("GameManager.restart_game: Resetting Globals.game_has_started to false.")
		g.game_has_started = false
	else:
		printerr("GameManager.restart_game: Globals instance not valid, cannot reset game_has_started flag.")


	# The CharacterSelection node is part of Main.tscn.
	# When reload_current_scene() reloads Main.tscn, CharacterSelection will be part of its initial state.
	# GameManager._ready() will then run, see game_has_started = false, clear player/enemy cards,
	# and CharacterSelection (which is part of Main.tscn's tree) should be visible by default.
	# No explicit .show() needed here for CharacterSelection if Main.tscn is set up with it visible initially.

	# Remove restart button if it exists
	for child in get_tree().current_scene.get_children():
		if child is Button and (child.text == "Restart Game" or child.text == "Play Again"):
			child.queue_free()
	
	# TODO: Reset ShopManager if it holds state across games, or ensure it's freshly initialized
	# if shop_manager_instance: shop_manager_instance.reset_shop_state()

	# Reload the main scene
	get_tree().reload_current_scene()

# Placeholder for ShopManager instance
# var shop_manager_instance = null

# func _ready():
	# ... existing _ready() code ...
	# TODO: Instantiate ShopManager. This could be a scene preloaded and instanced,
	# or a .gd script new()ed.
	# var ShopManagerScene = load("res://ShopManager.tscn") # If it's a scene
	# shop_manager_instance = ShopManagerScene.instantiate()
	# add_child(shop_manager_instance)
	# Or if ShopManager.gd is just a script:
	# shop_manager_instance = load("res://scripts/ShopManager.gd").new()
	# shop_manager_instance.name = "ShopManager" # Optional: give it a name for get_node
	# add_child(shop_manager_instance) # Optional: if it needs to be in the tree
	# If ShopManager needs DataManager, set it up:
	# if shop_manager_instance and shop_manager_instance.has_method("set_data_manager"):
	#    shop_manager_instance.set_data_manager(get_node("../DataManager"))


func enter_shop_phase():
	# TODO: Implement logic to transition to a dedicated shop phase.
	# This might involve:
	# 1. Setting current_state = State.SHOP_PHASE (if SHOP_PHASE is added to enum)
	# 2. Notifying UIManager to display the shop interface:
	#    var ui_manager = get_node("../UIManager") # UIManager might also become an autoload later
	#    if ui_manager and ui_manager.has_method("display_shop_interface"):
	#        var dm = _get_dm_instance("enter_shop_phase") # Use helper
	#        if is_instance_valid(dm): # Check instance validity
	#            ui_manager.display_shop_interface(dm.current_khaos_coins)
	#        else:
	#            printerr("GameManager: DataManager instance NOT VALID for enter_shop_phase.")
	# 3. Potentially pausing other game elements.
	# 4. Shop interactions would then be handled, possibly through ShopManager or UIManager.
	print("Placeholder: Entering Shop Phase...")
	# current_state = State.SHOP_PHASE # Uncomment if SHOP_PHASE state is added
	# get_node("../UIManager").update_turn_label() # To reflect "Shop Phase"

func set_targeting_cursor(is_targeting):
	Input.set_custom_mouse_cursor(targeting_cursor if is_targeting else default_cursor)

func _on_card_pressed(card):
	if current_state != State.PLAYER_TURN:
		return
	if is_targeting_ability:
		if not card.is_player and targeting_card:
			targeting_card.use_ability([card])
			targeting_card.ability_used = true
			targeting_card.has_attacked = true
			is_targeting_ability = false
			targeting_card = null
			set_targeting_cursor(false)
			if check_wave_cleared():
				var dm = _get_dm_instance("_on_card_pressed_wave_cleared") # Use helper
				if is_instance_valid(dm): # Check instance validity
					if dm.has_method("add_khaos_coins"):
						dm.add_khaos_coins(10)
					else:
						dm.current_khaos_coins += 10 # Less ideal direct access
					
					var ui_manager = get_node("../UIManager") 
					if ui_manager and ui_manager.has_method("update_khaos_coins_label"): 
						ui_manager.update_khaos_coins_label(dm.current_khaos_coins)
				else:
					printerr("GameManager: DataManager instance NOT VALID in _on_card_pressed. Cannot add Khaos Coins.")
				get_node("../UIManager").start_upgrade_phase()
			elif check_game_over():
				game_over()
	else:
		if card.is_player:
			selected_card = card
		elif selected_card and not selected_card.has_attacked:
			perform_attack(selected_card, card)
			selected_card = null

func _on_ability_pressed(card): # card is the CardBase instance
	# Basic turn and state checks
	if current_state != State.PLAYER_TURN or card.ability_used or card.has_attacked:
		if card.has_attacked: # Provide specific feedback if already attacked
			print("%s cannot use ability after attacking this turn." % card.text) # Use card.text for name
		elif card.ability_used:
			print("%s has already used an ability this turn." % card.text)
		return

	# Check if the card has any artifacts and if the primary one (artifacts[0]) can be used
	if card.artifacts.is_empty():
		print("%s has no artifacts equipped." % card.text)
		return

	var artifact_to_use = card.artifacts[0] # Defaulting to the first artifact

	if not artifact_to_use: # Should not happen if artifacts array is not empty and contains valid objects
		printerr("Error: %s has an empty or invalid entry in artifacts array." % card.text)
		return

	if artifact_to_use.current_cooldown > 0:
		print("%s's %s is on cooldown for %d turns." % [card.text, artifact_to_use.name, artifact_to_use.current_cooldown])
		return
	
	# Proceed with targeting or direct use
	if artifact_to_use.requires_targets:
		if is_targeting_ability and targeting_card == card:
			# Cancel targeting if the same card's ability is pressed again while targeting
			is_targeting_ability = false
			targeting_card = null
			set_targeting_cursor(false)
			print("Targeting cancelled for %s's %s." % [card.text, artifact_to_use.name])
		else:
			is_targeting_ability = true
			targeting_card = card # This is the card whose ability is being targeted
			set_targeting_cursor(true)
			print("Select a target for %s's %s." % [card.text, artifact_to_use.name])
	else:
		# Non-targeted ability
		card.use_ability([]) # CardBase.use_ability will use artifacts[0]
		card.ability_used = true
		card.has_attacked = true
		if check_wave_cleared():
			var dm = _get_dm_instance("_on_ability_pressed_wave_cleared") # Use helper
			if is_instance_valid(dm): # Check instance validity
				if dm.has_method("add_khaos_coins"):
					dm.add_khaos_coins(10)
				else:
					dm.current_khaos_coins += 10 # Less ideal direct access
				
				var ui_manager = get_node("../UIManager") 
				if ui_manager and ui_manager.has_method("update_khaos_coins_label"): 
					ui_manager.update_khaos_coins_label(dm.current_khaos_coins)
			else:
				printerr("GameManager: DataManager instance NOT VALID in _on_ability_pressed. Cannot add Khaos Coins.")
			get_node("../UIManager").start_upgrade_phase()
		elif check_game_over():
			game_over()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and is_targeting_ability:
		is_targeting_ability = false
		targeting_card = null
		set_targeting_cursor(false)
		print("Targeting cancelled by right-click")

func _on_load_game():
	var dm = _get_dm_instance("_on_load_game") # Use helper
	if not is_instance_valid(dm): # Check instance validity
		printerr("GameManager: DataManager instance NOT VALID. Cannot load game.")
		return

	if dm.load_game(): # load_game() in DataManager should handle its own file access and parsing errors
		# Populate player cards based on dm.player_cards_run
		var player_cards_node = get_node_or_null("../PlayerCards")
		if not player_cards_node:
			printerr("GameManager: PlayerCards node not found during load game.")
			return # Cannot proceed with card setup

		# Clear existing cards from the scene first
		for child in player_cards_node.get_children():
			child.queue_free()
		
		for card_data in dm.player_cards_run:
			var card_scene = load("res://Card.tscn") 
			if card_scene:
				var card_instance = card_scene.instantiate()
				card_instance.type = card_data.get("type", Globals.CardType.PALADIN) 
				card_instance.health = card_data.get("health", 10)
				card_instance.max_health = card_data.get("max_health", 10)
				card_instance.attack = card_data.get("attack", 1)

				# Re-instance artifacts
				card_instance.artifacts = [] # Initialize as empty array
				var loaded_artifacts_data = card_data.get("artifacts", [])
				if loaded_artifacts_data is Array:
					for art_data in loaded_artifacts_data:
						if art_data is Dictionary and art_data.has("name"):
							var artifact_name = art_data.get("name")
							var new_artifact = ArtifactFactory.create_artifact(artifact_name)
							if new_artifact:
								new_artifact.current_cooldown = art_data.get("current_cooldown", 0)
								var rune_name = art_data.get("rune", "")
								if not rune_name.is_empty():
									# ArtifactFactory.attach_rune_to_artifact handles rune creation
									ArtifactFactory.attach_rune_to_artifact(new_artifact, rune_name)
								card_instance.artifacts.append(new_artifact)
							else:
								printerr("GameManager _on_load_game: Failed to create artifact '%s'" % artifact_name)
				
				player_cards_node.add_child(card_instance)
				card_instance.add_to_group("PlayerCards")
				card_instance.pressed.connect(Callable(self, "_on_card_pressed").bind(card_instance))
				var ability_button = card_instance.get_node_or_null("VBoxContainer/AbilityButton") 
				if ability_button:
					ability_button.pressed.connect(Callable(self, "_on_ability_pressed").bind(card_instance))
				card_instance.update_labels() 
			else:
				printerr("GameManager: Failed to load Card.tscn for loading game.")
		
		# Set current wave from DataManager
		current_wave = dm.current_wave_run
		
		# Update UI elements that depend on loaded data
		var ui_manager = get_node_or_null("../UIManager")
		if is_instance_valid(ui_manager):
			ui_manager.update_turn_label() 
			ui_manager.update_wave_progress()
			if ui_manager.has_method("update_khaos_coins_label"):
				ui_manager.update_khaos_coins_label(dm.current_khaos_coins) # Use dm
		else:
			printerr("GameManager: UIManager node not found, cannot update UI on load.")

		current_state = State.PLAYER_TURN 
		reset_player_attacks()
		start_wave() 
	else:
		# This 'else' means dm.load_game() returned false. 
		# DataManager.load_game() itself should print why (no file, parse error, no run data).
		print("GameManager: DataManager.load_game() returned false. No run loaded.")
		# Optionally, still go to game scene but in a default start state, or show error.

# player_cards are now populated by start_game based on DataManager initial state,
# or by _on_load_game based on DataManager.player_cards_run.
# The erroneous block below this comment (which was causing the "Identifier 'card' not declared" error)
# has been removed. The function _on_load_game() now correctly ends after the else block above.

# Helper methods for enemy abilities
func get_alive_player_cards() -> Array:
	return get_node("../PlayerCards").get_children().filter(func(c): return c.health > 0)

func get_alive_enemies() -> Array:
	return get_node("../EnemyCards").get_children().filter(func(c): return c.health > 0)

# ADDED: Helper function for reviving fallen cards (referenced in soul_gem_ability)
func revive_fallen_card():
	var player_cards = get_node("../PlayerCards").get_children()
	var fallen_cards = player_cards.filter(func(c): return c.health <= 0)
	
	if fallen_cards.size() > 0:
		var revived_card = fallen_cards[0]  # Revive the first fallen card
		revived_card.health = revived_card.max_health / 2
		revived_card.update_labels()
		revived_card.update_appearance()
		print("%s has been revived with %d health!" % [revived_card.text, revived_card.health])
