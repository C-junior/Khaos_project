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
	upgrade_points = 5 + game_manager.current_wave
	update_turn_label()
	get_node("../UpgradePanel").show()
	get_node("../PointsLabel").text = "Points: " + str(upgrade_points)
	
	var upgrade_container = get_node("../UpgradePanel/UpgradeContainer")
	for child in upgrade_container.get_children():
		child.queue_free()
	
	var available_artifacts = []
	for artifact_name in Data.artifacts.keys():
		var should_unlock = true
		# Ensure game_manager is valid before accessing current_wave
		var current_game_wave = 0
		if game_manager and "current_wave" in game_manager: # Check property exists too
			current_game_wave = game_manager.current_wave

		if artifact_name == "Shadow Cloak" and current_game_wave < 3:
			should_unlock = false
		elif artifact_name == "Earth Spike" and current_game_wave < 6:
			should_unlock = false
		elif artifact_name == "Soul Gem" and current_game_wave < 9:
			should_unlock = false
		elif artifact_name == "Blood Rune" and current_game_wave < 12:
			should_unlock = false
		if should_unlock:
			available_artifacts.append({"name": artifact_name, "cost": Data.artifacts[artifact_name]["cost"]})
	
	available_artifacts.shuffle()
	var displayed_artifacts = available_artifacts.slice(0, 4)

	for card in get_node("../PlayerCards").get_children():
		var card_section = VBoxContainer.new()
		var label = Label.new()
		label.text = "Card (%s)" % card.name
		card_section.add_child(label)
		
		var health_button = Button.new()
		health_button.text = "Upgrade Health (+1)"
		health_button.pressed.connect(Callable(self, "_on_upgrade_health").bind(card))
		card_section.add_child(health_button)
		
		var attack_button = Button.new()
		attack_button.text = "Upgrade Attack (+1)"
		attack_button.pressed.connect(Callable(self, "_on_upgrade_attack").bind(card))
		card_section.add_child(attack_button)
		
		var artifact_label = Label.new()
		artifact_label.text = "Artifact: %s" % (card.artifact.name if card.artifact else "None")
		card_section.add_child(artifact_label)
		
		for artifact in displayed_artifacts:
			var artifact_container = HBoxContainer.new()
			var artifact_icon = TextureRect.new()
			artifact_icon.texture = load(Data.artifacts[artifact.name]["icon"])
			artifact_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			artifact_icon.custom_minimum_size = Vector2(24, 24)
			artifact_container.add_child(artifact_icon)
			
			var artifact_button = Button.new()
			artifact_button.text = "Equip %s (%d pts)" % [artifact.name, artifact.cost]
			artifact_button.pressed.connect(Callable(self, "_on_equip_artifact").bind(card, artifact.name, artifact.cost))
			# Add hover signals
			artifact_button.connect("mouse_entered", Callable(self, "_on_artifact_hover").bind(artifact))
			artifact_button.connect("mouse_exited", Callable(self, "_on_hover_exit"))
			artifact_container.add_child(artifact_button)
			
			card_section.add_child(artifact_container)
		
		if card.artifact:
			var rune_label = Label.new()
			rune_label.text = "Rune: %s" % (card.artifact.rune.name if card.artifact.rune else "None")
			card_section.add_child(rune_label)
			for rune_name in Data.runes.keys():
				var rune_container = HBoxContainer.new()
				var rune_icon = TextureRect.new()
				rune_icon.texture = load(Data.runes[rune_name]["icon"])
				rune_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				rune_icon.custom_minimum_size = Vector2(24, 24)
				rune_container.add_child(rune_icon)
				
				var rune_button = Button.new()
				rune_button.text = "Attach %s (%d pts)" % [rune_name, Data.runes[rune_name]["cost"]]
				rune_button.pressed.connect(Callable(self, "_on_attach_rune").bind(card, rune_name, Data.runes[rune_name]["cost"]))
				# Add hover signals
				rune_button.connect("mouse_entered", Callable(self, "_on_rune_hover").bind(rune_name))
				rune_button.connect("mouse_exited", Callable(self, "_on_hover_exit"))
				rune_container.add_child(rune_button)
				
				card_section.add_child(rune_container)
		
		upgrade_container.add_child(card_section)
	
	var continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.pressed.connect(Callable(self, "_on_continue"))
	upgrade_container.add_child(continue_button)

# Tooltip hover functions
func _on_artifact_hover(artifact):
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
		
func _on_upgrade_health(card):
	if upgrade_points >= Data.health_upgrade_cost:
		card.health += 1
		card.max_health += 1
		upgrade_points -= Data.health_upgrade_cost
		get_node("../PointsLabel").text = "Points: " + str(upgrade_points)
		card.update_labels()

func _on_upgrade_attack(card):
	if upgrade_points >= Data.attack_upgrade_cost:
		card.attack += 1
		upgrade_points -= Data.attack_upgrade_cost
		get_node("../PointsLabel").text = "Points: " + str(upgrade_points)
		card.update_labels()

func _on_equip_artifact(card, artifact_name: String, cost: int):
	if upgrade_points >= cost:
		card.artifact = Artifact.new(
			artifact_name,
			Data.artifacts[artifact_name]["ability"],
			Data.get_artifact_cooldown(artifact_name),
			Data.get_artifact_requires_targets(artifact_name)
		)
		upgrade_points -= cost
		get_node("../PointsLabel").text = "Points: " + str(upgrade_points)
		card.update_labels()
	else:
		show_temp_label()
		#start_upgrade_phase()

func _on_attach_rune(card, rune_name: String, cost: int):
	if upgrade_points >= cost and card.artifact and not card.artifact.rune:
		card.artifact.attach_rune(Rune.new(rune_name, Data.runes[rune_name]["ability"]))
		upgrade_points -= cost
		get_node("../PointsLabel").text = "Points: " + str(upgrade_points)
		card.update_labels()
		#start_upgrade_phase()

func _on_continue():
	get_node("../UpgradePanel").hide()
	var game_manager = get_node_or_null("../GameManager")
	if game_manager:
		game_manager.current_wave += 1
		game_manager.start_wave()
	else:
		printerr("UIManager: GameManager not found. Cannot continue.")
	
func show_temp_label():
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
