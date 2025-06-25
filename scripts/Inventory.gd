extends Control

# Signals
signal inventory_closed
signal artifact_equipped(character_card, artifact_name, slot_index) # slot_index could be 0 or 1
signal artifact_unequipped(character_card, artifact_instance, slot_index)

# UI References
@onready var character_list_container: VBoxContainer = %CharacterList
@onready var artifact_inventory_list_container: VBoxContainer = %ArtifactInventoryList
@onready var equipped_artifacts_list_container: HBoxContainer = %EquippedArtifactsList
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton # More specific path

# Game State References
var game_manager # Set by whatever opens this inventory
var data_manager # Set by whatever opens this inventory

var player_cards_nodes: Array = [] # Array of CardBase nodes
var selected_character_card: CardBase = null

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	hide() # Hidden by default

func setup_inventory(gm, dm):
	game_manager = gm
	data_manager = dm
	# Assuming game_manager has a way to get player card nodes
	# This might need adjustment based on where player card nodes are actually stored/managed
	if game_manager and game_manager.has_node("PlayerCards"): # Example path
		player_cards_nodes = game_manager.get_node("PlayerCards").get_children()
	elif game_manager and game_manager.get_parent().has_node("PlayerCards"): # Another common pattern
		player_cards_nodes = game_manager.get_parent().get_node("PlayerCards").get_children()
	else:
		printerr("Inventory.gd: Could not find PlayerCards node via GameManager.")
		player_cards_nodes = []

	populate_character_list()
	populate_artifact_inventory_list()
	update_equipped_artifacts_display() # Initial update for no selected char

func populate_character_list():
	if not is_instance_valid(character_list_container):
		printerr("Inventory.gd: CharacterList container is not valid.")
		return

	for child in character_list_container.get_children():
		child.queue_free()

	for card_node in player_cards_nodes:
		if not is_instance_valid(card_node): continue

		var char_button = Button.new()
		char_button.text = card_node.text # Card's name or type
		char_button.pressed.connect(Callable(self, "_on_character_selected").bind(card_node))
		character_list_container.add_child(char_button)

func _on_character_selected(card_node: CardBase):
	selected_character_card = card_node
	print("Selected character: ", selected_character_card.text)
	update_equipped_artifacts_display()
	populate_artifact_inventory_list() # Refresh to enable/disable equip buttons based on selection

func populate_artifact_inventory_list():
	if not is_instance_valid(data_manager) or not is_instance_valid(artifact_inventory_list_container):
		printerr("Inventory.gd: DataManager or ArtifactInventoryList container is not valid.")
		return

	for child in artifact_inventory_list_container.get_children():
		child.queue_free()

	var owned_artifact_names: Array = data_manager.player_artifact_inventory

	if owned_artifact_names.is_empty():
		var label = Label.new()
		label.text = "No artifacts in inventory."
		artifact_inventory_list_container.add_child(label)
		return

	for artifact_name_str in owned_artifact_names:
		var artifact_data = Data.artifacts.get(artifact_name_str)
		if not artifact_data:
			printerr("Inventory.gd: Artifact data not found for '%s'" % artifact_name_str)
			continue

		var item_hbox = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = "%s (%s)" % [artifact_name_str, artifact_data.get("rarity", "N/A")]
		name_label.tooltip_text = artifact_data.get("tooltip", "No tooltip.")
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_hbox.add_child(name_label)

		var equip_button = Button.new()
		equip_button.text = "Equip"
		if not selected_character_card or selected_character_card.artifacts.size() >= selected_character_card.max_artifacts:
			equip_button.disabled = true # Disable if no char selected or char has max artifacts

		equip_button.pressed.connect(Callable(self, "_on_equip_artifact_pressed").bind(artifact_name_str))
		item_hbox.add_child(equip_button)

		artifact_inventory_list_container.add_child(item_hbox)

func _on_equip_artifact_pressed(artifact_name_to_equip: String):
	if not selected_character_card:
		print("No character selected to equip artifact.")
		return

	if selected_character_card.artifacts.size() >= selected_character_card.max_artifacts:
		print("%s cannot equip more artifacts." % selected_character_card.text)
		return

	if data_manager.player_artifact_inventory.has(artifact_name_to_equip):
		# 1. Remove from DataManager inventory
		data_manager.player_artifact_inventory.erase(artifact_name_to_equip)

		# 2. Create artifact instance
		var new_artifact_instance = ArtifactFactory.create_artifact(artifact_name_to_equip)
		if not new_artifact_instance:
			printerr("Inventory.gd: Failed to create artifact instance for '%s'" % artifact_name_to_equip)
			# Attempt to add it back to inventory to prevent loss
			data_manager.player_artifact_inventory.append(artifact_name_to_equip)
			return

		# 3. Add to character's artifacts array
		selected_character_card.artifacts.append(new_artifact_instance)

		# 4. Persist changes
		if is_instance_valid(data_manager) and data_manager.has_method("save_game"):
			data_manager.save_game()

		# 5. Update UI
		populate_artifact_inventory_list()
		update_equipped_artifacts_display()

		emit_signal("artifact_equipped", selected_character_card, artifact_name_to_equip, selected_character_card.artifacts.size() - 1)
		print("Equipped %s on %s" % [artifact_name_to_equip, selected_character_card.text])
	else:
		printerr("Inventory.gd: Artifact '%s' not found in player inventory for equipping." % artifact_name_to_equip)


func update_equipped_artifacts_display():
	if not is_instance_valid(equipped_artifacts_list_container):
		printerr("Inventory.gd: EquippedArtifactsList container is not valid.")
		return

	for child in equipped_artifacts_list_container.get_children():
		child.queue_free()

	if not selected_character_card:
		var label = Label.new()
		label.text = "Select a character to see equipped artifacts."
		equipped_artifacts_list_container.add_child(label)
		return

	if selected_character_card.artifacts.is_empty():
		var label = Label.new()
		label.text = "No artifacts equipped."
		equipped_artifacts_list_container.add_child(label)
	else:
		for i in range(selected_character_card.artifacts.size()):
			var artifact_instance = selected_character_card.artifacts[i]
			if not is_instance_valid(artifact_instance): continue

			var artifact_box = VBoxContainer.new() # Display name and unequip button vertically
			artifact_box.custom_minimum_size = Vector2(150, 0) # Give some width
			artifact_box.alignment = BoxContainer.ALIGNMENT_CENTER

			var name_label = Label.new()
			name_label.text = artifact_instance.name
			name_label.horizontal_alignment = Label.HORIZONTAL_ALIGNMENT_CENTER
			artifact_box.add_child(name_label)

			var rune_label_text = "Rune: None"
			if artifact_instance.rune:
				rune_label_text = "Rune: %s" % artifact_instance.rune.name
			var rune_label = Label.new()
			rune_label.text = rune_label_text
			rune_label.horizontal_alignment = Label.HORIZONTAL_ALIGNMENT_CENTER
			artifact_box.add_child(rune_label)

			var unequip_button = Button.new()
			unequip_button.text = "Unequip"
			unequip_button.pressed.connect(Callable(self, "_on_unequip_artifact_pressed").bind(artifact_instance, i))
			artifact_box.add_child(unequip_button)

			if not artifact_instance.rune: # Only show attach button if no rune is attached
				var attach_rune_button = Button.new()
				attach_rune_button.text = "Attach Rune"
				# Disable if no character selected or no artifact instance valid (already checked by context)
				# or if DataManager/Data.runes is not available.
				if not is_instance_valid(data_manager) or Data.runes.is_empty():
					attach_rune_button.disabled = true
					attach_rune_button.tooltip_text = "No runes available or DataManager error."
				else:
					# Check if there are any actually unlocked runes to attach
					var has_available_runes = false
					for rune_id_key in Data.runes.keys():
						if data_manager.unlocked_runes_global.get(rune_id_key, false):
							has_available_runes = true
							break
					if not has_available_runes:
						attach_rune_button.disabled = true
						attach_rune_button.tooltip_text = "No runes unlocked to attach."

				attach_rune_button.pressed.connect(Callable(self, "_on_attach_rune_pressed").bind(artifact_instance, i))
				artifact_box.add_child(attach_rune_button)

			equipped_artifacts_list_container.add_child(artifact_box)

	# Add placeholders if less than max_artifacts are equipped
	var placeholders_to_add = selected_character_card.max_artifacts - selected_character_card.artifacts.size()
	for _i in range(placeholders_to_add):
		var placeholder_label = Label.new()
		placeholder_label.text = "[Empty Slot]"
		placeholder_label.custom_minimum_size = Vector2(150,50)
		placeholder_label.horizontal_alignment = Label.HORIZONTAL_ALIGNMENT_CENTER
		placeholder_label.vertical_alignment = Label.VERTICAL_ALIGNMENT_CENTER

		var panel = PanelContainer.new() # To give it some visual boundary
		panel.add_child(placeholder_label)
		equipped_artifacts_list_container.add_child(panel)


func _on_unequip_artifact_pressed(artifact_instance_to_unequip: Artifact, slot_index: int):
	if not selected_character_card:
		printerr("Inventory.gd: No character selected for unequipping.")
		return

	if not selected_character_card.artifacts.has(artifact_instance_to_unequip):
		printerr("Inventory.gd: Artifact instance not found on selected character.")
		return

	# 1. Add back to DataManager inventory
	data_manager.player_artifact_inventory.append(artifact_instance_to_unequip.name)

	# 2. Remove from character's artifacts array
	selected_character_card.artifacts.erase(artifact_instance_to_unequip)

	# 3. Persist changes
	if is_instance_valid(data_manager) and data_manager.has_method("save_game"):
		data_manager.save_game()

	# 4. Update UI
	populate_artifact_inventory_list()
	update_equipped_artifacts_display()

	emit_signal("artifact_unequipped", selected_character_card, artifact_instance_to_unequip, slot_index)
	print("Unequipped %s from %s" % [artifact_instance_to_unequip.name, selected_character_card.text])

var rune_selection_popup: PanelContainer = null
var current_artifact_for_rune: Artifact = null

func _on_attach_rune_pressed(artifact_instance: Artifact, _slot_index: int):
	print("Attempting to attach rune to: ", artifact_instance.name)
	current_artifact_for_rune = artifact_instance # Store which artifact we are working with

	if not is_instance_valid(data_manager):
		printerr("Inventory.gd: DataManager not valid for rune attachment.")
		return

	if rune_selection_popup and is_instance_valid(rune_selection_popup):
		rune_selection_popup.queue_free() # Remove old one if exists

	rune_selection_popup = PanelContainer.new()
	rune_selection_popup.custom_minimum_size = Vector2(300, 200)
	rune_selection_popup.set_anchors_preset(Control.PRESET_CENTER)
	# Style it a bit
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_width_left = 1; style.border_width_right = 1; style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color.GRAY
	rune_selection_popup.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	rune_selection_popup.add_child(margin)

	var vbox = VBoxContainer.new()
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Select a Rune for %s" % artifact_instance.name
	title.horizontal_alignment = Label.HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var rune_list_vbox = VBoxContainer.new()
	scroll.add_child(rune_list_vbox)

	var available_runes_found = false
	for rune_name_str in Data.runes.keys():
		# Check if rune is globally unlocked by player
		if data_manager.unlocked_runes_global.get(rune_name_str, false):
			available_runes_found = true
			var rune_data = Data.runes[rune_name_str]
			var rune_button = Button.new()
			rune_button.text = "%s (Cost: %d)" % [rune_name_str, rune_data.get("cost", 0)] # Assuming cost is still relevant for selection, or remove
			rune_button.tooltip_text = rune_data.get("tooltip", "No description.")
			rune_button.pressed.connect(Callable(self, "_on_rune_selected_for_attachment").bind(rune_name_str))
			rune_list_vbox.add_child(rune_button)

	if not available_runes_found:
		var no_runes_label = Label.new()
		no_runes_label.text = "No unlocked runes available."
		rune_list_vbox.add_child(no_runes_label)

	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(Callable(rune_selection_popup, "queue_free")) # Simple cancel
	vbox.add_child(cancel_button)

	add_child(rune_selection_popup) # Add popup to the inventory screen
	rune_selection_popup.popup_centered() # Godot 3.x way, or just show() and rely on anchors for Godot 4.x
	# For Godot 4, just ensure it's visible:
	# rune_selection_popup.show()


func _on_rune_selected_for_attachment(rune_name_to_attach: String):
	if not is_instance_valid(current_artifact_for_rune):
		printerr("Inventory.gd: current_artifact_for_rune is not valid.")
		if rune_selection_popup and is_instance_valid(rune_selection_popup):
			rune_selection_popup.queue_free()
		return

	var rune_cost = Data.runes[rune_name_to_attach].get("cost", 0)
	# Assuming rune attachment might have a cost (e.g. Khaos Coins or a different currency)
	# For now, let's assume it's free or cost is handled elsewhere (like shop unlock)
	# If there was a cost from DataManager:
	# if data_manager.current_khaos_coins < rune_cost:
	#     print("Not enough coins to attach rune %s" % rune_name_to_attach)
	#     # Optionally show feedback to player
	#     if rune_selection_popup and is_instance_valid(rune_selection_popup):
	#         rune_selection_popup.queue_free()
	#     return

	# data_manager.spend_khaos_coins(rune_cost) # If there was a cost

	var success = ArtifactFactory.attach_rune_to_artifact(current_artifact_for_rune, rune_name_to_attach)

	if success:
		print("Successfully attached rune %s to %s" % [rune_name_to_attach, current_artifact_for_rune.name])
		if is_instance_valid(data_manager) and data_manager.has_method("save_game"):
			data_manager.save_game() # Save the game state as artifact has changed
	else:
		printerr("Inventory.gd: Failed to attach rune %s to %s via ArtifactFactory." % [rune_name_to_attach, current_artifact_for_rune.name])
		# If cost was deducted, would need to refund here.

	if rune_selection_popup and is_instance_valid(rune_selection_popup):
		rune_selection_popup.queue_free()

	update_equipped_artifacts_display() # Refresh the display to show the new rune or lack thereof


func open_inventory():
	# Ensure DataManager and GameManager references are fresh if this UI can be closed and reopened.
	# This might be better handled by the node that calls open_inventory().
	# For now, assume they are set correctly by an external manager.
	if not is_instance_valid(game_manager) or not is_instance_valid(data_manager):
		printerr("Inventory.gd: GameManager or DataManager not set. Cannot open inventory.")
		return

	# Refresh player cards list in case it changed (e.g. card died and was removed)
	if game_manager and game_manager.has_node("PlayerCards"):
		player_cards_nodes = game_manager.get_node("PlayerCards").get_children()
	elif game_manager and game_manager.get_parent().has_node("PlayerCards"):
		player_cards_nodes = game_manager.get_parent().get_node("PlayerCards").get_children()
	else:
		player_cards_nodes = [] # Fallback

	selected_character_card = null # Reset selected character
	populate_character_list()
	populate_artifact_inventory_list()
	update_equipped_artifacts_display()
	show()

func _on_close_button_pressed():
	hide()
	emit_signal("inventory_closed")

func _input(event):
	if event.is_action_pressed("ui_cancel") and is_visible(): # Assuming "ui_cancel" is mapped to Escape
		_on_close_button_pressed()
