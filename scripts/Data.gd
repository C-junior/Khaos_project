# Data.gd (autoload)
extends Node

# Add missing properties for compatibility
var passive_abilities = {}

# Enemy types data
var ENEMY_TYPES = {
	"Goblin": {
		"name": "Goblin",
		"image": "res://assets/enemies/goblin.png", # Placeholder - replace with actual image if available
		"health": 10,
		"attack": 2
	},
	"OrcBoss": {
		"name": "Orc Boss",
		"image": "res://assets/enemies/orc_boss.png", # Placeholder - replace with actual image if available
		"ability": "cleaver_attack",
		"health": 40,
		"attack": 6
	},
	"Necromancer": {
		"name": "Necromancer",
		"image": "res://assets/enemies/necromancer.jpg",
		"health": 10,
		"attack": 5
	},
	"Slime": {
		"name": "Slime",
		"image": "res://assets/enemies/slime.jpg",
		"health": 18,
		"attack": 2
	}
	# Add more enemies below this line
}

# Artifact data: name -> {ability: Callable, icon: String, cooldown: int, requires_targets: bool, tooltip: String}

var artifacts = {
	"Thunder Bolt": {
		"ability": Callable(self, "thunder_bolt_ability"),
		"icon": "res://artifacts/thunder_bolt.png",
		"cooldown": 2,
		"requires_targets": true,
		"tooltip": "Deals full attack damage to one enemy",
		"cost": 3
	},
	"Healing Stone": {
		"ability": Callable(self, "healing_stone_ability"),
		"icon": "res://artifacts/healing_stone.png",
		"cooldown": 3,
		"requires_targets": false,
		"tooltip": "Heals this card for 5 health",
		"cost": 3
	},
	"Fire Orb": {
		"ability": Callable(self, "fire_orb_ability"),
		"icon": "res://artifacts/fire_orb.png",
		"cooldown": 3,
		"requires_targets": false,
		"tooltip": "Deals half attack damage to all enemies",
		"cost": 4
	},
	"Iron Shield": {
		"ability": Callable(self, "iron_shield_ability"),
		"icon": "res://artifacts/iron_shield.jpg",
		"cooldown": 2,
		"requires_targets": false,
		"tooltip": "Reduces next damage taken by 2",
		"cost": 2
	},
	"Poison Vial": {
		"ability": Callable(self, "poison_vial_ability"),
		"icon": "res://artifacts/poison_vial.png",
		"cooldown": 3,
		"requires_targets": true,
		"tooltip": "Poisons an enemy for 1 damage/turn (3 turns)",
		"cost": 3
	},
	"Frost Shard": {
		"ability": Callable(self, "frost_shard_ability"),
		"icon": "res://artifacts/frost_shard.png",
		"cooldown": 2,
		"requires_targets": true,
		"tooltip": "Freezes an enemy, skipping its next turn",
		"cost": 3
	},
	"Vampire Fang": {
		"ability": Callable(self, "vampire_fang_ability"),
		"icon": "res://artifacts/vampire_fang.png",
		"cooldown": 3,
		"requires_targets": true,
		"tooltip": "Steals 3 health from an enemy",
		"cost": 4
	},
	"Wind Gust": {
		"ability": Callable(self, "wind_gust_ability"),
		"icon": "res://artifacts/wind_gust.jpg",
		"cooldown": 2,
		"requires_targets": true,
		"tooltip": "Delays an enemy's attack by 1 turn",
		"cost": 2
	},
	"Lightning Chain": {
		"ability": Callable(self, "lightning_chain_ability"),
		"icon": "res://artifacts/lightning_chain.png",
		"cooldown": 4,
		"requires_targets": false,
		"tooltip": "Deals half attack to 2 random enemies",
		"cost": 5
	},
	"Shadow Cloak": {
		"ability": Callable(self, "shadow_cloak_ability"),
		"icon": "res://artifacts/shadow_cloak.png",
		"cooldown": 3,
		"requires_targets": false,
		"tooltip": "Makes this card untouchable for one turn",
		"cost": 4
	},
	"Earth Spike": {
		"ability": Callable(self, "earth_spike_ability"),
		"icon": "res://artifacts/earth_spike.png",
		"cooldown": 2,
		"requires_targets": true,
		"tooltip": "Deals 4 damage to one enemy",
		"cost": 3
	},
	"Soul Gem": {
		"ability": Callable(self, "soul_gem_ability"),
		"icon": "res://artifacts/soul_gem.png",
		"cooldown": 5,
		"requires_targets": false,
		"tooltip": "Revives a fallen card with half health",
		"cost": 5
	},
	"Blood Rune": {
		"ability": Callable(self, "blood_rune_ability"),
		"icon": "res://artifacts/blood_rune.png",
		"cooldown": 3,
		"requires_targets": false,
		"tooltip": "Doubles attack for one turn",
		"cost": 4
	},
	# Example new artifact - Lightning Storm
	"Lightning Storm": {
		"ability": Callable(self, "lightning_storm_ability"),
		"icon": "res://artifacts/lightning_storm.png",
		"cooldown": 4,
		"requires_targets": true,
		"tooltip": "Deals 3 damage to target and 1 damage to all other enemies",
		"cost": 5
	}
}
# Rune data: name -> {ability: Callable, icon: String, tooltip: String, cost: int}
var runes = {
	"Double Trouble": {
		"ability": Callable(self, "double_trouble_modify"),
		"icon": "res://runes/double_trouble.png",
		"tooltip": "Hits an additional random enemy",
		"cost": 2
	},
	"Power Boost": {
		"ability": Callable(self, "power_boost_modify"),
		"icon": "res://runes/power_boost.png",
		"tooltip": "Increases effect by 50%",
		"cost": 3
	},
	"Quick Cast": {
		"ability": Callable(self, "quick_cast_modify"),
		"icon": "res://runes/quick_cast.png",
		"tooltip": "Reduces cooldown by 1 turn",
		"cost": 1
	},
	# Example new rune - Poison Touch
	"Poison Touch": {
		"ability": Callable(self, "poison_touch_modify"),
		"icon": "res://runes/poison_touch.png",
		"tooltip": "Adds poison effect to damage abilities",
		"cost": 2
	}
}

# Wave data: array of waves, each with enemies
var waves = [
	{"enemies": ["Goblin", "Goblin"]},
	{"enemies": ["Goblin", "Goblin", "Goblin"]},
	{"enemies": ["Goblin", "Slime"]},
	{"enemies": ["Slime", "Slime", "Goblin"]},
	{"enemies": ["Necromancer", "Goblin"]},
	{"enemies": ["Necromancer", "Necromancer", "OrcBoss"]},
	{"enemies": ["Slime", "Slime", "OrcBoss"]}
]
# Artifact ability implementations
func thunder_bolt_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		targets[0].take_damage(user.attack, user)

func healing_stone_ability(user: CardBase, _targets: Array):
	user.heal(5)

func fire_orb_ability(user: CardBase, _targets: Array):
	# Fire Orb hits all enemies automatically - no targets needed
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.has_method("get_alive_enemies"):
		var all_enemies = game_manager.get_alive_enemies()
		var damage = max(1, user.attack / 2)  # Ensure at least 1 damage
		for enemy in all_enemies:
			enemy.take_damage(damage, user)
		print("%s unleashes Fire Orb, hitting %d enemies for %d damage each!" % [user.text, all_enemies.size(), damage])
	else:
		print("Error: Could not find GameManager for Fire Orb ability")

func iron_shield_ability(user: CardBase, _targets: Array):
	user.apply_status_effect("shield_active", true)
	print("%s activates Iron Shield!" % user.text)

func poison_vial_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		targets[0].apply_status_effect("poison_turns", 3)
		targets[0].apply_status_effect("poison_damage", 1)
		print("%s poisons %s!" % [user.text, targets[0].text])

func frost_shard_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		targets[0].apply_status_effect("is_frozen", true)
		print("%s freezes %s!" % [user.text, targets[0].text])

func vampire_fang_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		var heal_amount = min(3, user.max_health - user.health)
		targets[0].take_damage(heal_amount, user)
		user.heal(heal_amount)
		print("%s steals %d health from %s!" % [user.text, heal_amount, targets[0].text])

func wind_gust_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		targets[0].apply_status_effect("attack_delay", 1)
		print("%s delays %s's attack!" % [user.text, targets[0].text])

func lightning_chain_ability(user: CardBase, _targets: Array):
	# Lightning Chain hits random enemies automatically - no targets needed
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.has_method("get_alive_enemies"):
		var all_enemies = game_manager.get_alive_enemies()
		if all_enemies.size() > 0:
			var count = min(2, all_enemies.size())
			var damage = max(1, user.attack / 2)  # Ensure at least 1 damage
			# Shuffle the array to get random targets
			all_enemies.shuffle()
			for i in range(count):
				all_enemies[i].take_damage(damage, user)
			print("%s hits %d enemies with Lightning Chain for %d damage each!" % [user.text, count, damage])
		else:
			print("%s's Lightning Chain finds no targets!" % user.text)
	else:
		print("Error: Could not find GameManager for Lightning Chain ability")

func shadow_cloak_ability(user: CardBase, _targets: Array):
	user.apply_status_effect("is_invisible", true)
	print("%s becomes invisible!" % user.text)

func earth_spike_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		targets[0].take_damage(4, user)

func soul_gem_ability(user: CardBase, _targets: Array):
	# This needs to be handled by the game manager as it requires access to the scene
	print("%s attempts to revive a fallen ally!" % user.text)
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.has_method("revive_fallen_card"):
		game_manager.revive_fallen_card()
	else:
		print("Error: Could not find GameManager for Soul Gem ability")

func blood_rune_ability(user: CardBase, _targets: Array):
	user.apply_status_effect("attack_boost", user.base_attack)
	print("%s doubles their attack power!" % user.text)

# Example new artifact implementation
func lightning_storm_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		var primary_target = targets[0]
		# Deal main damage to primary target
		primary_target.take_damage(3, user)
		
		# Deal splash damage to all other enemies
		var game_manager = get_node_or_null("/root/Main/GameManager")
		if not game_manager:
			game_manager = get_node_or_null("/root/GameManager")
		
		if game_manager and game_manager.has_method("get_alive_enemies"):
			var all_enemies = game_manager.get_alive_enemies()
			for enemy in all_enemies:
				if enemy != primary_target:
					enemy.take_damage(1, user)
		
		print("%s unleashes Lightning Storm!" % user.text)

# Rune modifier implementations
func double_trouble_modify(base_ability: Callable, user: CardBase, targets: Array):
	base_ability.call(user, targets)
	# Find additional targets for offensive abilities
	if targets.size() > 0 and not targets[0].is_player:
		var game_manager = get_node_or_null("/root/Main/GameManager")
		if not game_manager:
			game_manager = get_node_or_null("/root/GameManager")
		
		if game_manager and game_manager.has_method("get_alive_enemies"):
			var all_enemies = game_manager.get_alive_enemies()
			var available_targets = all_enemies.filter(func(t): return t != targets[0] and t.health > 0)
			if available_targets.size() > 0:
				var extra_target = available_targets[randi() % available_targets.size()]
				base_ability.call(user, [extra_target])
				print("Double Trouble hits an additional target!")

func power_boost_modify(base_ability: Callable, user: CardBase, targets: Array):
	var original_attack = user.attack
	user.attack = int(user.attack * 1.5)
	base_ability.call(user, targets)
	user.attack = original_attack
	print("Power Boost increases the effect by 50%!")

func quick_cast_modify(base_ability: Callable, user: CardBase, targets: Array):
	base_ability.call(user, targets)
	# The cooldown reduction is handled in attach_rune

# Example new rune implementation
func poison_touch_modify(base_ability: Callable, user: CardBase, targets: Array):
	base_ability.call(user, targets)
	# Add poison effect to any targets that took damage
	for target in targets:
		if not target.is_player and target.health > 0:
			target.apply_status_effect("poison_turns", 2)
			target.apply_status_effect("poison_damage", 1)
	print("Poison Touch adds poison to the attack!")

# Helper functions
func get_artifact_cooldown(artifact_name: String) -> int:
	return artifacts[artifact_name]["cooldown"]

func get_artifact_requires_targets(artifact_name: String) -> bool:
	return artifacts[artifact_name]["requires_targets"]
	
func get_artifact_cost(artifact_name: String) -> bool:
	return artifacts[artifact_name]["cost"]

# Upgrade costs
var health_upgrade_cost = 1
var attack_upgrade_cost = 1

# Enemy ability implementations
func cleaver_attack(enemy: CardBase, targets: Array) -> void:
	# Cleaver attack hits the main target for full damage and adjacent targets for half damage
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.has_method("get_alive_player_cards"):
		var all_players = game_manager.get_alive_player_cards()
		if all_players.size() > 0:
			# Choose a random target
			var main_target = all_players[randi() % all_players.size()]
			main_target.take_damage(enemy.attack, enemy)
			print("%s uses Cleaver Attack on %s!" % [enemy.text, main_target.text])
			
			# Hit adjacent targets for half damage
			for player in all_players:
				if player != main_target:
					player.take_damage(enemy.attack / 2, enemy)
					print("%s's cleaver also hits %s for %d damage!" % [enemy.text, player.text, enemy.attack / 2])
