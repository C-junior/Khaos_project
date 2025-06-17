# Test script for enemy system
extends Node

func _ready():
	print("Testing enemy system...")
	test_enemy_data()
	test_wave_data()

func test_enemy_data():
	print("=== Testing Enemy Data ===")
	for enemy_key in Data.ENEMY_TYPES:
		var enemy_data = Data.ENEMY_TYPES[enemy_key]
		print("Enemy: %s" % enemy_key)
		print("  Name: %s" % enemy_data.name)
		print("  Health: %d" % enemy_data.health)
		print("  Attack: %d" % enemy_data.attack)
		print("  Image: %s" % enemy_data.image)
		if "ability" in enemy_data:
			print("  Ability: %s" % enemy_data.ability)
		print("---")

func test_wave_data():
	print("=== Testing Wave Data ===")
	for i in range(Data.waves.size()):
		var wave = Data.waves[i]
		print("Wave %d:" % (i + 1))
		print("  Enemies: %s" % wave.enemies)
		print("---")

func test_create_enemy():
	print("=== Testing Enemy Creation ===")
	var enemy_card = load("res://Card.tscn").instantiate()
	enemy_card.is_player = false
	enemy_card.type = Globals.CardType.ENEMY
	
	var enemy_data = Data.ENEMY_TYPES["Goblin"]
	enemy_card.health = enemy_data.health
	enemy_card.max_health = enemy_data.health
	enemy_card.attack = enemy_data.attack
	enemy_card.text = enemy_data.name
	
	print("Created enemy: %s with %d health and %d attack" % [enemy_card.text, enemy_card.health, enemy_card.attack])
	
	# Test image setting
	if enemy_card.has_method("set_image"):
		enemy_card.set_image(enemy_data.image)
	
	return enemy_card