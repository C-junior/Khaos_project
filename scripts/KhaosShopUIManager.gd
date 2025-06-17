# KhaosShopUIManager.gd
extends CanvasLayer

# var data_manager # No longer needed, use DataManager autoload
# var shop_manager # No longer needed, use ShopManager autoload

var main_panel: PanelContainer
var khaos_coins_display_label: Label
var item_list_container: VBoxContainer # Inside a ScrollContainer

# Store the currently displayed category to refresh it after purchase
var current_category: String = ShopManager.TYPE_CHARACTER 

signal shop_closed

# Helper function to get DataManager instance with fallback
func _get_dm_instance(context_msg: String):
	var dm_instance = null
	if Engine.has_singleton("DataManager"):
		dm_instance = DataManager
		print("KhaosShopUIManager (%s): Accessed DataManager via Engine.has_singleton." % context_msg)
	else:
		print("KhaosShopUIManager (%s): Engine.has_singleton('DataManager') returned false. Attempting get_node_or_null('/root/DataManager')." % context_msg)
		dm_instance = get_node_or_null("/root/DataManager")
		if is_instance_valid(dm_instance):
			print("KhaosShopUIManager (%s): Accessed DataManager via get_node_or_null('/root/DataManager')." % context_msg)
		else:
			print("KhaosShopUIManager (%s): Failed to access DataManager via get_node_or_null('/root/DataManager') as well." % context_msg)
	return dm_instance

# Helper function to get ShopManager instance with fallback
func _get_sm_instance(context_msg: String = "") -> Object:
	var sm_instance = null
	if Engine.has_singleton("ShopManager"):
		sm_instance = ShopManager
		print("KhaosShopUIManager (%s): Accessed ShopManager via Engine.has_singleton." % context_msg)
	else:
		print("KhaosShopUIManager (%s): Engine.has_singleton('ShopManager') returned false. Attempting get_node_or_null('/root/ShopManager')." % context_msg)
		sm_instance = get_node_or_null("/root/ShopManager")
		if is_instance_valid(sm_instance):
			print("KhaosShopUIManager (%s): Accessed ShopManager via get_node_or_null('/root/ShopManager')." % context_msg)
		else:
			printerr("KhaosShopUIManager (%s): Failed to access ShopManager via get_node_or_null('/root/ShopManager') as well." % context_msg)
	return sm_instance

func _ready():
	# UI structure is created, but data-dependent parts are populated when shown.
	create_shop_ui()
	hide_shop() # Start hidden


func create_shop_ui():
	main_panel = PanelContainer.new()
	main_panel.name = "KhaosShopMainPanel"
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(600, 400) # Adjust size as needed
	# Style the panel (optional, but makes it visible)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.25, 0.95) # Dark semi-transparent background
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color.LIGHT_GRAY
	main_panel.add_theme_stylebox_override("panel", stylebox)
	add_child(main_panel)

	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	main_panel.add_child(margin_container)

	var vbox_main_layout = VBoxContainer.new()
	margin_container.add_child(vbox_main_layout)

	# Title
	var title_label = Label.new()
	title_label.text = "Khaos Shop"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox_main_layout.add_child(title_label)

	# Khaos Coins Display
	khaos_coins_display_label = Label.new()
	khaos_coins_display_label.name = "KhaosCoinsDisplay"
	khaos_coins_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox_main_layout.add_child(khaos_coins_display_label)
	# update_coins_display() # Moved to show_shop()

	# Category Buttons
	var category_hbox = HBoxContainer.new()
	category_hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
	vbox_main_layout.add_child(category_hbox)

	var char_button = Button.new()
	char_button.text = "Characters"
	# Accessing ShopManager.TYPE_CHARACTER directly assumes the ShopManager script is loaded,
	# even if the autoload instance isn't ready. This is generally safe for constants.
	char_button.pressed.connect(Callable(self, "populate_items_for_category").bind(ShopManager.TYPE_CHARACTER)) 
	category_hbox.add_child(char_button)

	var artifact_button = Button.new()
	artifact_button.text = "Artifacts"
	artifact_button.pressed.connect(Callable(self, "populate_items_for_category").bind(ShopManager.TYPE_ARTIFACT)) 
	category_hbox.add_child(artifact_button)

	var rune_button = Button.new()
	rune_button.text = "Runes"
	rune_button.pressed.connect(Callable(self, "populate_items_for_category").bind(ShopManager.TYPE_RUNE)) 
	category_hbox.add_child(rune_button)

	# Add Talent Button if ShopManager class is available and has TYPE_TALENT definition
	# This checks if the script itself is known, not necessarily the singleton instance.
	var ShopManagerScript = load("res://scripts/ShopManager.gd") # Get a reference to the script resource
	if ShopManagerScript and ShopManagerScript.get_script_constant_map().has("TYPE_TALENT"):
		# Check if shop_item_definitions (an instance var) is accessible via an instance
		var sm_instance_check = _get_sm_instance("create_shop_ui_talent_button_check")
		if sm_instance_check and sm_instance_check.shop_item_definitions.has(ShopManagerScript.TYPE_TALENT): # Use script constant here
			var talent_button = Button.new()
			talent_button.text = "Talents"
			talent_button.pressed.connect(Callable(self, "populate_items_for_category").bind(ShopManagerScript.TYPE_TALENT)) # Use script constant
			category_hbox.add_child(talent_button)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox_main_layout.add_child(spacer)

	# Item List Area
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main_layout.add_child(scroll_container)

	item_list_container = VBoxContainer.new()
	item_list_container.name = "ItemList"
	item_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(item_list_container)
	
	# Spacer before close button
	var spacer_bottom = Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0,10)
	vbox_main_layout.add_child(spacer_bottom)

	# Close Button
	var close_button = Button.new()
	close_button.text = "Close Shop"
	close_button.pressed.connect(Callable(self, "_on_close_button_pressed"))
	vbox_main_layout.add_child(close_button)


func populate_items_for_category(category_key: String):
	current_category = category_key # Store for refresh
	print("Shop: Populating items for category: %s" % category_key)
	
	var sm_instance = _get_sm_instance("populate_items_for_category")
	if not is_instance_valid(sm_instance):
		printerr("KhaosShopUIManager: ShopManager instance NOT VALID for populate_items_for_category.")
		# Optionally clear items or show an error in the list
		for child in item_list_container.get_children(): child.queue_free()
		var err_label = Label.new(); err_label.text = "Shop items unavailable (SM Error)"; item_list_container.add_child(err_label)
		return

	if not is_instance_valid(item_list_container):
		printerr("KhaosShopUIManager: item_list_container is not valid.")
		return

	# Clear previous items
	for child in item_list_container.get_children():
		child.queue_free()

	var unlockable_items = sm_instance.get_unlockable_items(category_key)
	if unlockable_items.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "No more items to unlock in this category!"
		no_items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list_container.add_child(no_items_label)
		return

	for item_data in unlockable_items:
		var item_panel = HBoxContainer.new()
		item_panel.custom_minimum_size = Vector2(0, 60) # Increased min height for better spacing

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.custom_minimum_size = Vector2(250, 0) # Give info_vbox a good minimum width
		item_panel.add_child(info_vbox)

		var name_label = Label.new()
		name_label.text = item_data.name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.clip_text = true # Prevent very long names from breaking layout
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD # Allow name to wrap if necessary
		info_vbox.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = item_data.get("description", "No description.")
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(0, 30) # Min height for ~2 lines
		desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL # Allow desc to take available vertical space in info_vbox
		info_vbox.add_child(desc_label)
		
		# Cost and Buy Button in their own VBox to align them vertically
		var action_vbox = VBoxContainer.new()
		action_vbox.alignment = VBoxContainer.ALIGNMENT_CENTER # Center cost and button vertically
		item_panel.add_child(action_vbox)

		var cost_label = Label.new()
		cost_label.text = "Cost: %d KC" % item_data.cost
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER # Center text in label
		action_vbox.add_child(cost_label) 
		
		var buy_button = Button.new()
		buy_button.text = "Buy"
		buy_button.custom_minimum_size = Vector2(60,30) # Give button a decent size
		buy_button.pressed.connect(Callable(self, "_on_buy_item_pressed").bind(item_data.id, category_key, item_data.cost))
		action_vbox.add_child(buy_button)
		
		item_list_container.add_child(item_panel)
		
		# Add a separator
		var separator = HSeparator.new()
		item_list_container.add_child(separator)


func _on_buy_item_pressed(item_id, item_type: String, item_cost: int): 
	print("Shop: Attempting to buy item: %s, type: %s, cost: %d" % [item_id, item_type, item_cost])
	
	var sm_instance = _get_sm_instance("_on_buy_item_pressed")
	if not is_instance_valid(sm_instance):
		printerr("KhaosShopUIManager: ShopManager instance NOT VALID for _on_buy_item_pressed.")
		return

	# DataManager check is good here as well, though ShopManager's purchase_unlock should also handle it.
	var dm_instance = _get_dm_instance("_on_buy_item_pressed_dm_check")
	if not is_instance_valid(dm_instance):
		printerr("KhaosShopUIManager: DataManager instance NOT VALID for purchase feedback in _on_buy_item_pressed.")
		# Potentially show a UI error to the player
		return

	var purchase_successful = sm_instance.purchase_unlock(item_id, item_type)
	
	if purchase_successful:
		print("Shop: Purchase successful for %s!" % item_id)
		# Provide user feedback (e.g., a temporary label, sound effect) - for now, print is fine
	else:
		print("Shop: Purchase failed for %s (e.g., not enough coins or already unlocked)." % item_id)
		# Provide user feedback
		
	update_coins_display()
	populate_items_for_category(current_category) # Refresh the list


func update_coins_display():
	var dm_instance = _get_dm_instance("update_coins_display")

	if not is_instance_valid(dm_instance):
		if is_instance_valid(khaos_coins_display_label):
			khaos_coins_display_label.text = "Khaos Coins: Error (DataManager inaccessible)"
		return
	
	if is_instance_valid(khaos_coins_display_label):
		khaos_coins_display_label.text = "Khaos Coins: %d" % dm_instance.current_khaos_coins


func show_shop():
	if not main_panel: 
		create_shop_ui()
		if not main_panel: 
			printerr("KhaosShopUIManager: Main panel could not be created.")
			return

	print("KHAOS SHOP (UI): Attempting to check DataManager. Global Name configured? ", ProjectSettings.has_setting("autoload/DataManager"))
	
	var dm_instance = _get_dm_instance("show_shop")

	if not is_instance_valid(dm_instance):
		printerr("KhaosShopUIManager: DataManager instance NOT VALID when trying to show shop!")
		if is_instance_valid(khaos_coins_display_label):
			khaos_coins_display_label.text = "Error: DataManager not accessible."
		# Optionally disable shop functionality or parts of it by not populating items
		main_panel.show() # Show panel even with error to make error visible
		return

	# Proceed to check ShopManager
	var sm_instance = _get_sm_instance("show_shop_sm_check")
	if not is_instance_valid(sm_instance):
		printerr("KhaosShopUIManager: ShopManager instance NOT VALID when trying to show shop!")
		if is_instance_valid(khaos_coins_display_label): 
			if is_instance_valid(dm_instance): # dm_instance should be valid if we reached here
				khaos_coins_display_label.text = str(dm_instance.current_khaos_coins) + " (Shop Error)"
			else: # Should not happen given the earlier check for dm_instance
				khaos_coins_display_label.text = "Error: DM & Shop inaccessible"
		main_panel.show() # Show panel even with error
		return
	
	# Both DataManager and ShopManager instances are valid, proceed to populate and show
	# update_coins_display() now uses dm_instance via _get_dm_instance()
	update_coins_display() 
	# populate_items_for_category also uses ShopManager directly, which in turn will use the new DM access.
	populate_items_for_category(current_category) 
	main_panel.show()


func hide_shop():
	if main_panel:
		main_panel.hide()

func _on_close_button_pressed():
	hide_shop()
	emit_signal("shop_closed")
