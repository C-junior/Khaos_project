# ShopManager.gd
extends Node

var _dm_cache = null # Cache for DataManager instance

# Helper function to get DataManager instance with fallback and caching
func _get_dm_instance(context_msg: String):
	if is_instance_valid(_dm_cache):
		# print("ShopManager (%s): Reusing cached DataManager instance." % context_msg) # Optional: can be verbose
		return _dm_cache

	var dm_instance = null
	if Engine.has_singleton("DataManager"):
		dm_instance = DataManager
		print("ShopManager (%s): Accessed DataManager via Engine.has_singleton." % context_msg)
	else:
		print("ShopManager (%s): Engine.has_singleton('DataManager') returned false. Attempting get_node_or_null('/root/DataManager')." % context_msg)
		dm_instance = get_node_or_null("/root/DataManager")
		if is_instance_valid(dm_instance):
			print("ShopManager (%s): Accessed DataManager via get_node_or_null('/root/DataManager')." % context_msg)
		else:
			print("ShopManager (%s): Failed to access DataManager via get_node_or_null('/root/DataManager') as well." % context_msg)
	
	if is_instance_valid(dm_instance):
		_dm_cache = dm_instance # Cache the successfully obtained instance
	
	return dm_instance


# Define item categories as constants for easier use
const TYPE_CHARACTER = "character"
const TYPE_ARTIFACT = "artifact"
const TYPE_RUNE = "rune"
const TYPE_TALENT = "talent" # New category for talents

# Shop item definitions
# IDs for characters are their Globals.CardType enum value
# IDs for artifacts and runes are their string names (from Data.gd)
var shop_item_definitions = {
	TYPE_CHARACTER: {
		Globals.CardType.ARCHER: {"id": Globals.CardType.ARCHER, "name": "Archer", "type": TYPE_CHARACTER, "cost": 100, "description": "Unlocks the Archer: +15% damage per consecutive hit (max 45%)."},
		Globals.CardType.CLERIC: {"id": Globals.CardType.CLERIC, "name": "Cleric", "type": TYPE_CHARACTER, "cost": 100, "description": "Unlocks the Cleric: Heal allies below 25% HP."},
		Globals.CardType.ASSASSIN: {"id": Globals.CardType.ASSASSIN, "name": "Assassin", "type": TYPE_CHARACTER, "cost": 120, "description": "Unlocks the Assassin: +50% damage if target at full HP."},
		Globals.CardType.BERSERKER: {"id": Globals.CardType.BERSERKER, "name": "Berserker", "type": TYPE_CHARACTER, "cost": 150, "description": "Unlocks the Berserker: +20% attack per 25% HP lost."},
		Globals.CardType.NECRODANCER: {"id": Globals.CardType.NECRODANCER, "name": "Necrodancer", "type": TYPE_CHARACTER, "cost": 150, "description": "Unlocks the Necrodancer: Reduce cooldowns when enemies die."},
		Globals.CardType.GUARDIAN: {"id": Globals.CardType.GUARDIAN, "name": "Guardian", "type": TYPE_CHARACTER, "cost": 150, "description": "Unlocks the Guardian: 25% less damage above 50% HP, 25% weaker attacks."}
	},
	TYPE_ARTIFACT: {
		# Example artifacts - ideally these would loop through Data.artifacts if costs are uniform or defined there
		"Thunder Bolt": {"id": "Thunder Bolt", "name": "Thunder Bolt", "type": TYPE_ARTIFACT, "cost": 30, "description": "Unlocks the Thunder Bolt artifact."},
		"Healing Stone": {"id": "Healing Stone", "name": "Healing Stone", "type": TYPE_ARTIFACT, "cost": 40, "description": "Unlocks the Healing Stone artifact."},
		"Fire Orb": {"id": "Fire Orb", "name": "Fire Orb", "type": TYPE_ARTIFACT, "cost": 25, "description": "Unlocks the Fire Orb artifact."},
		"Iron Shield": {"id": "Iron Shield", "name": "Iron Shield", "type": TYPE_ARTIFACT, "cost": 20, "description": "Unlocks the Iron Shield artifact."}
		# TODO: Populate with more artifacts from Data.artifacts and assign costs
	},
	TYPE_RUNE: {
		# Example runes - ideally loop through Data.runes
		"Swiftness Rune": {"id": "Swiftness Rune", "name": "Swiftness Rune", "type": TYPE_RUNE, "cost": 35, "description": "Unlocks the Swiftness Rune."},
		"Might Rune": {"id": "Might Rune", "name": "Might Rune", "type": TYPE_RUNE, "cost": 45, "description": "Unlocks the Might Rune."}
		# TODO: Populate with more runes from Data.runes and assign costs
	},
	TYPE_TALENT: {
		"base_hp_up_1": {
			"id": "base_hp_up_1", "name": "Vitality Boost I", "type": TYPE_TALENT, "cost": 20, 
			"description": "+5 Max HP to all characters (effect not implemented).", 
			"prerequisites": []
		},
		"base_atk_up_1": {
			"id": "base_atk_up_1", "name": "Strength Surge I", "type": TYPE_TALENT, "cost": 30, 
			"description": "+1 Base Attack to all characters (effect not implemented).", 
			"prerequisites": ["base_hp_up_1"] # Example: Requires Vitality Boost I
		},
		"khaos_coin_gain_1": {
			"id": "khaos_coin_gain_1", "name": "Khaos Affinity I", "type": TYPE_TALENT, "cost": 50,
			"description": "Gain 10% more Khaos Coins from wave clears (effect not implemented).",
			"prerequisites": []
		}
		# TODO: Define more talents
	}
}


func _ready():
	_dm_cache = _get_dm_instance("_ready") # Populate cache on ready
	if not is_instance_valid(_dm_cache):
		printerr("ShopManager: DataManager instance NOT VALID in _ready! Shop may not function correctly.")
	
	# _populate_dynamic_shop_items still uses global Data. Autoload order for Data should be fine.
	_populate_dynamic_shop_items()

func _populate_dynamic_shop_items():
	if not Data.artifacts or not Data.runes:
		printerr("ShopManager: Data.artifacts or Data.runes not available for dynamic population.")
		return

	var default_artifact_cost = 25
	for artifact_id in Data.artifacts:
		if not shop_item_definitions[TYPE_ARTIFACT].has(artifact_id):
			shop_item_definitions[TYPE_ARTIFACT][artifact_id] = {
				"id": artifact_id, 
				"name": artifact_id, # Assuming name is the ID from Data.gd
				"type": TYPE_ARTIFACT, 
				"cost": Data.artifacts[artifact_id].get("cost", default_artifact_cost), # Use cost from Data.gd if available
				"description": "Unlocks the %s artifact." % artifact_id
			}

	var default_rune_cost = 20
	for rune_id in Data.runes:
		if not shop_item_definitions[TYPE_RUNE].has(rune_id):
			shop_item_definitions[TYPE_RUNE][rune_id] = {
				"id": rune_id, 
				"name": rune_id, # Assuming name is the ID from Data.gd
				"type": TYPE_RUNE, 
				"cost": Data.runes[rune_id].get("cost", default_rune_cost), # Use cost from Data.gd if available
				"description": "Unlocks the %s rune." % rune_id
			}

func get_unlockable_items(item_type: String) -> Array:
	var dm_instance = _get_dm_instance("get_unlockable_items")
	if not is_instance_valid(dm_instance):
		printerr("ShopManager: DataManager instance NOT VALID for get_unlockable_items.")
		return []
	
	if not shop_item_definitions.has(item_type):
		printerr("ShopManager: Unknown item type requested: %s" % item_type)
		return []

	var available_items = []
	var all_items_of_type = shop_item_definitions[item_type]

	for item_id in all_items_of_type:
		var item_data = all_items_of_type[item_id]
		var is_unlocked = false
		match item_type:
			TYPE_CHARACTER:
				# item_id for characters is an int (Globals.CardType)
				is_unlocked = dm_instance.unlocked_characters_global.get(item_id, false)
			TYPE_ARTIFACT:
				# item_id for artifacts is a String
				is_unlocked = dm_instance.unlocked_artifacts_status.get(item_id, false)
			TYPE_RUNE:
				# item_id for runes is a String
				is_unlocked = dm_instance.unlocked_runes_global.get(item_id, false)
			TYPE_TALENT:
				# item_id for talents is a String
				is_unlocked = dm_instance.is_talent_unlocked(item_id)
				# TODO: Implement prerequisite check here
				# if not _are_prerequisites_met(dm_instance, item_data.get("prerequisites", [])): # Pass dm_instance
				#     continue # Skip if prerequisites not met
		
		if not is_unlocked:
			available_items.append(item_data)
			
	return available_items


# Placeholder for prerequisite check logic (updated to accept dm_instance)
# func _are_prerequisites_met(dm_instance_local, prereq_list: Array) -> bool:
#   if not is_instance_valid(dm_instance_local): return false
#   for prereq_id in prereq_list:
#       if not dm_instance_local.is_talent_unlocked(prereq_id):
#           return false
#   return true


func purchase_unlock(item_id, item_type: String) -> bool: 
	var dm_instance = _get_dm_instance("purchase_unlock")
	if not is_instance_valid(dm_instance):
		printerr("ShopManager: DataManager instance NOT VALID for purchase_unlock.")
		return false

	if not shop_item_definitions.has(item_type) or not shop_item_definitions[item_type].has(item_id):
		printerr("ShopManager: Invalid item_id '%s' or item_type '%s' for purchase." % [item_id, item_type])
		return false

	var item_data = shop_item_definitions[item_type][item_id]
	var cost = item_data.cost

	# TODO: For talents, check prerequisites before purchase attempt
	# if item_type == TYPE_TALENT:
	#     if not _are_prerequisites_met(dm_instance, item_data.get("prerequisites", [])): # Pass dm_instance
	#         print("ShopManager: Cannot purchase talent '%s', prerequisites not met." % item_data.name)
	#         return false

	if dm_instance.current_khaos_coins >= cost:
		if dm_instance.spend_khaos_coins(cost): # spend_khaos_coins now returns bool and saves
			var unlock_successful = false
			match item_type:
				TYPE_CHARACTER:
					dm_instance.unlock_character(item_id) 
					unlock_successful = true 
				TYPE_ARTIFACT:
					dm_instance.unlock_artifact(item_id) 
					unlock_successful = true
				TYPE_RUNE:
					dm_instance.unlock_rune(item_id) 
					unlock_successful = true
				TYPE_TALENT:
					unlock_successful = dm_instance.unlock_talent(item_id) # unlock_talent returns bool
			
			if unlock_successful:
				print("ShopManager: Successfully purchased and unlocked '%s' (%s)." % [item_data.name, item_type])
				return true
			else:
				# This case should ideally not be reached if unlock functions in DataManager are robust
				# and spend_khaos_coins succeeded. Consider if refund is needed.
				printerr("ShopManager: Purchase failed because unlock step failed for '%s'." % item_data.name)
				# Refunding coins as unlock failed after spending
				dm_instance.add_khaos_coins(cost) # Add back if unlock failed post-spend
				print("ShopManager: Refunded %d Khaos Coins due to unlock failure." % cost)
				return false
		else:
			# This case implies spend_khaos_coins itself failed, though it should only fail if not enough coins,
			# which we check above. This could be a redundant check or for future failure modes in spend_khaos_coins.
			print("ShopManager: Purchase failed for '%s' because spending coins failed." % item_data.name)
			return false
	else:
		print("ShopManager: Not enough Khaos Coins to purchase '%s'." % item_data.name)
		return false

# Helper to get item details, e.g., for UI
func get_item_details(item_id, item_type: String) -> Dictionary:
	if shop_item_definitions.has(item_type) and shop_item_definitions[item_type].has(item_id):
		return shop_item_definitions[item_type][item_id]
	return {}
