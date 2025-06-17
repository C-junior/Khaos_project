extends Node

signal wave_started(wave_number)
signal wave_completed(wave_number)

const Card = preload("res://Card.tscn")

var waves: Array = []
var enemy_container: Node

func _ready() -> void:
	waves = Data.waves

func initialize(enemy_container_node: Node) -> void:
	enemy_container = enemy_container_node

func start_wave(wave_number: int) -> void:
	if wave_number >= waves.size():
		return
		
	_clear_current_enemies()
	_spawn_wave_enemies(wave_number)
	wave_started.emit(wave_number)

func _spawn_wave_enemies(wave_number: int) -> void:
	var wave_data = waves[wave_number]
	for enemy_type_key in wave_data.enemies:
		var enemy_data = Data.ENEMY_TYPES[enemy_type_key]
		var enemy = Card.instantiate()
		enemy_container.add_child(enemy)
		
		# Determine if this is a boss type
		if enemy_type_key == "OrcBoss" or "Boss" in enemy_type_key:
			enemy.type = Globals.CardType.BOSS
		else:
			enemy.type = Globals.CardType.ENEMY
		
		# Set enemy properties from the enemy type data
		enemy.health = enemy_data.health
		enemy.max_health = enemy_data.health
		enemy.attack = enemy_data.attack
		enemy.is_player = false
		
		# Set the enemy name for display
		enemy.text = enemy_data.name
		
		# If the enemy has an image path, set it (assuming there's a method to set the image)
		if "image" in enemy_data:
			# This would need to be implemented in the Card class
			if enemy.has_method("set_image"):
				enemy.set_image(enemy_data.image)
		
		# If the enemy has a special ability, store it
		if "ability" in enemy_data:
			enemy.apply_status_effect("special_ability", enemy_data.ability)
		
		CardManager.register_enemy_card(enemy)

func _clear_current_enemies() -> void:
	for enemy in enemy_container.get_children():
		enemy.queue_free()
	await get_tree().process_frame
	CardManager.enemy_cards.clear()

func get_wave_count() -> int:
	return waves.size()

func calculate_upgrade_points(wave_number: int) -> int:
	# Base points plus bonus for higher waves
	return 3 + wave_number
