# Data.gd (autoload)
extends Node

# Enemy types data (keeping existing for now)
var ENEMY_TYPES = {
	"Goblin": {
		"name": "Goblin",
		"image": "res://assets/enemies/goblin.png",
		"health": 10,
		"attack": 2
	},
	"OrcBoss": {
		"name": "Orc Boss",
		"image": "res://assets/enemies/orc_boss.png",
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

# Wave data (keeping existing for now)
var waves = [
	{"enemies": ["Goblin", "Goblin"]},
	{"enemies": ["Goblin", "Goblin", "Goblin"]},
	{"enemies": ["Goblin", "Slime"]},
	{"enemies": ["Slime", "Slime", "Goblin"]},
	{"enemies": ["Necromancer", "Goblin"]},
	{"enemies": ["Necromancer", "Necromancer", "OrcBoss"]},
	{"enemies": ["Slime", "Slime", "OrcBoss"]}
]

# Artifact data
# Structure:
# "Artifact Name": {
#     "rarity": "Common" | "Rare" | "Epic" | "Legendary",
#     "icon": "res://path/to/icon.png",
#     "requires_targets": true | false, # If the base ability generally requires a target selection
#     "cost": int, # Base cost, review if this is for unlock or first purchase
#     "levels": [
#         { # Level 1 (Base artifact, e.g., "Thunder Bolt")
#             "description": "User-facing description for this level",
#             "cooldown": int,
#             "effects": [
#                 {"type": "effect_type", "param1": "value1", ...},
#                 # ... other effects for this level
#             ]
#         },
#         { # Level 2 (e.g., "Thunder Bolt +1")
#             "description": "...",
#             "cooldown": int,
#             "effects": [...]
#         },
#         # ... up to Level 9 (for "+8" artifacts)
#     ]
# }

var artifacts = {
	"Thunder Bolt": {
		"rarity": "Common",
		"icon": "res://artifacts/thunder_bolt.png",
		"requires_targets": true,
		"cost": 3, # Assuming this is a base cost
		"levels": [
			{ # Level 1 (Base)
				"description": "Dano a um inimigo igual a 100% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.0}]
			},
			{ # Level 2 (+1) - Assuming same as Level 1 as +1 is not specified
				"description": "Dano a um inimigo igual a 100% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.0}]
			},
			{ # Level 3 (+2)
				"description": "Dano a um inimigo igual a 110% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.1}]
			},
			{ # Level 4 (+3)
				"description": "Dano a um inimigo igual a 120% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.2}]
			},
			{ # Level 5 (+4)
				"description": "Dano a um inimigo igual a 130% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.3}]
			},
			{ # Level 6 (+5)
				"description": "Dano a um inimigo igual a 140% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.4}]
			},
			{ # Level 7 (+6)
				"description": "Dano a um inimigo igual a 150% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.5}]
			},
			{ # Level 8 (+7)
				"description": "Dano a um inimigo igual a 160% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.6}]
			},
			{ # Level 9 (+8)
				"description": "Dano a um inimigo igual a 170% do ATK",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.7}]
			}
		]
	},
	"Healing Stone": {
		"rarity": "Common",
		"icon": "res://artifacts/healing_stone.png",
		"requires_targets": false,
		"cost": 3,
		"levels": [
			{ # Level 1 (Base)
				"description": "Cura o usuário por 50% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.5}]
			},
			{ # Level 2 (+1) - Assuming same as Level 1
				"description": "Cura o usuário por 50% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.5}]
			},
			{ # Level 3 (+2)
				"description": "Cura o usuário por 60% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.6}]
			},
			{ # Level 4 (+3)
				"description": "Cura o usuário por 70% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.7}]
			},
			{ # Level 5 (+4)
				"description": "Cura o usuário por 80% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.8}]
			},
			{ # Level 6 (+5)
				"description": "Cura o usuário por 90% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.9}]
			},
			{ # Level 7 (+6)
				"description": "Cura o usuário por 100% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 1.0}]
			},
			{ # Level 8 (+7)
				"description": "Cura o usuário por 100% do HP máximo e remove 1 debuff",
				"cooldown": 4,
				"effects": [
					{"type": "heal", "target_type": "user", "scale_with_max_hp": 1.0},
					{"type": "remove_debuffs", "target_type": "user", "count": 1}
				]
			},
			{ # Level 9 (+8)
				"description": "Cura o usuário por 100% do HP máximo e remove 2 debuffs",
				"cooldown": 4,
				"effects": [
					{"type": "heal", "target_type": "user", "scale_with_max_hp": 1.0},
					{"type": "remove_debuffs", "target_type": "user", "count": 2}
				]
			}
		]
	},
	"Rusty Blade": {
		"rarity": "Common",
		"icon": "res://artifacts/rusty_blade.png", # Placeholder - replace with actual icon path if available
		"requires_targets": true,
		"cost": 2,
		"levels": [
			{ # Level 1
				"description": "Causa 80% de dano do ATK a um inimigo",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.8}]
			},
			{ # Level 2 (+1)
				"description": "Causa 80% de dano do ATK a um inimigo",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.8}]
			},
			{ # Level 3 (+2)
				"description": "Causa 85% de dano do ATK a um inimigo",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.85}]
			},
			{ # Level 4 (+3)
				"description": "Causa 90% de dano do ATK a um inimigo",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.90}]
			},
			{ # Level 5 (+4)
				"description": "Causa 95% de dano do ATK a um inimigo",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.95}]
			},
			{ # Level 6 (+5)
				"description": "Causa 100% de dano do ATK a um inimigo",
				"cooldown": 3,
				"effects": [{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.0}]
			},
			{ # Level 7 (+6)
				"description": "Causa 105% de dano do ATK a um inimigo, 10% de chance de sangramento (5 de dano por 2 turnos)",
				"cooldown": 3,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.05},
					{"type": "apply_status_with_chance", "target_type": "single_enemy", "status_name": "bleed", "chance": 0.10, "value": 5, "duration": 2}
				]
			},
			{ # Level 8 (+7)
				"description": "Causa 110% de dano do ATK a um inimigo, 15% de chance de sangramento (5 de dano por 2 turnos)",
				"cooldown": 3,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.10},
					{"type": "apply_status_with_chance", "target_type": "single_enemy", "status_name": "bleed", "chance": 0.15, "value": 5, "duration": 2}
				]
			},
			{ # Level 9 (+8)
				"description": "Causa 115% de dano do ATK a um inimigo, 20% de chance de sangramento (5 de dano por 2 turnos)",
				"cooldown": 3,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 1.15},
					{"type": "apply_status_with_chance", "target_type": "single_enemy", "status_name": "bleed", "chance": 0.20, "value": 5, "duration": 2}
				]
			}
		]
	},
	"Worn Amulet": {
		"rarity": "Common",
		"icon": "res://artifacts/worn_amulet.png", # Placeholder
		"requires_targets": false,
		"cost": 2,
		"levels": [
			{ # Level 1
				"description": "Cura o usuário por 25% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.25}]
			},
			{ # Level 2 (+1)
				"description": "Cura o usuário por 25% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.25}]
			},
			{ # Level 3 (+2)
				"description": "Cura o usuário por 30% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.30}]
			},
			{ # Level 4 (+3)
				"description": "Cura o usuário por 35% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.35}]
			},
			{ # Level 5 (+4)
				"description": "Cura o usuário por 40% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.40}]
			},
			{ # Level 6 (+5)
				"description": "Cura o usuário por 45% do HP máximo",
				"cooldown": 4,
				"effects": [{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.45}]
			},
			{ # Level 7 (+6)
				"description": "Cura o usuário por 50% do HP máximo, 10% de chance de remover 1 debuff",
				"cooldown": 4,
				"effects": [
					{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.50},
					{"type": "remove_debuffs_with_chance", "target_type": "user", "count": 1, "chance": 0.10}
				]
			},
			{ # Level 8 (+7)
				"description": "Cura o usuário por 55% do HP máximo, 15% de chance de remover 1 debuff",
				"cooldown": 4,
				"effects": [
					{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.55},
					{"type": "remove_debuffs_with_chance", "target_type": "user", "count": 1, "chance": 0.15}
				]
			},
			{ # Level 9 (+8)
				"description": "Cura o usuário por 60% do HP máximo, 20% de chance de remover 1 debuff",
				"cooldown": 4,
				"effects": [
					{"type": "heal", "target_type": "user", "scale_with_max_hp": 0.60},
					{"type": "remove_debuffs_with_chance", "target_type": "user", "count": 1, "chance": 0.20}
				]
			}
		]
	},
	"Faded Cloak": {
		"rarity": "Common",
		"icon": "res://artifacts/faded_cloak.png", # Placeholder
		"requires_targets": false,
		"cost": 2,
		"levels": [
			{ # Level 1
				"description": "Aumenta a defesa do usuário em 10% por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.10, "duration": 2}]
			},
			{ # Level 2 (+1)
				"description": "Aumenta a defesa do usuário em 10% por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.10, "duration": 2}]
			},
			{ # Level 3 (+2)
				"description": "Aumenta a defesa do usuário em 15% por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.15, "duration": 2}]
			},
			{ # Level 4 (+3)
				"description": "Aumenta a defesa do usuário em 20% por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.20, "duration": 2}]
			},
			{ # Level 5 (+4)
				"description": "Aumenta a defesa do usuário em 25% por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.25, "duration": 2}]
			},
			{ # Level 6 (+5)
				"description": "Aumenta a defesa do usuário em 30% por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.30, "duration": 2}]
			},
			{ # Level 7 (+6)
				"description": "Aumenta a defesa do usuário em 35% por 3 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.35, "duration": 3}]
			},
			{ # Level 8 (+7)
				"description": "Aumenta a defesa do usuário em 40% por 3 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.40, "duration": 3}]
			},
			{ # Level 9 (+8)
				"description": "Aumenta a defesa do usuário em 45% por 3 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "defense_boost", "value": 0.45, "duration": 3}]
			}
		]
	},
	"Cracked Orb": {
		"rarity": "Common",
		"icon": "res://artifacts/cracked_orb.png", # Placeholder
		"requires_targets": false,
		"cost": 2,
		"levels": [
			{ # Level 1
				"description": "Causa 40% de dano do ATK a até 2 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.40, "num_targets": 2}]
			},
			{ # Level 2 (+1)
				"description": "Causa 40% de dano do ATK a até 2 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.40, "num_targets": 2}]
			},
			{ # Level 3 (+2)
				"description": "Causa 45% de dano do ATK a até 2 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.45, "num_targets": 2}]
			},
			{ # Level 4 (+3)
				"description": "Causa 50% de dano do ATK a até 2 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.50, "num_targets": 2}]
			},
			{ # Level 5 (+4)
				"description": "Causa 55% de dano do ATK a até 2 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.55, "num_targets": 2}]
			},
			{ # Level 6 (+5)
				"description": "Causa 60% de dano do ATK a até 2 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.60, "num_targets": 2}]
			},
			{ # Level 7 (+6)
				"description": "Causa 65% de dano do ATK a até 3 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.65, "num_targets": 3}]
			},
			{ # Level 8 (+7)
				"description": "Causa 70% de dano do ATK a até 3 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.70, "num_targets": 3}]
			},
			{ # Level 9 (+8)
				"description": "Causa 75% de dano do ATK a até 3 inimigos aleatórios",
				"cooldown": 3,
				"effects": [{"type": "damage_random_enemies", "scale_with_atk": 0.75, "num_targets": 3}]
			}
		]
	},

	# Raros
	"Poison Vial": {
		"rarity": "Rare",
		"icon": "res://artifacts/poison_vial.png",
		"requires_targets": true,
		"cost": 4,
		"levels": [
			{ # Level 1
				"description": "Causa 80% de dano, envenena o alvo por 3 turnos causando 5 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.80, "fixed_damage": 0}, # Assuming the "80% de dano" is ATK-based
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 5, "duration": 3}
				]
			},
			{ # Level 2 (+1)
				"description": "Causa 80% de dano, envenena o alvo por 3 turnos causando 5 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.80, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 5, "duration": 3}
				]
			},
			{ # Level 3 (+2)
				"description": "Causa 80% de dano, envenena o alvo por 3 turnos causando 7 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.80, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 7, "duration": 3}
				]
			},
			{ # Level 4 (+3)
				"description": "Causa 85% de dano, envenena o alvo por 3 turnos causando 7 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.85, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 7, "duration": 3}
				]
			},
			{ # Level 5 (+4)
				"description": "Causa 85% de dano, envenena o alvo por 3 turnos causando 9 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.85, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 9, "duration": 3}
				]
			},
			{ # Level 6 (+5)
				"description": "Causa 90% de dano, envenena o alvo por 3 turnos causando 9 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.90, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 9, "duration": 3}
				]
			},
			{ # Level 7 (+6)
				"description": "Causa 90% de dano, envenena o alvo por 3 turnos causando 11 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.90, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 11, "duration": 3}
				]
			},
			{ # Level 8 (+7)
				"description": "Causa 95% de dano, envenena o alvo por 3 turnos causando 11 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.95, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 11, "duration": 3}
				]
			},
			{ # Level 9 (+8)
				"description": "Causa 95% de dano, envenena o alvo por 3 turnos causando 13 de dano por turno",
				"cooldown": 4,
				"effects": [
					{"type": "damage", "target_type": "single_enemy", "scale_with_atk": 0.95, "fixed_damage": 0},
					{"type": "apply_status", "target_type": "single_enemy", "status_name": "poison", "value": 13, "duration": 3}
				]
			}
		]
	},
	"Iron Shield": {
		"rarity": "Rare",
		"icon": "res://artifacts/iron_shield.jpg",
		"requires_targets": false,
		"cost": 3,
		"levels": [
			{ # Level 1
				"description": "Absorve 40 de dano por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 40, "duration": 2}]
			},
			{ # Level 2 (+1)
				"description": "Absorve 40 de dano por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 40, "duration": 2}]
			},
			{ # Level 3 (+2)
				"description": "Absorve 50 de dano por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 50, "duration": 2}]
			},
			{ # Level 4 (+3)
				"description": "Absorve 60 de dano por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 60, "duration": 2}]
			},
			{ # Level 5 (+4)
				"description": "Absorve 70 de dano por 2 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 70, "duration": 2}]
			},
			{ # Level 6 (+5)
				"description": "Absorve 80 de dano por 3 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 80, "duration": 3}]
			},
			{ # Level 7 (+6)
				"description": "Absorve 90 de dano por 3 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 90, "duration": 3}]
			},
			{ # Level 8 (+7)
				"description": "Absorve 100 de dano por 3 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 100, "duration": 3}]
			},
			{ # Level 9 (+8)
				"description": "Absorve 110 de dano por 3 turnos",
				"cooldown": 4,
				"effects": [{"type": "apply_status", "target_type": "user", "status_name": "damage_absorb_shield", "value": 110, "duration": 3}]
			}
		]
	}
	# Epicos and Lendarios will be added in the next update.
}

# Rune data (structure remains for now, interaction with leveled artifacts TBD)
var runes = {
	"Double Trouble": {
		"ability": Callable(self, "double_trouble_modify"), # These Callables will need review
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
	"Poison Touch": {
		"ability": Callable(self, "poison_touch_modify"),
		"icon": "res://runes/poison_touch.png",
		"tooltip": "Adds poison effect to damage abilities",
		"cost": 2
	}
}

# Old artifact ability Callables from the previous Data.gd structure.
# These will be deprecated as Artifact.gd will use the 'effects' array.
# For now, they are commented out to avoid conflicts if not immediately removed.
# func thunder_bolt_ability(user: CardBase, targets: Array): ...
# func healing_stone_ability(user: CardBase, _targets: Array): ...
# func fire_orb_ability(user: CardBase, _targets: Array): ...
# func iron_shield_ability(user: CardBase, _targets: Array): ...
# func poison_vial_ability(user: CardBase, targets: Array): ...
# func frost_shard_ability(user: CardBase, targets: Array): ...
# func vampire_fang_ability(user: CardBase, targets: Array): ...
# func wind_gust_ability(user: CardBase, targets: Array): ...
# func lightning_chain_ability(user: CardBase, _targets: Array): ...
# func shadow_cloak_ability(user: CardBase, _targets: Array): ...
# func earth_spike_ability(user: CardBase, targets: Array): ...
# func soul_gem_ability(user: CardBase, _targets: Array): ...
# func blood_rune_ability(user: CardBase, _targets: Array): ...
# func lightning_storm_ability(user: CardBase, targets: Array): ...


# Rune modifier implementations
# These will also need to be reviewed in context of the new effect system.
# The base_ability they receive will be different.
func double_trouble_modify(base_ability_callable: Callable, user: CardBase, targets: Array):
	# This rune's logic might need to re-evaluate how 'base_ability_callable' is invoked
	# if it's now a series of effects.
	# For now, assume it triggers the original target set, then finds another.
	base_ability_callable.call(user, targets) # Original call

	# Attempt to find an additional enemy target if the primary target was an enemy
	if targets.size() > 0 and not targets[0].is_player:
		var game_manager = get_node_or_null("/root/Main/GameManager")
		if not game_manager: game_manager = get_node_or_null("/root/GameManager")
		
		if game_manager and game_manager.has_method("get_alive_enemies"):
			var all_enemies = game_manager.get_alive_enemies()
			var available_targets = all_enemies.filter(func(t): return t != targets[0] and t.health > 0)
			if available_targets.size() > 0:
				var extra_target = available_targets[randi() % available_targets.size()]
				# How to re-trigger effects on extra_target? This needs careful thought.
				# For now, let's assume base_ability_callable can be called again.
				base_ability_callable.call(user, [extra_target])
				print("Double Trouble hits an additional target!")

func power_boost_modify(base_ability_callable: Callable, user: CardBase, targets: Array):
	# This is tricky. "Effect" is broad. If it's damage, ATK boost is fine.
	# If it's healing, does it boost heal amount? If it's duration, does it boost duration?
	# For now, let's assume it primarily boosts ATK for damage-dealing abilities.
	var original_attack = user.attack
	user.attack = int(user.attack * 1.5) # Consider if this should be temp_attack_boost

	base_ability_callable.call(user, targets)

	user.attack = original_attack # Reset attack
	print("Power Boost attempts to increase the effect by 50%!")

func quick_cast_modify(base_ability_callable: Callable, user: CardBase, targets: Array):
	# The primary effect (cooldown reduction) is best handled when the rune is attached
	# and the artifact's level-specific cooldown is determined.
	# This function might just call the base ability or add a minor visual/log.
	base_ability_callable.call(user, targets)
	print("Quick Cast rune is active.")

func poison_touch_modify(base_ability_callable: Callable, user: CardBase, targets: Array):
	base_ability_callable.call(user, targets)
	# Apply poison to primary target if it's an enemy and was affected
	# This assumes the base_ability_callable might have already damaged/affected targets.
	for target in targets: # Iterate through actual targets affected by base_ability
		if target is CardBase and not target.is_player and target.health > 0:
			print("Poison Touch applying poison to: " + target.text)
			target.apply_status_effect("poison", {"duration": 2, "damage": 1}) # Example
	print("Poison Touch adds poison to the attack!")


# Enemy ability implementations (keeping existing for now)
func cleaver_attack(enemy: CardBase, targets: Array) -> void: # targets param is unused here
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager: game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.has_method("get_alive_player_cards"):
		var all_players = game_manager.get_alive_player_cards()
		if all_players.size() > 0:
			all_players.shuffle() # Ensure randomness if multiple targets
			var main_target = all_players[0]

			print("%s uses Cleaver Attack on %s!" % [enemy.text, main_target.text])
			main_target.take_damage(enemy.attack, enemy)
			
			# Hit other players for half damage (if any)
			for i in range(1, all_players.size()):
				var secondary_target = all_players[i]
				var splash_damage = max(1, enemy.attack / 2) # Ensure at least 1 damage
				print("%s's cleaver also hits %s for %d damage!" % [enemy.text, secondary_target.text, splash_damage])
				secondary_target.take_damage(splash_damage, enemy)


# Placeholder for passive abilities if they are ever moved here or expanded
# var passive_abilities = {} # Defined in globals.gd for now

func _ready():
	# Ensure passive_abilities is initialized if not already (e.g. if not an autoload yet)
	if not Engine.has_singleton("Globals") or not Globals.has("passive_abilities"):
		# This is a fallback, ideally Globals is an autoload and has passive_abilities
		var temp_passive_abilities = {
			# Example: Globals.CardType.PALADIN: {"name": "Divine Intervention", "description": "..."}
		}
		# If Globals exists but misses the var, try to add it (less ideal)
		if Engine.has_singleton("Globals") and not Globals.has("passive_abilities"):
			Globals.passive_abilities = temp_passive_abilities
		elif not Engine.has_singleton("Globals"):
			# If Globals doesn't exist at all, this Data.gd might hold them, or it's an error.
			# For now, let's assume Globals should provide this.
			pass # print("Warning: Globals singleton not found for passive_abilities.")

	print("Data.gd loaded. Artifact count: %s" % len(artifacts.keys()))
