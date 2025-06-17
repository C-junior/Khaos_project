extends Control

var khaos_shop_ui_instance = null
const KHAOS_SHOP_UI_SCRIPT_PATH = "res://scripts/KhaosShopUIManager.gd"

func _ready():
	print("MainMenu.gd: _ready() CALLED (Timestamp: %s)" % Time.get_ticks_msec()) # Added timestamp for better tracing
	$NewGameButton.pressed.connect(Callable(self, "_on_new_game"))
	$LoadGameButton.pressed.connect(Callable(self, "_on_load_game"))
	$TalentTree.pressed.connect(Callable(self, "_on_talent_tree"))
	var shop_button = Button.new()
	shop_button.name = "KhaosShopButton"
	shop_button.text = "Khaos Shop"
	shop_button.pressed.connect(Callable(self, "_on_khaos_shop_button_pressed"))
	
	# Add the shop button to the same parent as the NewGameButton, likely a VBoxContainer
	var button_parent = $NewGameButton.get_parent()
	if button_parent:
		button_parent.add_child(shop_button)
	else:
		# Fallback if NewGameButton has no parent (e.g. root of this scene)
		# This might require manual positioning if not in a container
		add_child(shop_button)
		# Example manual positioning (if not in a container):
		# shop_button.position = Vector2($LoadGameButton.position.x, $LoadGameButton.position.y + $LoadGameButton.size.y + 10)

func _on_new_game():
	# Ensure shop is hidden if it was opened and game is started
	if is_instance_valid(khaos_shop_ui_instance):
		khaos_shop_ui_instance.hide_shop()
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_talent_tree():
	# Ensure shop is hidden if it was opened and game is started
	if is_instance_valid(khaos_shop_ui_instance):
		khaos_shop_ui_instance.hide_shop()
	get_tree().change_scene_to_file("res://talent_tree/talent_tree.tscn")
func _on_load_game():
	# Ensure shop is hidden
	if is_instance_valid(khaos_shop_ui_instance):
		khaos_shop_ui_instance.hide_shop()
	print("Load game functionality TBD")
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_khaos_shop_button_pressed():
	if not is_instance_valid(khaos_shop_ui_instance):
		var KhaosShopUIScript = load(KHAOS_SHOP_UI_SCRIPT_PATH)
		if KhaosShopUIScript:
			khaos_shop_ui_instance = KhaosShopUIScript.new()
			khaos_shop_ui_instance.name = "KhaosShopUIManager" # So it can be found by get_node
			
			# Add KhaosShopUI to the root of the scene tree to ensure it persists and is accessible
			if get_tree() and get_tree().root:
				get_tree().root.add_child(khaos_shop_ui_instance)
				print("MainMenu: KhaosShopUI added to get_tree().root")
			else:
				printerr("MainMenu: Cannot access get_tree().root. KhaosShopUI cannot be added.")
				return # Cannot proceed if root is not accessible

			if khaos_shop_ui_instance.has_signal("shop_closed"): # Check if signal exists
				if not khaos_shop_ui_instance.is_connected("shop_closed", Callable(self, "_on_khaos_shop_closed")):
					khaos_shop_ui_instance.connect("shop_closed", Callable(self, "_on_khaos_shop_closed"))
			else:
				printerr("MainMenu: KhaosShopUIManager does not have 'shop_closed' signal.")
		else:
			printerr("MainMenu: Failed to load KhaosShopUI script at %s" % KHAOS_SHOP_UI_SCRIPT_PATH)
			return

	if is_instance_valid(khaos_shop_ui_instance):
		khaos_shop_ui_instance.show_shop()
		self.hide() # Hide the main menu controls

func _on_khaos_shop_closed():
	self.show() # Show the main menu controls again
	# Optional: queue_free the shop instance if you want it recreated every time.
	# if is_instance_valid(khaos_shop_ui_instance):
	#    khaos_shop_ui_instance.queue_free()
	#    khaos_shop_ui_instance = null
