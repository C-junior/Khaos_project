# Artifact.gd
extends Resource
class_name Artifact

var id: String # Unique identifier, e.g., "Thunder Bolt"
var level: int = 1
var current_cooldown: int = 0
var rune: Rune = null # Rune system interaction will be refined later

# Cached data for the current level
var _level_data_cache: Dictionary = {}

func _init(_id: String = "", _level: int = 1):
	id = _id
	level = clamp(_level, 1, 9) # Assuming max level 9 (for +8)
	_update_level_data_cache()

func _update_level_data_cache():
	if id.is_empty() or not Data.artifacts.has(id):
		printerr("Artifact _update_level_data_cache: Artifact ID '%s' not found in Data.artifacts." % id)
		_level_data_cache = {}
		return

	var artifact_data = Data.artifacts[id]
	if not artifact_data.has("levels") or artifact_data.levels.size() == 0:
		printerr("Artifact _update_level_data_cache: Artifact '%s' has no levels defined in Data.artifacts." % id)
		_level_data_cache = {}
		return

	var current_level_index = level - 1
	if current_level_index < 0 or current_level_index >= artifact_data.levels.size():
		printerr("Artifact _update_level_data_cache: Level %d is out of bounds for artifact '%s'. Max levels: %d" % [level, id, artifact_data.levels.size()])
		# Fallback to last valid level or first if level is too low
		current_level_index = clamp(current_level_index, 0, artifact_data.levels.size() - 1)
		level = current_level_index + 1 # Correct the instance's level property

	_level_data_cache = artifact_data.levels[current_level_index]

func get_level_data() -> Dictionary:
	if _level_data_cache.is_empty() and not id.is_empty(): # Attempt to reload if empty but id is set
		_update_level_data_cache()
	return _level_data_cache

func get_name() -> String:
	if level > 1:
		return "%s +%d" % [id, level - 1]
	return id

func get_description() -> String:
	var data = get_level_data()
	if data.has("description"):
		return data.description
	return "No description available."

func get_cooldown() -> int:
	var data = get_level_data()
	if data.has("cooldown"):
		return data.cooldown
	return 99 # Default high cooldown if not specified

# This function determines if the artifact ability itself requires a target selection phase.
# Individual effects within the ability might target user, all_enemies etc. without selection.
func requires_target_selection() -> bool:
	if id.is_empty() or not Data.artifacts.has(id):
		return false # Default if data is missing
	var artifact_base_data = Data.artifacts[id]
	return artifact_base_data.get("requires_targets", false)


func set_level(new_level: int):
	level = clamp(new_level, 1, 9) # Assuming max level 9 for now
	_update_level_data_cache()
	# Potentially emit a signal if UI needs to react to level change directly on artifact instance

func attach_rune(_rune: Rune):
	rune = _rune
	# Rune effects on base stats like cooldown might be handled here or when stats are read.
	# For "Quick Cast", we can adjust current_cooldown or the base cooldown for this instance.
	# However, get_cooldown() now reads from _level_data_cache.
	# A simple approach for Quick Cast:
	if rune and rune.name == "Quick Cast":
		# This modification is to the instance, not the underlying Data.gd
		# If we want to modify the "base" cooldown for this instance:
		var data = get_level_data().duplicate() # Avoid modifying global Data
		data["cooldown"] = max(1, data.get("cooldown", 99) - 1)
		_level_data_cache = data # Cache the modified data for this instance
		if current_cooldown > get_cooldown(): # Adjust current if it was higher than new max
			current_cooldown = get_cooldown()


func can_use() -> bool:
	return current_cooldown <= 0

func use(user: CardBase, selected_targets: Array): # selected_targets might be empty
	if not can_use():
		print("%s is on cooldown for %d turns." % [get_name(), current_cooldown])
		return

	var user_card_name = "Unknown User"
	if is_instance_valid(user) and user.has_method("get_text"): # Assuming CardBase has get_text or similar
		user_card_name = user.get_text()
	elif is_instance_valid(user) and user.has_meta("text_name"): # Fallback if you set a meta name
		user_card_name = user.get_meta("text_name")
	elif is_instance_valid(user):
		user_card_name = user.name # Node name as last resort

	print("%s uses %s (Lvl %d)." % [user_card_name, id, level])

	var effects_array = get_level_data().get("effects", [])
	if effects_array.is_empty():
		print("No effects found for %s Lvl %d" % [id, level])
		return

	# --- Mage Arcane Echo Handling ---
	var run_effects_count = 1
	if is_instance_valid(user) and user.type == Globals.CardType.MAGE: # Ensure user is valid CardBase
		user.spell_count += 1
		if user.spell_count % 3 == 0:
			print("%s's Arcane Echo triggers!" % user_card_name)
			run_effects_count = 2
	# --- End Arcane Echo ---

	for i in range(run_effects_count):
		if i > 0: print("Arcane Echo: Repeating effects for %s" % get_name())
		for effect_definition in effects_array:
			execute_effect(user, selected_targets, effect_definition)
	
	# --- Rune Post-Effect (Conceptual - Full rune interaction needs more design) ---
	if rune and rune.has_method("apply_post_effects"): # Example hook
		rune.apply_post_effects(user, selected_targets, self)
	# --- End Rune Post-Effect ---

	current_cooldown = get_cooldown() # Set cooldown based on (potentially rune-modified) level data
	if is_instance_valid(user): # Ensure user is valid CardBase
		user.update_labels()


func execute_effect(user: CardBase, selected_targets: Array, effect_definition: Dictionary):
	var effect_type = effect_definition.get("type", "")
	var target_type = effect_definition.get("target_type", "") # e.g. "single_enemy", "user", "all_enemies"

	var actual_targets: Array = []

	# Determine actual targets based on effect_definition and selected_targets
	match target_type:
		"single_enemy":
			if selected_targets.size() > 0 and selected_targets[0] is CardBase and not selected_targets[0].is_player:
				actual_targets.append(selected_targets[0])
			else:
				# Try to find a default enemy if no valid target selected (e.g. if selection was optional but effect needs one)
				# This might need GameManager access or be skipped if selection is strictly required by requires_target_selection()
				print("Warning: Effect type '%s' for '%s' requires a single enemy target, but none valid was provided." % [effect_type, id])
				return # Skip this effect if no valid target
		"user":
			actual_targets.append(user)
		"all_enemies":
			var game_manager = user.get_node_or_null("/root/GameManager") # Path to GameManager
			if game_manager: actual_targets = game_manager.get_alive_enemies()
		"all_allies":
			var game_manager = user.get_node_or_null("/root/GameManager")
			if game_manager: actual_targets = game_manager.get_alive_player_cards() # Assumes players are allies
		"random_enemies":
			var game_manager = user.get_node_or_null("/root/GameManager")
			if game_manager:
				var num_to_target = effect_definition.get("num_targets", 1)
				var alive_enemies = game_manager.get_alive_enemies()
				alive_enemies.shuffle()
				for i in range(min(num_to_target, alive_enemies.size())):
					actual_targets.append(alive_enemies[i])
		_: # Default or unhandled target_type
			if selected_targets.size() > 0: # Fallback to selected_targets if any
				actual_targets = selected_targets
			else: # Or user if no selection
				actual_targets.append(user)


	if actual_targets.is_empty() and target_type not in ["user"]: # "user" target type is implicitly valid if user exists
		# Check if effect should proceed if no specific targets found (e.g. some AoEs might still work on empty field)
		# For now, if specific targets like all_enemies results in empty, we might still proceed if the effect is, e.g., a field effect
		# But for most direct targeting, if actual_targets is empty, we should probably stop.
		var can_proceed_without_targets = effect_definition.get("can_proceed_without_targets", false) # Add this to Data.gd if needed
		if not can_proceed_without_targets:
			print("Effect '%s' for '%s': No valid actual targets found for target_type '%s'." % [effect_type, id, target_type])
			return


	# Process the effect based on its type
	match effect_type:
		"damage":
			var scale_atk = effect_definition.get("scale_with_atk", 0.0)
			var fixed_dmg = effect_definition.get("fixed_damage", 0)
			for target_card in actual_targets:
				if is_instance_valid(target_card) and target_card is CardBase:
					var total_damage = int(user.attack * scale_atk + fixed_dmg)
					target_card.take_damage(total_damage, user)
					print("'%s' deals %d damage to '%s'" % [id, total_damage, target_card.get_text_name()])

		"damage_all_enemies": # This target_type is handled by "all_enemies" above, effect is just damage
			var scale_atk = effect_definition.get("scale_with_atk", 0.0)
			var fixed_dmg = effect_definition.get("fixed_damage", 0)
			for enemy_card in actual_targets: # actual_targets should be all_enemies here
				if is_instance_valid(enemy_card) and enemy_card is CardBase:
					var total_damage = int(user.attack * scale_atk + fixed_dmg)
					enemy_card.take_damage(total_damage, user)
					print("'%s' deals %d damage to '%s' (all_enemies)" % [id, total_damage, enemy_card.get_text_name()])

		"lifesteal_damage":
			var scale_atk = effect_definition.get("scale_with_atk", 0.0)
			var fixed_dmg = effect_definition.get("fixed_damage", 0)
			var lifesteal_ratio = effect_definition.get("lifesteal_ratio", 0.0)
			for target_card in actual_targets:
				if is_instance_valid(target_card) and target_card is CardBase:
					var total_damage = int(user.attack * scale_atk + fixed_dmg)
					var damage_dealt = target_card.take_damage(total_damage, user, true) # take_damage returns actual damage dealt
					var heal_amount = int(damage_dealt * lifesteal_ratio)
					if heal_amount > 0:
						user.heal(heal_amount)
						print("'%s' deals %d damage to '%s' and heals self for %d" % [id, damage_dealt, target_card.get_text_name(), heal_amount])


		"chain_damage":
			var main_scale_atk = effect_definition.get("main_target_scale_atk", 0.0)
			var main_fixed_dmg = effect_definition.get("main_target_fixed_damage", 0)
			var chain_scale_atk = effect_definition.get("chain_scale_atk", 0.0)
			var chain_fixed_dmg = effect_definition.get("chain_fixed_damage", 0)
			var num_chain_targets = effect_definition.get("chain_targets", 0)

			if actual_targets.size() > 0: # Main target should be in actual_targets[0] from "single_enemy" selection
				var main_target = actual_targets[0]
				if is_instance_valid(main_target) and main_target is CardBase:
					var main_damage = int(user.attack * main_scale_atk + main_fixed_dmg)
					main_target.take_damage(main_damage, user)
					print("'%s' (chain) deals %d main damage to '%s'" % [id, main_damage, main_target.get_text_name()])

					if num_chain_targets > 0:
						var game_manager = user.get_node_or_null("/root/GameManager")
						if game_manager:
							var potential_chain_targets = game_manager.get_alive_enemies().filter(func(t): return t != main_target)
							potential_chain_targets.shuffle()
							for i in range(min(num_chain_targets, potential_chain_targets.size())):
								var chain_target = potential_chain_targets[i]
								if is_instance_valid(chain_target) and chain_target is CardBase:
									var chain_damage_val = int(user.attack * chain_scale_atk + chain_fixed_dmg)
									chain_target.take_damage(chain_damage_val, user)
									print("'%s' (chain) deals %d chain damage to '%s'" % [id, chain_damage_val, chain_target.get_text_name()])


		"heal":
			var scale_hp = effect_definition.get("scale_with_max_hp", 0.0)
			var fixed_heal = effect_definition.get("fixed_heal", 0)
			for target_card in actual_targets:
				if is_instance_valid(target_card) and target_card is CardBase:
					var total_heal = int(target_card.max_health * scale_hp + fixed_heal)
					target_card.heal(total_heal)
					print("'%s' heals '%s' for %d" % [id, target_card.get_text_name(), total_heal])

		"heal_all_allies": # actual_targets should be all_allies
			var scale_hp = effect_definition.get("scale_with_max_hp", 0.0)
			var fixed_heal = effect_definition.get("fixed_heal", 0)
			for ally_card in actual_targets:
				if is_instance_valid(ally_card) and ally_card is CardBase:
					var total_heal = int(ally_card.max_health * scale_hp + fixed_heal)
					ally_card.heal(total_heal)
					print("'%s' heals '%s' for %d (all_allies)" % [id, ally_card.get_text_name(), total_heal])

		"apply_status", "apply_status_with_chance":
			var status_name = effect_definition.get("status_name", "")
			var value = effect_definition.get("value") # Can be int, float, or bool depending on status
			var duration = effect_definition.get("duration", 1)
			var chance = effect_definition.get("chance", 1.0) # Default 100% chance

			if status_name.is_empty():
				printerr("Artifact effect 'apply_status': status_name is empty for %s" % id)
				return

			if effect_type == "apply_status_with_chance" and randf() >= chance:
				print("'%s' effect '%s' chance failed for targets." % [id, status_name])
				# For per-target chance, this check moves inside the loop
			else:
				for target_card in actual_targets:
					if is_instance_valid(target_card) and target_card is CardBase:
						# If chance is per target (e.g. meteor strike stun), check here:
						# if effect_type == "apply_status_with_chance" and effect_definition.get("chance_per_target", false) and randf() >= chance:
						#     print("'%s' effect '%s' chance failed for target '%s'." % [id, status_name, target_card.get_text_name()])
						#     continue
						target_card.apply_status_effect(status_name, {"value": value, "duration": duration}) # Pass value and duration
						print("'%s' applies status '%s' to '%s' (Val: %s, Dur: %d)" % [id, status_name, target_card.get_text_name(), str(value), duration])

		"apply_status_to_all_enemies", "apply_status_to_all_enemies_with_chance":
			# actual_targets should be all_enemies here
			var status_name = effect_definition.get("status_name", "")
			var value = effect_definition.get("value")
			var duration = effect_definition.get("duration", 1)
			var chance = effect_definition.get("chance", 1.0)
			var chance_per_target = effect_definition.get("chance_per_target", true) # Default to chance per target for AoE status

			if status_name.is_empty(): return

			for enemy_card in actual_targets:
				if is_instance_valid(enemy_card) and enemy_card is CardBase:
					if effect_type.ends_with("_with_chance"):
						if chance_per_target and randf() >= chance:
							print("'%s' status '%s' chance failed for enemy '%s'." % [id, status_name, enemy_card.get_text_name()])
							continue # Skip this target
						elif not chance_per_target and randf() >= chance and enemy_card == actual_targets[0]: # only roll once for all
							print("'%s' status '%s' chance failed for all enemies." % [id, status_name])
							break # Stop applying to any more targets

					enemy_card.apply_status_effect(status_name, {"value": value, "duration": duration})
					print("'%s' applies status '%s' to '%s' (all_enemies)" % [id, status_name, enemy_card.get_text_name()])

		"apply_status_to_all_allies":
			# actual_targets should be all_allies here
			var status_name = effect_definition.get("status_name", "")
			var value = effect_definition.get("value")
			var duration = effect_definition.get("duration", 1)
			if status_name.is_empty(): return

			for ally_card in actual_targets:
				if is_instance_valid(ally_card) and ally_card is CardBase:
					ally_card.apply_status_effect(status_name, {"value": value, "duration": duration})
					print("'%s' applies status '%s' to '%s' (all_allies)" % [id, status_name, ally_card.get_text_name()])

		"remove_debuffs", "remove_debuffs_with_chance":
			var count = effect_definition.get("count", 1)
			var chance = effect_definition.get("chance", 1.0)
			if effect_type == "remove_debuffs_with_chance" and randf() >= chance:
				print("'%s' remove_debuffs chance failed." % id)
			else:
				for target_card in actual_targets:
					if is_instance_valid(target_card) and target_card is CardBase:
						target_card.remove_debuffs(count) # Assumes CardBase.remove_debuffs(count) exists
						print("'%s' removes %d debuff(s) from '%s'" % [id, count, target_card.get_text_name()])
		_:
			printerr("Artifact execute_effect: Unknown effect type '%s' for artifact '%s'" % [effect_type, id])


func turn_end():
	if current_cooldown > 0:
		current_cooldown -= 1

# Alias for backward compatibility if any old code calls activate directly
func activate(user: CardBase, targets: Array):
	use(user, targets)

func get_data_for_save() -> Dictionary:
	var rune_id = ""
	if rune:
		rune_id = rune.name # Assuming rune has a name property
	return {
		"id": id,
		"level": level,
		"current_cooldown": current_cooldown,
		"rune_id": rune_id
	}

static func new_from_save_data(data: Dictionary) -> Artifact:
	if not data.has("id") or not data.has("level"):
		printerr("Artifact new_from_save_data: Missing 'id' or 'level' in save data.")
		return null

	var artifact = Artifact.new(data.id, data.level)
	artifact.current_cooldown = data.get("current_cooldown", 0)

	var rune_id = data.get("rune_id", "")
	if not rune_id.is_empty() and Data.runes.has(rune_id): # Check if Data.runes exists
		# This assumes ArtifactFactory is available or similar logic to create/attach rune
		var artifact_factory = Globals.get_node_or_null("ArtifactFactory") # Example path
		if artifact_factory and artifact_factory.has_method("create_rune"):
			var rune_instance = artifact_factory.create_rune(rune_id)
			if rune_instance:
				artifact.attach_rune(rune_instance)
		else: # Fallback or direct creation if ArtifactFactory isn't used for this
			var rune_data = Data.runes[rune_id]
			# Assuming Rune.gd has a constructor that takes name and modify_func callable path
			# This part is complex as modify_func is a Callable. For save/load, storing rune ID is typical.
			# The actual rune modification logic might need to be reapplied based on this ID when loaded.
			# For now, just note that the rune_id is available.
			# A simple way:
			var temp_rune = Rune.new(rune_id, rune_data.ability if rune_data.has("ability") else Callable())
			artifact.attach_rune(temp_rune) # This might re-apply Quick Cast if it's re-cached
			print("Artifact.new_from_save_data: Attached rune '%s' to '%s'" % [rune_id, artifact.id])

	return artifact
