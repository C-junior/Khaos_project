extends Node

signal card_attacked(attacker, defender)
signal card_died(card)
signal ability_used(card, targets)

var player_cards: Array = []
var enemy_cards: Array = []

func register_player_card(card: Card) -> void:
	player_cards.append(card)
	_connect_card_signals(card)

func register_enemy_card(card: Card) -> void:
	enemy_cards.append(card)
	_connect_card_signals(card)

func remove_card(card: Card) -> void:
	if card.is_player:
		player_cards.erase(card)
	else:
		enemy_cards.erase(card)
	card_died.emit(card)

func perform_attack(attacker: Card, defender: Card) -> void:
	if not _is_valid_attack(attacker, defender):
		return
		
	attacker.attack_target(defender)
	card_attacked.emit(attacker, defender)

func use_ability(card: Card, targets: Array = []) -> void:
	if card.artifact:
		card.use_ability(targets)
		ability_used.emit(card, targets)

func reset_player_attacks() -> void:
	for card in player_cards:
		card.has_attacked = false

func are_all_enemies_dead() -> bool:
	return enemy_cards.all(func(card): return card.health <= 0)

func are_all_players_dead() -> bool:
	return player_cards.all(func(card): return card.health <= 0)

func _connect_card_signals(card: Card) -> void:
	card.died.connect(_on_card_died)

func _on_card_died(card: Card) -> void:
	remove_card(card)

func _is_valid_attack(attacker: Card, defender: Card) -> bool:
	return not attacker.has_attacked and attacker.health > 0 and defender.health > 0
