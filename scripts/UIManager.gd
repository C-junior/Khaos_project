# UIManager.gd
extends Node

var upgrade_points = 0
var current_tooltip = null
var khaos_coins_label: Label
var _dm_instance = null # Cache for DataManager instance

# Helper function to get DataManager instance with fallback and caching
func _get_dm_instance(context_msg: String = "") -> Object:
	if is_instance_valid(_dm_instance):
		# print("UIManager (%s): Reusing cached DataManager instance." % context_msg) # Optional
		return _dm_instance

	var dm = null
	if Engine.has_singleton("DataManager"):
		dm = DataManager
		# print("UIManager (%s): Accessed DataManager via Engine.has_singleton." % context_msg) # Optional
	else:
		print("UIManager (%s): Engine.has_singleton('DataManager') returned false. Attempting get_node_or_null('/root/DataManager')." % context_msg)
		dm = get_node_or_null("/root/DataManager")
		if is_instance_valid(dm):
			print("UIManager (%s): Accessed DataManager via get_node_or_null('/root/DataManager')." % context_msg)
		else:
			printerr("UIManager (%s): Failed to access DataManager via get_node_or_null('/root/DataManager') as well." % context_msg)
	
	if is_instance_valid(dm):
		_dm_instance = dm
	
	return dm


func _ready():
	# Create and add the label programmatically
	khaos_coins_label = Label.new()
	khaos_coins_label.name = "KhaosCoinsLabel"
	khaos_coins_label.text = "Khaos Coins: 0" 
	# Position it appropriately. Example:
	khaos_coins_label.position = Vector2(10, 30) # Adjust as needed. Assuming TurnLabel is at (10,10)
	add_child(khaos_coins_label)

	# Add Inventory Button
	var inventory_button = Button.new()
	inventory_button.name = "InventoryButton"
	inventory_button.text = "Inventory"
	inventory_button.position = Vector2(10, 60) # Adjust as needed
	inventory_button.pressed.connect(Callable(self, "_on_inventory_button_pressed"))
	add_child(inventory_button)

	# Attempt to get the Inventory node. This assumes Inventory.tscn is instanced in Main.tscn
	# and UIManager can access it, e.g. if UIManager is also a child of Main.tscn's root.
	# A more robust way would be to have GameManager or Main.gd manage this relationship.
	var inventory_node = get_node_or_null("../Inventory") # Adjust path if UIManager is not sibling to Inventory
	if inventory_node:
		inventory_node.inventory_closed.connect(Callable(self, "_on_inventory_closed"))


	_dm_instance = _get_dm_instance("_ready")

	# Fetch initial coins and update
	if is_instance_valid(_dm_instance):
		update_khaos_coins_label(_dm_instance.current_khaos_coins)
	else:
		# Fallback or error if DataManager isn't setup as expected
		printerr("UIManager: DataManager instance NOT VALID in _ready. Cannot set initial coin display.")
		update_khaos_coins_label(0) # Display 0 as a fallback


func update_khaos_coins_label(coins_amount: int):
	if khaos_coins_label:
		khaos_coins_label.text = "Khaos Coins: %d" % coins_amount
	else:
		print("KhaosCoinsLabel node not found.")

# Placeholder for ShopManager instance, if UIManager handles its instantiation or interaction.
# var shop_manager_instance = null

# func _ready():
	# ... existing _ready() code ...
	# TODO: Potentially add a "Shop" button to the UI here.
	# var shop_button = Button.new()
	# shop_button.text = "Open Shop"
	# shop_button.position = Vector2(10, 60) # Example position
	# add_child(shop_button)
	# shop_button.pressed.connect(Callable(self, "_on_open_shop_pressed"))

	# TODO: If UIManager instantiates ShopManager (alternative to GameManager doing it)
	# shop_manager_instance = load("res://scripts/ShopManager.gd").new()
	# shop_manager_instance.name = "ShopManager"
	# add_child(shop_manager_instance) # If it's a Node and needs to be in tree
	# var data_manager = get_node_or_null("../DataManager")
	# if shop_manager_instance and data_manager and shop_manager_instance.has_method("set_data_manager"):
	#     shop_manager_instance.set_data_manager(data_manager)


func display_shop_interface(player_khaos_coins: int):
	# TODO: Implement the actual shop UI display.
	# This would involve:
	# 1. Creating or showing a shop panel (e.g., get_node("../ShopPanel").show()).
	# 2. Populating the shop with items, possibly fetched from ShopManager.
	#    (e.g., var items = shop_manager_instance.get_shop_items())
	# 3. Displaying player's current Khaos Coins.
	# 4. Setting up buttons for purchasing items and connecting their signals.
	print("Placeholder: Displaying Shop Interface with %d Khaos Coins." % player_khaos_coins)
	# Example: get_node("../ShopPanel/PlayerCoinsLabel").text = "Your Coins: " + str(player_khaos_coins)
	# Example: get_node("../ShopPanel").show()
	# Example: get_node("../UpgradePanel").hide() # Hide upgrade panel if shop is separate


# func _on_open_shop_pressed():
	# TODO: This function would be called if a dedicated "Shop" button is added.
	# It could directly call display_shop_interface or notify GameManager to change state.
	# var game_manager = get_node_or_null("../GameManager")
	# if game_manager:
	#    if game_manager.has_method("enter_shop_phase"):
	#        game_manager.enter_shop_phase() # GameManager would then call display_shop_interface
	#    else:
	#        # Or UIManager handles it more directly if no dedicated game state
	#        var dm_local_check = _get_dm_instance("_on_open_shop_pressed") # Use helper
	#        if is_instance_valid(dm_local_check):
	#            display_shop_interface(dm_local_check.current_khaos_coins)
	#        else:
	#            printerr("UIManager: DataManager instance NOT VALID for _on_open_shop_pressed.")


func start_upgrade_phase():
	var game_manager = get_node_or_null("../GameManager") # GameManager might not be an autoload yet
	if not game_manager:
		printerr("UIManager: GameManager not found. Cannot start upgrade phase.")
		return
		
	# TODO: Consider if the shop should be accessible from/after the upgrade phase,
	# or if they are mutually exclusive.
	# If shop is accessible, a button could be added here to go to the shop.
	game_manager.current_state = game_manager.State.UPGRADE_PHASE
	# upgrade_points = 5 + game_manager.current_wave # Removed upgrade points system for now
	update_turn_label()
	
	var upgrade_panel_node = get_node_or_null("../UpgradePanel")
	if not upgrade_panel_node:
		printerr("UIManager: UpgradePanel node not found!")
		return
	upgrade_panel_node.show()
	
	# Assuming PointsLabel might be repurposed or hidden. For now, clear it.
	var points_label_node = get_node_or_null("../PointsLabel")
	if points_label_node:
		points_label_node.text = "Choose an Artifact"

	var upgrade_container = get_node_or_null("../UpgradePanel/UpgradeContainer")
	if not upgrade_container:
		printerr("UIManager: UpgradePanel/UpgradeContainer node not found!")
		return
		
	for child in upgrade_container.get_children():
		child.queue_free()

	# Get all artifact names from Data.gd
	var all_artifact_names = Data.artifacts.keys()
	all_artifact_names.shuffle() # Randomize the list

	# Display up to 3 artifacts
	var num_artifacts_to_display = min(all_artifact_names.size(), 3)
	var displayed_artifacts = all_artifact_names.slice(0, num_artifacts_to_display)

	if displayed_artifacts.is_empty():
		var no_artifacts_label = Label.new()
		no_artifacts_label.text = "No artifacts available to choose from."
		upgrade_container.add_child(no_artifacts_label)
	else:
		for artifact_name_str in displayed_artifacts:
			var artifact_data = Data.artifacts[artifact_name_str]

			var artifact_button_container = HBoxContainer.new() # To hold icon and button

			var artifact_icon = TextureRect.new()
			if artifact_data.has("icon") and not artifact_data.icon.is_empty():
				var tex = load(artifact_data.icon)
				if tex:
					artifact_icon.texture = tex
			artifact_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			artifact_icon.custom_minimum_size = Vector2(32, 32) # Increased icon size
			artifact_button_container.add_child(artifact_icon)

			var artifact_button = Button.new()
			# Display name and rarity. Tooltip shows full description.
			artifact_button.text = "%s (%s)" % [artifact_name_str, artifact_data.get("rarity", "N/A")]
			artifact_button.tooltip_text = artifact_data.get("tooltip", "No description available.")
			# The button's action will be to add the artifact to inventory and close the panel.
			artifact_button.pressed.connect(Callable(self, "_on_upgrade_artifact_selected").bind(artifact_name_str))
			
			# Hover for tooltip (using existing mechanism if still desired, but button tooltip_text is simpler)
			# artifact_button.mouse_entered.connect(Callable(self, "_on_artifact_data_hover").bind(artifact_data)) # Pass full data
			# artifact_button.mouse_exited.connect(Callable(self, "_on_hover_exit"))

			artifact_button_container.add_child(artifact_button)
			upgrade_container.add_child(artifact_button_container)

	# Add a "Skip" or "Continue" button if no artifact is chosen, or if all are chosen.
	# For now, selecting an artifact will be the primary way to continue.
	# If no artifacts were displayed, we need a continue button.
	if displayed_artifacts.is_empty():
		var continue_button_empty = Button.new()
		continue_button_empty.text = "Continue"
		continue_button_empty.pressed.connect(Callable(self, "_on_continue_after_upgrade"))
		upgrade_container.add_child(continue_button_empty)

	# Note: The old structure iterated player cards and showed complex options per card.
	# This is now simplified to a single choice of one artifact to add to inventory.
	# The _on_equip_artifact, _on_attach_rune, _on_upgrade_health, _on_upgrade_attack methods
	# will be removed or become obsolete with this change.

# Tooltip hover functions (modified for generic artifact data)
func _on_artifact_data_hover(artifact_definition: Dictionary):
	# This function is kept if detailed hover is preferred over button's native tooltip
	if current_tooltip:
		current_tooltip.queue_free()
	current_tooltip = load("res://Tooltip.tscn").instantiate() # Ensure Tooltip.tscn is available
	
	var icon_path = artifact_definition.get("icon", "")
	var name = artifact_definition.get("name", "Unknown Artifact") # Should come from key if artifact_definition is the value
	var tooltip_text = artifact_definition.get("tooltip", "No description.")
	var cooldown = artifact_definition.get("cooldown", 0)
	# var rarity = artifact_definition.get("rarity", "N/A") # Could add rarity to tooltip display

	# Assuming Tooltip.gd has a method like set_artifact_data or a more generic one
	if current_tooltip.has_method("set_artifact_data"):
		current_tooltip.set_artifact_data(icon_path, name, tooltip_text, cooldown)
	elif current_tooltip.has_method("set_data"): # Generic setter
		current_tooltip.set_data(name, tooltip_text, icon_path) # Example
	else: # Fallback or simple text
		current_tooltip.text = "%s\n%s\nCD: %d" % [name, tooltip_text, cooldown]

	get_tree().root.add_child(current_tooltip) # Add to root to ensure it's on top
	current_tooltip.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)


func _on_rune_hover(rune_name: String):
	if current_tooltip:
		current_tooltip.queue_free()
	current_tooltip = load("res://Tooltip.tscn").instantiate()
	current_tooltip.set_artifact_data(
		Data.artifacts[artifact.name]["icon"],
		artifact.name,
		Data.artifacts[artifact.name]["tooltip"],
		Data.artifacts[artifact.name]["cooldown"]
	)
	get_tree().root.add_child(current_tooltip)
	current_tooltip.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)

func _on_rune_hover(rune_name: String):
	if current_tooltip:
		current_tooltip.queue_free()
	current_tooltip = load("res://Tooltip.tscn").instantiate()
	current_tooltip.set_artifact_data(  # Using set_artifact_data for simplicity, adjust if needed
		Data.runes[rune_name]["icon"],
		rune_name,
		Data.runes[rune_name]["tooltip"],
		0  # Runes don’t have cooldowns in your setup, so set to 0
	)
	get_tree().root.add_child(current_tooltip)
	current_tooltip.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)

func _on_hover_exit():
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null

func _process(delta):
	if current_tooltip:
		current_tooltip.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)
		# Optional: Add screen edge detection
		var viewport_size = get_viewport().get_visible_rect().size
		var tooltip_size = current_tooltip.get_size()
		current_tooltip.global_position = current_tooltip.global_position.clamp(
			Vector2.ZERO,
			viewport_size - tooltip_size
		)

func _on_upgrade_artifact_selected(artifact_name_str: String):
	var dm = _get_dm_instance("_on_upgrade_artifact_selected")
	if not is_instance_valid(dm):
		printerr("UIManager: DataManager not found, cannot add artifact to inventory.")
		# Optionally, show an error to the player or just proceed without adding
		_on_continue_after_upgrade() # Proceed even if DM fails, artifact won't be added
		return

	if not dm.player_artifact_inventory.has(artifact_name_str):
		dm.player_artifact_inventory.append(artifact_name_str)
		print("UIManager: Added '%s' to player artifact inventory." % artifact_name_str)
		if dm.has_method("save_game"): # Ensure DataManager can save
			dm.save_game() # Save the change to inventory
	else:
		print("UIManager: Player already owns '%s'." % artifact_name_str)
		# Player might pick an artifact they already have from a previous round/choice.
		# This is fine, they just get another "copy" conceptually if inventory was list of instances.
		# Since inventory is list of names, this check prevents duplicates if that's desired behavior.
		# If duplicates are allowed (e.g. can have 3 Healing Stones), remove this check.
		# For now, let's assume unique names in inventory means one of each type.

	_on_continue_after_upgrade()


func _on_continue_after_upgrade():
	var upgrade_panel_node = get_node_or_null("../UpgradePanel")
	if upgrade_panel_node:
		upgrade_panel_node.hide()

	var game_manager = get_node_or_null("../GameManager") # Path might need adjustment
	if not game_manager:
		game_manager = get_node_or_null("/root/Main/GameManager") # Alternative path

	if game_manager:
		game_manager.current_wave += 1
		game_manager.start_wave()
	else:
		printerr("UIManager: GameManager not found. Cannot continue after upgrade.")
	
func show_temp_label(): # This function might be obsolete if there are no costs.
	var label = get_node("../NotEnoughLabel")
	label.show()
	
	# Create a timer that will timeout after 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	label.hide()
func update_turn_label():
	var game_manager = get_node_or_null("../GameManager")
	if not game_manager:
		printerr("UIManager: GameManager not found. Cannot update turn label.")
		if get_node_or_null("../TurnLabel"): # Check if label exists
			get_node("../TurnLabel").text = "Error: GM not found"
		return

	match game_manager.current_state:
		game_manager.State.PLAYER_TURN:
			get_node("../TurnLabel").text = "Player Turn"
		game_manager.State.ENEMY_TURN:
			get_node("../TurnLabel").text = "Enemy Turn"
		game_manager.State.UPGRADE_PHASE:
			get_node("../TurnLabel").text = "Upgrade Phase"
		# game_manager.State.SHOP_PHASE: # Uncomment if SHOP_PHASE state is added
			# get_node("../TurnLabel").text = "Khaos Shop"
		game_manager.State.GAME_OVER:
			get_node("../TurnLabel").text = "Game Over"

func update_wave_progress():
	var game_manager = get_node_or_null("../GameManager")
	var current_game_wave = 0
	if game_manager and "current_wave" in game_manager:
		current_game_wave = game_manager.current_wave
	elif game_manager: # current_wave might not exist if game_manager itself is from a different context
		printerr("UIManager: GameManager found, but current_wave property is missing.")
	else: # game_manager is null
		printerr("UIManager: GameManager not found. Cannot update wave progress.")

	var enemies_left = 0
	var enemy_cards_node = get_node_or_null("../EnemyCards")
	if enemy_cards_node:
		enemies_left = enemy_cards_node.get_children().size()
	else:
		printerr("UIManager: EnemyCards node not found. Cannot count enemies left.")

	if get_node_or_null("../WaveLabel"): # Check if label exists
		get_node("../WaveLabel").text = "Wave: %d (Enemies Left: %d)" % [current_game_wave + 1, enemies_left]


func _on_inventory_button_pressed():
	# Path to Inventory node might need adjustment depending on actual scene tree structure.
	# It's often better if a higher-level node (like Main.gd or GameManager) handles this.
	var inventory_node = get_node_or_null("../Inventory") # Example: if UIManager and Inventory are siblings
	if not inventory_node:
		inventory_node = get_node_or_null("/root/Main/Inventory") # Example: if Inventory is child of Main scene root

	if inventory_node and inventory_node.has_method("open_inventory"):
		var game_manager_node = get_node_or_null("../GameManager") # Example path
		if not game_manager_node:
			game_manager_node = get_node_or_null("/root/Main/GameManager") # Example path for GM

		var data_manager_node = _get_dm_instance("_on_inventory_button_pressed") # Use helper to get DM

		if game_manager_node and data_manager_node:
			# Pass GameManager and DataManager references to the inventory
			inventory_node.setup_inventory(game_manager_node, data_manager_node)
			inventory_node.open_inventory()
			# Optionally, pause the game or disable other UI elements
			# get_tree().paused = true
		else:
			printerr("UIManager: Failed to get GameManager or DataManager for Inventory setup.")
	else:
		printerr("UIManager: Inventory node not found or doesn't have open_inventory method.")

func _on_inventory_closed():
	# Handle anything that needs to happen when inventory is closed
	print("UIManager: Inventory closed signal received.")
	# if get_tree().paused:
		# get_tree().paused = false # Resume game if it was paused
