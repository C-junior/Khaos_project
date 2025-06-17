extends Control

enum State { PLAYER_TURN, ENEMY_TURN, UPGRADE_PHASE, GAME_OVER }
var current_state = State.PLAYER_TURN

var selected_card = null
var upgrade_points = 0
var current_wave = 0

var waves = [
	#{"enemies": [
		#{"type": Globals.CardType.ENEMY, "health": 3, "attack": 2},
		#{"type": Globals.CardType.ENEMY, "health": 3, "attack": 2}
	#]},
	#{"enemies": [
		#{"type": Globals.CardType.ENEMY, "health": 12, "attack": 2},
		#{"type": Globals.CardType.ENEMY, "health": 12, "attack": 2},
		#{"type": Globals.CardType.ENEMY, "health": 12, "attack": 2}
	#]},
	#{"enemies": [
		#{"type": Globals.CardType.ENEMY, "health": 15, "attack": 3},
		#{"type": Globals.CardType.ENEMY, "health": 15, "attack": 3}
	#]},
	#{"enemies": [
		#{"type": Globals.CardType.ENEMY, "health": 18, "attack": 3},
		#{"type": Globals.CardType.ENEMY, "health": 18, "attack": 3},
		#{"type": Globals.CardType.ENEMY, "health": 18, "attack": 3}
	#]},
	#{"enemies": [
		#{"type": Globals.CardType.ENEMY, "health": 20, "attack": 4},
		#{"type": Globals.CardType.ENEMY, "health": 20, "attack": 4}
	#]},
	#{"enemies": [
		#{"type": Globals.CardType.ENEMY, "health": 22, "attack": 4},
		#{"type": Globals.CardType.ENEMY, "health": 22, "attack": 4},
		#{"type": Globals.CardType.BOSS, "health": 40, "attack": 6}
	#]},
	#{"enemies": [
		#{"type": Globals.CardType.ENEMY, "health": 25, "attack": 5},
		#{"type": Globals.CardType.ENEMY, "health": 25, "attack": 5},
		#{"type": Globals.CardType.BOSS, "health": 50, "attack": 7}
	#]}
]


var artifacts = [
	#{"name": "Healing Stone", "cost": 3},
	#{"name": "Fire Orb", "cost": 4},
	#{"name": "Thunder Bolt", "cost": 3},
	#{"name": "Iron Shield", "cost": 2},
	#{"name": "Poison Vial", "cost": 3},
	#{"name": "Frost Shard", "cost": 3},
	#{"name": "Vampire Fang", "cost": 4},
	#{"name": "Wind Gust", "cost": 2},
	#{"name": "Lightning Chain", "cost": 5}
]

func _ready():
	start_game()
	$EndTurnButton.pressed.connect(Callable(self, "player_end_turn"))
	update_turn_label()

func start_game():
	var paladin = load("res://Card.tscn").instantiate()
	paladin.is_player = true
	paladin.type = Globals.CardType.PALADIN
	paladin.health = 30
	paladin.max_health = 30
	paladin.attack = 3
	$PlayerCards.add_child(paladin)
	paladin.pressed.connect(Callable(self, "_on_card_pressed").bind(paladin))

	var mage = load("res://Card.tscn").instantiate()
	mage.is_player = true
	mage.type = Globals.CardType.MAGE
	mage.health = 15
	mage.max_health = 15
	mage.attack = 5
	$PlayerCards.add_child(mage)
	mage.pressed.connect(Callable(self, "_on_card_pressed").bind(mage))

	var knight = load("res://Card.tscn").instantiate()
	knight.is_player = true
	knight.type = Globals.CardType.KNIGHT
	knight.health = 20
	knight.max_health = 20
	knight.attack = 4
	$PlayerCards.add_child(knight)
	knight.pressed.connect(Callable(self, "_on_card_pressed").bind(knight))

	for card in $PlayerCards.get_children():
		card.get_node("VBoxContainer/AbilityButton").pressed.connect(Callable(self, "_on_ability_pressed").bind(card))
		
	start_wave()

func start_wave():
	if current_wave >= waves.size():
		print("You win!")
		return
	$WaveLabel.text = "Wave: " + str(current_wave + 1)
	var wave_data = waves[current_wave]
	for enemy_data in wave_data.enemies:
		var enemy = load("res://Card.tscn").instantiate()
		enemy.is_player = false
		enemy.type = enemy_data.type
		enemy.health = enemy_data.health
		enemy.max_health = enemy_data.health
		enemy.attack = enemy_data.attack
		$EnemyCards.add_child(enemy)
		enemy.pressed.connect(Callable(self, "_on_card_pressed").bind(enemy))
	
	current_state = State.PLAYER_TURN
	reset_player_attacks()
	update_turn_label()
	update_wave_progress()

func perform_attack(attacker, defender):
	attacker.attack_target(defender)
	update_wave_progress()
	if check_wave_cleared():
		start_upgrade_phase()
	elif check_game_over():
		game_over()

func check_wave_cleared():
	for enemy in $EnemyCards.get_children():
		if enemy.health > 0:
			return false
	return true

func check_game_over():
	for card in $PlayerCards.get_children():
		if card.health > 0:
			return false
	return true

func reset_player_attacks():
	for card in $PlayerCards.get_children():
		card.has_attacked = false
		card.ability_used = false

func player_end_turn():
	current_state = State.ENEMY_TURN
	update_turn_label()
	perform_enemy_turn()

func perform_enemy_turn():
	for enemy in $EnemyCards.get_children():
		if enemy.health <= 0:
			continue
		enemy.apply_poison()
		if enemy.health <= 0:
			continue
		if enemy.is_frozen:
			enemy.is_frozen = false
			continue
		if enemy.attack_delay > 0:
			enemy.attack_delay -= 1
			continue
		var targets = $PlayerCards.get_children()
		if targets.size() > 0:
			var weakest = targets[0]
			for target in targets:
				if target.health < weakest.health:
					weakest = target
			enemy.attack_target(weakest)
			await get_tree().create_timer(0.5).timeout
	
	if check_game_over():
		game_over()
	else:
		current_state = State.PLAYER_TURN
		reset_player_attacks()
		update_turn_label()

func start_upgrade_phase():
	current_state = State.UPGRADE_PHASE
	update_turn_label()
	upgrade_points = 5 + (current_wave / 2)
	$UpgradePanel.show()
	$PointsLabel.text = "Points: " + str(upgrade_points)
	
	for child in $UpgradePanel/UpgradeContainer.get_children():
		child.queue_free()
	
	var artifact_tooltips = {
		"Healing Stone": "Heals this card for 5 health",
		"Fire Orb": "Deals half attack damage to all enemies",
		"Thunder Bolt": "Deals full attack damage to one enemy",
		"Iron Shield": "Reduces next damage taken by 2",
		"Poison Vial": "Poisons an enemy for 1 damage/turn (3 turns)",
		"Frost Shard": "Freezes an enemy, skipping its next turn",
		"Vampire Fang": "Steals 3 health from an enemy",
		"Wind Gust": "Delays an enemy’s attack by 1 turn",
		"Lightning Chain": "Deals half attack to 2 random enemies"
	}
	
	var available_artifacts = artifacts.duplicate()
	available_artifacts.shuffle()
	var displayed_artifacts = available_artifacts.slice(0, 3)
	
	for card in $PlayerCards.get_children():
		var card_section = VBoxContainer.new()
		var label = Label.new()
		label.text = "Card (" + str(card.get_children()[1].get_children()[0].text) + ")"
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
		artifact_label.text = "Current Artifact: " + (card.artifact if card.artifact != "" else "None")
		card_section.add_child(artifact_label)
		
		for artifact in displayed_artifacts:
			var artifact_button = Button.new()
			artifact_button.text = "Equip " + artifact.name + " (" + str(artifact.cost) + " pts)"
			artifact_button.tooltip_text = artifact_tooltips[artifact.name]
			artifact_button.pressed.connect(Callable(self, "_on_equip_artifact").bind(card, artifact.name, artifact.cost))
			card_section.add_child(artifact_button)
		
		$UpgradePanel/UpgradeContainer.add_child(card_section)
	
	var continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.pressed.connect(Callable(self, "_on_continue"))
	$UpgradePanel/UpgradeContainer.add_child(continue_button)

func _on_upgrade_health(card):
	if upgrade_points > 0:
		card.health += 1
		card.max_health += 1
		upgrade_points -= 1
		$PointsLabel.text = "Points: " + str(upgrade_points)
		card.update_labels()

func _on_upgrade_attack(card):
	if upgrade_points > 0:
		card.attack += 1
		upgrade_points -= 1
		$PointsLabel.text = "Points: " + str(upgrade_points)
		card.update_labels()

func _on_equip_artifact(card, artifact_name: String, cost: int):
	if upgrade_points >= cost and card.artifact != artifact_name:
		card.artifact = artifact_name
		upgrade_points -= cost
		$PointsLabel.text = "Points: " + str(upgrade_points)
		card.update_labels()

func _on_ability_pressed(card):
	if current_state != State.PLAYER_TURN or card.ability_used:
		return
	if card.artifact in ["Healing Stone", "Iron Shield"]:
		card.use_ability(null)
	elif card.artifact in ["Fire Orb", "Lightning Chain"]:
		var targets = $EnemyCards.get_children()
		card.use_ability(targets)
	elif card.artifact in ["Thunder Bolt", "Poison Vial", "Frost Shard", "Vampire Fang", "Wind Gust"]:
		if selected_card == null:
			selected_card = card
		elif selected_card == card:
			selected_card = null

func _on_card_pressed(card):
	if current_state != State.PLAYER_TURN:
		return
	if card.is_player:
		if selected_card != null and selected_card.artifact in ["Thunder Bolt", "Poison Vial", "Frost Shard", "Vampire Fang", "Wind Gust"]:
			return
		selected_card = card
	elif selected_card != null:
		if selected_card.artifact in ["Thunder Bolt", "Poison Vial", "Frost Shard", "Vampire Fang", "Wind Gust"] and not selected_card.ability_used:
			selected_card.use_ability([card])
			selected_card.ability_used = true
			selected_card = null
		elif not selected_card.has_attacked:
			perform_attack(selected_card, card)
			selected_card.has_attacked = true
			selected_card = null

func _on_continue():
	$UpgradePanel.hide()
	current_wave += 1
	start_wave()

func game_over():
	current_state = State.GAME_OVER
	update_turn_label()
	print("Game Over")

func update_turn_label():
	match current_state:
		State.PLAYER_TURN:
			$TurnLabel.text = "Player Turn"
		State.ENEMY_TURN:
			$TurnLabel.text = "Enemy Turn"
		State.UPGRADE_PHASE:
			$TurnLabel.text = "Upgrade Phase"
		State.GAME_OVER:
			$TurnLabel.text = "Game Over"

func update_wave_progress():
	var enemies_left = $EnemyCards.get_children().size()
	$WaveLabel.text = "Wave: " + str(current_wave + 1) + " (Enemies Left: " + str(enemies_left) + ")"
