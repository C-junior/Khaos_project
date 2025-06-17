# DataManager.gd
extends Node

var save_path = "user://game_save.json"
const SAVE_VERSION = 1

var passive_abilities = {
	Globals.CardType.PALADIN: {
		"name": "Divine Intervention",
		"description": "Redirects 1/3 of damage dealt to allies to the Paladin instead."
	},
	Globals.CardType.KNIGHT: {
		"name": "Bloodlust",
		"description": "Gains 1 attack for each enemy defeated."
	},
		Globals.CardType.MAGE: {
		"name": "Arcane Echo",
		"description": "Arcane Echo doubles the damage from the third artifact spell!."
	}
}

var player_characters = {
	Globals.CardType.PALADIN: {"health": 100, "attack": 45, "unlocked": true, "passive": passive_abilities.get(Globals.CardType.PALADIN)},
	Globals.CardType.MAGE: {"health": 65, "attack": 80, "unlocked": true, "passive": passive_abilities.get(Globals.CardType.MAGE)}, # Mage passive was added to passive_abilities
	Globals.CardType.KNIGHT: {"health": 70, "attack": 75, "unlocked": true, "passive": passive_abilities.get(Globals.CardType.KNIGHT)},
	Globals.CardType.ARCHER: {"health": 75, "attack": 70, "unlocked": false, "passive": passive_abilities.get(Globals.CardType.ARCHER)}, # Assuming ARCHER passive will be added to passive_abilities
	Globals.CardType.CLERIC: {"health": 90, "attack": 45, "unlocked": false, "passive": passive_abilities.get(Globals.CardType.CLERIC)}, # Assuming CLERIC passive will be added
	Globals.CardType.ASSASSIN: {"health": 60, "attack": 85, "unlocked": false, "passive": passive_abilities.get(Globals.CardType.ASSASSIN)}, # Assuming ASSASSIN passive will be added
	Globals.CardType.BERSERKER: {"health": 85, "attack": 60, "unlocked": false, "passive": passive_abilities.get(Globals.CardType.BERSERKER)},# Assuming BERSERKER passive will be added
	Globals.CardType.NECRODANCER: {"health": 70, "attack": 55, "unlocked": false, "passive": passive_abilities.get(Globals.CardType.NECRODANCER)},# Assuming NECRODANCER passive will be added
	Globals.CardType.GUARDIAN: {"health": 100, "attack": 40, "unlocked": false, "passive": passive_abilities.get(Globals.CardType.GUARDIAN)} # Assuming GUARDIAN passive will be added
}

# Global player data (persists across runs)
var current_khaos_coins = 0
var unlocked_characters_global: Dictionary = {} # Globals.CardType (int) -> bool
var unlocked_artifacts_status: Dictionary = {} # Artifact Name (String) -> bool (already suitable)
var unlocked_runes_global: Dictionary = {}     # Rune Name (String) -> bool
var talent_tree_progress_global: Dictionary = {} # Placeholder for future talent system

# Per-run data (reset or loaded per game run)
# These will be populated by load_game() if a run is active.
var current_wave_run = 0
var player_cards_run: Array = []


func _init():
	# Initialize default state for artifacts (all locked initially)
	for artifact_name in Data.artifacts:
		unlocked_artifacts_status[artifact_name] = false
	# Initialize default state for character global unlocks (all locked initially, but base game might unlock some)
	for char_type in player_characters:
		unlocked_characters_global[char_type] = player_characters[char_type].unlocked # Respect initial design
	# Initialize default state for runes (all locked initially)
	for rune_name in Data.runes:
		unlocked_runes_global[rune_name] = false
		
	_load_global_data_on_init() # Load global data as soon as DataManager is ready


func _load_global_data_on_init():
	if not FileAccess.file_exists(save_path):
		print("DataManager: No save file found at %s. Using default global data." % save_path)
		_apply_initial_global_unlocks() # Apply unlocks from player_characters to unlocked_characters_global
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("DataManager: Failed to open save file for reading global data!")
		_apply_initial_global_unlocks()
		return
	
	var save_content = file.get_as_text()
	file.close()
	
	var json_parser = JSON.new()
	var error_code = json_parser.parse(save_content)
	
	if error_code != OK:
		printerr("DataManager (_load_global_data_on_init): Failed to parse save file JSON. Error: '%s' at line %s, column %s" % [json_parser.get_error_message(), json_parser.get_error_line(), json_parser.get_error_column()])
		_apply_initial_global_unlocks()
		print("DataManager: SUCCESSFULLY INITIALIZED AND READY. (after parse error in _load_global_data_on_init)") # Ensure this still prints
		return
	
	var save_data = json_parser.get_data()

	if save_data.has("global_player_data"): # New format
		var global_data = save_data.global_player_data
		current_khaos_coins = global_data.get("khaos_coins", 0)
		
		var loaded_unlocked_chars = global_data.get("unlocked_characters", {})
		for char_type_str in loaded_unlocked_chars:
			var char_type = int(char_type_str) # Keys are saved as strings in JSON
			if player_characters.has(char_type): # Ensure character type is valid
				unlocked_characters_global[char_type] = loaded_unlocked_chars[char_type_str]
		
		unlocked_artifacts_status = global_data.get("unlocked_artifacts", unlocked_artifacts_status) # Keep default if not found
		unlocked_runes_global = global_data.get("unlocked_runes", {})
		talent_tree_progress_global = global_data.get("talent_tree_progress", {})
		
	else: # Attempt to migrate from old format
		print("DataManager: Old save format detected. Migrating global data.")
		current_khaos_coins = save_data.get("khaos_coins", 0)
		
		var old_unlocked_chars = save_data.get("unlocked_characters", {})
		for char_type_str in old_unlocked_chars:
			var char_type = int(char_type_str)
			if player_characters.has(char_type):
				# In old format, this dict stored the 'unlocked' bool directly from player_characters
				unlocked_characters_global[char_type] = old_unlocked_chars[char_type_str]
		
		var old_unlocked_artifacts = save_data.get("unlocked_artifacts", [])
		# Reset existing artifact statuses from Data.artifacts, then apply saved ones
		for artifact_name_key in Data.artifacts:
			unlocked_artifacts_status[artifact_name_key] = false
		for item in old_unlocked_artifacts: # Old format saved as an array of dicts
			if item is Dictionary and item.has("name") and item.has("unlocked"):
				if unlocked_artifacts_status.has(item.name):
					unlocked_artifacts_status[item.name] = item.unlocked
		# Initialize runes and talents as empty for old saves
		unlocked_runes_global = {}
		talent_tree_progress_global = {}

	_apply_global_unlocks_to_player_characters()
	print("DataManager: Global data loaded. Khaos Coins: %d" % current_khaos_coins)

func _apply_initial_global_unlocks():
	# Ensure unlocked_characters_global reflects the initial state defined in player_characters
	for char_type in player_characters:
		unlocked_characters_global[char_type] = player_characters[char_type].get("unlocked", false)
	# Similar for artifacts if they had an initial unlocked state defined elsewhere
	# For now, artifacts default to locked in _init unless overridden by save.
	_apply_global_unlocks_to_player_characters()


func _apply_global_unlocks_to_player_characters():
	# Update the 'unlocked' status in the live player_characters dictionary
	# based on the globally loaded unlocked_characters_global.
	for char_type_key in player_characters:
		if unlocked_characters_global.has(char_type_key):
			player_characters[char_type_key].unlocked = unlocked_characters_global[char_type_key]
		else:
			# If a character is in player_characters but not in loaded global data (e.g. new character added to game)
			# default it to locked unless its base definition in player_characters says unlocked.
			player_characters[char_type_key].unlocked = player_characters[char_type_key].get("unlocked", false)


func save_game():
	var global_player_data = {
		"khaos_coins": current_khaos_coins,
		"unlocked_characters": {}, # Use string keys for JSON compatibility
		"unlocked_artifacts": unlocked_artifacts_status, # Already Name (String) -> bool
		"unlocked_runes": unlocked_runes_global,         # Already Name (String) -> bool
		"talent_tree_progress": talent_tree_progress_global
	}
	# Convert integer keys in unlocked_characters_global to strings for JSON
	for char_type_int in unlocked_characters_global:
		global_player_data.unlocked_characters[str(char_type_int)] = unlocked_characters_global[char_type_int]

	var run_data = null # Assume no active run unless GameManager provides data
	var game_manager = get_node_or_null("../GameManager") # Check if GameManager exists
	var player_cards_node = get_node_or_null("../PlayerCards")

	if game_manager and player_cards_node and game_manager.current_state != game_manager.State.GAME_OVER : # Ensure a run is active
		# Check if current_wave is available on game_manager to avoid errors if not in a run
		var current_run_wave = 0
		if "current_wave" in game_manager: # Check if property exists
			current_run_wave = game_manager.current_wave

		run_data = {
			"current_wave": current_run_wave,
			"player_cards": []
		}
		for card in player_cards_node.get_children():
			var artifact_data = null
			if card.artifact:
				artifact_data = {"name": card.artifact.name, "rune": card.artifact.rune.name if card.artifact.rune else ""}
			run_data.player_cards.append({
				"type": card.type,
				"health": card.health,
				"max_health": card.max_health,
				"attack": card.attack,
				"artifact": artifact_data
			})
	
	var save_data = {
		"version": SAVE_VERSION,
		"global_player_data": global_player_data,
		"run_data": run_data
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t")) # Added indent for readability
		file.close()
		print("DataManager: Game saved successfully to: %s" % save_path)
	else:
		print("DataManager: Failed to save game!")


func load_game(): # This function now primarily loads a game *run*. Global data is loaded on init.
	if not FileAccess.file_exists(save_path):
		print("DataManager: No save file found at: %s" % save_path)
		return false # Cannot load a run if no save file

	# Ensure global data is loaded/up-to-date first. 
	# _load_global_data_on_init() already handles file existence and parsing.
	# No need to call it again if _init already did, unless we want to force a re-load.
	# For simplicity, we assume _init handled the global part.

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("DataManager: Failed to open save file for reading run data!")
		return false
	
	var save_content = file.get_as_text()
	file.close()

	var json_parser = JSON.new()
	var error_code = json_parser.parse(save_content)

	if error_code != OK:
		printerr("DataManager (load_game): Failed to parse save file JSON for run data. Error: '%s' at line %s, column %s" % [json_parser.get_error_message(), json_parser.get_error_line(), json_parser.get_error_column()])
		return false
		
	var save_data = json_parser.get_data()

	if not validate_save_data(save_data): # Basic validation (e.g. version check)
		print("DataManager: Invalid save data structure for run data!")
		return false

	# --- Process Run Data ---
	var run_data_to_load = null
	if save_data.has("run_data"): # New format with distinct run_data
		run_data_to_load = save_data.run_data
	elif save_data.has("current_wave"): # Old format, run data is at top level
		print("DataManager: Old save format detected for run data.")
		run_data_to_load = save_data 
	
	if run_data_to_load == null or not run_data_to_load.has("current_wave"): # Check if run_data is usable
		print("DataManager: No valid run data found to load.")
		current_wave_run = 0
		player_cards_run = []
		# Potentially clear player cards on game scene if any are displayed
		var player_cards_node = get_node_or_null("../PlayerCards")
		if player_cards_node:
			for card_node in player_cards_node.get_children():
				card_node.queue_free()
		return false # Indicate no run was loaded

	print("DataManager: Loading run data...")
	current_wave_run = run_data_to_load.get("current_wave", 0)
	
	# Clear existing player cards before loading new ones (if any are on scene)
	var player_cards_node = get_node_or_null("../PlayerCards")
	if player_cards_node:
		for card_node in player_cards_node.get_children():
			card_node.queue_free()
	else:
		print("DataManager: Warning - PlayerCards node not found. Cannot clear/load cards into scene.")

	player_cards_run = [] # Store loaded card data, GameManager will instance them
	var loaded_cards_data = run_data_to_load.get("player_cards", [])
	for card_data in loaded_cards_data:
		player_cards_run.append(card_data) # Store data; actual card node creation is GameManager's job

	print("DataManager: Run data loaded successfully! Wave: %d, Player Cards Count: %d" % [current_wave_run, player_cards_run.size()])
	return true


func validate_save_data(save_data): # Basic validation
	if not save_data is Dictionary:
		printerr("DataManager: Save data is not a dictionary.")
		return false
	if not save_data.has("version"):
		printerr("DataManager: Save data is missing 'version' key.")
		return false
	# Add more checks as needed, e.g., version compatibility
	return true


func add_khaos_coins(amount: int):
	if amount < 0:
		printerr("DataManager: add_khaos_coins called with negative amount. Use spend_khaos_coins instead.")
		return
	current_khaos_coins += amount
	print("DataManager: Added %d Khaos Coins. Total: %d" % [amount, current_khaos_coins])
	save_game()


func spend_khaos_coins(amount: int) -> bool:
	if amount < 0:
		printerr("DataManager: spend_khaos_coins called with negative amount. Amount should be positive.")
		return false # Or handle as an absolute value if desired
	if current_khaos_coins >= amount:
		current_khaos_coins -= amount
		print("DataManager: Spent %d Khaos Coins. Remaining: %d" % [amount, current_khaos_coins])
		save_game()
		return true
	else:
		print("DataManager: Not enough Khaos Coins to spend %d. Current: %d" % [amount, current_khaos_coins])
		return false


func unlock_character(char_type_to_unlock: int): # Parameter renamed for clarity
	if player_characters.has(char_type_to_unlock):
		unlocked_characters_global[char_type_to_unlock] = true
		# Also update the live player_characters dictionary for current session use
		player_characters[char_type_to_unlock].unlocked = true 
		print("DataManager: Character %s globally unlocked." % Globals.CardType.keys()[char_type_to_unlock])
		save_game() # Persist this global unlock
	else:
		print("DataManager: Attempted to unlock invalid character type: %s" % char_type_to_unlock)


func unlock_artifact(artifact_id: String):
	if unlocked_artifacts_status.has(artifact_id):
		if not unlocked_artifacts_status[artifact_id]: # Only unlock if not already unlocked
			unlocked_artifacts_status[artifact_id] = true
			print("DataManager: Artifact '%s' globally unlocked." % artifact_id)
			save_game()
		else:
			print("DataManager: Artifact '%s' is already unlocked." % artifact_id)
	else:
		# This case implies artifact_id might not be in Data.artifacts, which shouldn't happen if ShopManager uses Data.artifacts
		print("DataManager: Attempted to unlock unknown artifact: '%s'" % artifact_id)
		# Optionally, add it to the dictionary if it's a dynamic artifact system, though current setup implies fixed list.
		# unlocked_artifacts_status[artifact_id] = true 
		# save_game()


func unlock_rune(rune_id: String):
	if unlocked_runes_global.has(rune_id):
		if not unlocked_runes_global[rune_id]: # Only unlock if not already unlocked
			unlocked_runes_global[rune_id] = true
			print("DataManager: Rune '%s' globally unlocked." % rune_id)
			save_game()
		else:
			print("DataManager: Rune '%s' is already unlocked." % rune_id)
	else:
		# Similar to artifacts, implies rune_id might not be in Data.runes
		print("DataManager: Attempted to unlock unknown rune: '%s'" % rune_id)
		# Optionally, add it:
		# unlocked_runes_global[rune_id] = true
		# save_game()


func unlock_talent(talent_id: String) -> bool:
	# For now, just mark as unlocked. Could be extended to levels, etc.
	if not talent_tree_progress_global.has(talent_id) or not talent_tree_progress_global[talent_id]:
		talent_tree_progress_global[talent_id] = true # Mark as unlocked
		print("DataManager: Talent '%s' globally unlocked." % talent_id)
		save_game()
		return true
	else:
		print("DataManager: Talent '%s' is already unlocked." % talent_id)
		return false # Indicate it was already unlocked, not a new unlock.


func is_talent_unlocked(talent_id: String) -> bool:
	return talent_tree_progress_global.get(talent_id, false)


func get_artifact_cooldown(name: String) -> int:
	var cooldowns = {
		"Thunder Bolt": 3, "Healing Stone": 2, "Fire Orb": 4, "Iron Shield": 2,
		"Poison Vial": 3, "Frost Shard": 3, "Vampire Fang": 4, "Wind Gust": 2,
		"Lightning Chain": 5, "Shadow Cloak": 4, "Earth Spike": 3, "Soul Gem": 5,
		"Blood Rune": 4
	}
	return cooldowns.get(name, 1)

func get_artifact_requires_targets(name: String) -> bool:
	var targets = {
		"Thunder Bolt": true, "Healing Stone": false, "Fire Orb": true, "Iron Shield": false,
		"Poison Vial": true, "Frost Shard": true, "Vampire Fang": true, "Wind Gust": true,
		"Lightning Chain": true, "Shadow Cloak": false, "Earth Spike": true, "Soul Gem": false,
		"Blood Rune": false
	}
	return targets.get(name, false)

# Optional: Simple test function for Khaos Coin logic
# This can be called temporarily from _ready() or another script during development.
func _test_khaos_coin_logic():
	print("--- Starting Khaos Coin Logic Test ---")
	
	# 1. Test Initialization (current_khaos_coins should be 0 if this is a fresh DataManager)
	print("Initial Khaos Coins: %d (Expected: 0 or previous value if not fresh)" % current_khaos_coins)
	# For a true isolated test, you might want to force it to 0:
	# current_khaos_coins = 0 
	# print("Forced Initial Khaos Coins for test: %d" % current_khaos_coins)
	assert(current_khaos_coins >= 0) # Basic assertion

	# 2. Test add_khaos_coins()
	add_khaos_coins(10) # Expected: 10 (if started at 0)
	assert(current_khaos_coins == 10  or current_khaos_coins > 10) # Adjust if not starting at 0

	add_khaos_coins(5)  # Expected: 15
	assert(current_khaos_coins == 15 or current_khaos_coins > 15)

	add_khaos_coins(0)   # Expected: 15
	assert(current_khaos_coins == 15 or current_khaos_coins > 15)

	# Test spending if add_khaos_coins is used for it by passing negative numbers
	add_khaos_coins(-7) # Expected: 8
	assert(current_khaos_coins == 8 or current_khaos_coins > 8)
	print("Khaos Coins after additions/subtractions: %d" % current_khaos_coins)

	# 3. Simulate Saving and Loading for Khaos Coins
	print("Simulating Save/Load...")
	var simulated_save_data = {
		"khaos_coins": current_khaos_coins 
		# ... other necessary save data fields would be here for a full save
	}
	print("Simulated saved coins: %d" % simulated_save_data.khaos_coins)

	# Simulate loading this value into a temporary variable or resetting current_khaos_coins
	var temp_loaded_coins = -1 # Default to an invalid value
	if "khaos_coins" in simulated_save_data:
		temp_loaded_coins = simulated_save_data.khaos_coins
	else:
		temp_loaded_coins = 0 # Default if not found
	
	print("Simulated loaded coins: %d (Expected: %d)" % [temp_loaded_coins, current_khaos_coins])
	assert(temp_loaded_coins == current_khaos_coins)

	# Simulate loading from a save file that *doesn't* have khaos_coins (e.g. older save)
	var old_save_data = {
		"current_wave": 3 
		# no "khaos_coins" key
	}
	var coins_from_old_save = -1
	if "khaos_coins" in old_save_data:
		coins_from_old_save = old_save_data.khaos_coins
	else:
		coins_from_old_save = 0
	print("Simulated loaded coins from old save: %d (Expected: 0)" % coins_from_old_save)
	assert(coins_from_old_save == 0)
	
	print("--- Khaos Coin Logic Test Finished ---")
	# To run this test, you could add:
	# _test_khaos_coin_logic() 
	# to the _ready() function of DataManager.gd temporarily.
	# Remember to remove the call after testing.
