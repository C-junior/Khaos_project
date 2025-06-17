# Artifact and Rune Implementation Guide

This guide explains how to add new artifacts and runes to the game system.

## System Overview

The artifact and rune system consists of several components:
- **Artifact.gd**: The artifact class that handles ability execution and cooldowns
- **Rune.gd**: The rune class that modifies artifact abilities
- **Data.gd**: Contains all artifact and rune definitions and their implementations
- **ArtifactFactory.gd**: Factory class for creating artifacts and runes
- **CardBase.gd**: The card class that uses artifacts and handles status effects

## Adding a New Artifact

### Step 1: Add Artifact Data
In `Data.gd`, add your artifact to the `artifacts` dictionary:

```gdscript
"My New Artifact": {
	"ability": Callable(self, "my_new_artifact_ability"),
	"icon": "res://artifacts/my_new_artifact.png",
	"cooldown": 3,
	"requires_targets": true,  # or false if it doesn't need targets
	"tooltip": "Description of what the artifact does",
	"cost": 4  # Cost to purchase/upgrade
}
```

### Step 2: Implement the Ability Function
In `Data.gd`, add the ability implementation:

```gdscript
func my_new_artifact_ability(user: CardBase, targets: Array):
	# Your ability implementation here
	if targets.size() > 0:
		# Example: Deal damage to target
		targets[0].take_damage(user.attack * 2, user)
		print("%s uses My New Artifact on %s!" % [user.text, targets[0].text])
```

### Step 3: Add Icon Asset
Place your artifact icon in the `res://artifacts/` folder with the filename specified in step 1.

## Adding a New Rune

### Step 1: Add Rune Data
In `Data.gd`, add your rune to the `runes` dictionary:

```gdscript
"My New Rune": {
	"ability": Callable(self, "my_new_rune_modify"),
	"icon": "res://runes/my_new_rune.png",
	"tooltip": "Description of how the rune modifies abilities",
	"cost": 2
}
```

### Step 2: Implement the Modifier Function
In `Data.gd`, add the rune modifier implementation:

```gdscript
func my_new_rune_modify(base_ability: Callable, user: CardBase, targets: Array):
	# Modify the ability behavior here
	# Example: Apply a status effect before the ability
	if targets.size() > 0:
		targets[0].apply_status_effect("poison_turns", 2)
	
	# Call the original ability
	base_ability.call(user, targets)
	
	# You can also do something after the ability
	print("My New Rune enhances the ability!")
```

### Step 3: Add Icon Asset
Place your rune icon in the `res://runes/` folder with the filename specified in step 1.

## Status Effects System

The game supports various status effects that can be applied to cards:

### Available Status Effects:
- `poison_turns`: Number of turns the card takes poison damage
- `poison_damage`: Amount of poison damage per turn
- `shield`: Amount of damage blocked by shield
- `is_frozen`: Whether the card skips its next turn
- `attack_delay`: Number of turns the card cannot attack
- `is_invisible`: Whether the card cannot be targeted
- `attack_boost`: Temporary attack increase
- `shield_active`: Whether Iron Shield effect is active

### Applying Status Effects:
```gdscript
# Apply poison for 3 turns
target.apply_status_effect("poison_turns", 3)

# Freeze the target
target.apply_status_effect("is_frozen", true)

# Give temporary attack boost
user.apply_status_effect("attack_boost", user.base_attack)
```

## Ability Types and Patterns

### Damage Abilities
```gdscript
func damage_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		targets[0].take_damage(damage_amount, user)
```

### Healing Abilities
```gdscript
func healing_ability(user: CardBase, _targets: Array):
	user.heal(heal_amount)
```

### Status Effect Abilities
```gdscript
func status_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		targets[0].apply_status_effect("effect_name", value)
```

### Area of Effect Abilities
```gdscript
func aoe_ability(user: CardBase, targets: Array):
	for target in targets:
		target.take_damage(damage_amount, user)
```

### Self-Buff Abilities
```gdscript
func buff_ability(user: CardBase, _targets: Array):
	user.apply_status_effect("attack_boost", boost_amount)
```

## Rune Modifier Patterns

### Damage Enhancement
```gdscript
func damage_boost_modify(base_ability: Callable, user: CardBase, targets: Array):
	var original_attack = user.attack
	user.attack = int(user.attack * 1.5)
	base_ability.call(user, targets)
	user.attack = original_attack
```

### Additional Effects
```gdscript
func additional_effect_modify(base_ability: Callable, user: CardBase, targets: Array):
	base_ability.call(user, targets)
	# Add extra effect after the ability
	if targets.size() > 0:
		targets[0].apply_status_effect("poison_turns", 2)
```

### Target Multiplication
```gdscript
func multi_target_modify(base_ability: Callable, user: CardBase, targets: Array):
	base_ability.call(user, targets)
	# Hit additional targets
	var all_enemies = GameManager.get_alive_enemies()
	var extra_targets = all_enemies.filter(func(t): return not t in targets)
	if extra_targets.size() > 0:
		base_ability.call(user, [extra_targets[0]])
```

## Using the Factory System

### Creating Artifacts
```gdscript
# Create an artifact
var artifact = ArtifactFactory.create_artifact("Thunder Bolt")

# Attach to a card
card.artifact = artifact

# Attach a rune to the artifact
ArtifactFactory.attach_rune_to_artifact(artifact, "Power Boost")
```

### Getting Available Items
```gdscript
# Get all artifact names
var artifact_names = ArtifactFactory.get_all_artifact_names()

# Get artifact info for UI
var artifact_info = ArtifactFactory.get_artifact_info("Thunder Bolt")
print(artifact_info.tooltip)  # Display tooltip
```

## Testing Your Implementation

1. **Test the artifact alone**: Make sure it works without runes
2. **Test with different runes**: Verify rune modifications work correctly
3. **Test edge cases**: Empty target arrays, dead targets, etc.
4. **Test status effects**: Ensure they apply and remove correctly
5. **Test cooldowns**: Verify the artifact respects cooldown periods

## Common Pitfalls

1. **Forgetting to check target validity**: Always check if targets exist and are alive
2. **Not handling empty target arrays**: Use `if targets.size() > 0:` checks
3. **Modifying permanent stats**: Use temporary boosts instead of permanent changes
4. **Forgetting to call `update_labels()`**: Status changes should update the UI
5. **Not considering rune interactions**: Test how your artifact works with all runes

## Example: Complete Implementation

Here's a complete example of adding a new artifact called "Lightning Storm":

```gdscript
# In Data.gd artifacts dictionary:
"Lightning Storm": {
	"ability": Callable(self, "lightning_storm_ability"),
	"icon": "res://artifacts/lightning_storm.png",
	"cooldown": 4,
	"requires_targets": true,
	"tooltip": "Deals 3 damage to target and 1 damage to all other enemies",
	"cost": 5
}

# In Data.gd ability implementations:
func lightning_storm_ability(user: CardBase, targets: Array):
	if targets.size() > 0:
		var primary_target = targets[0]
		# Deal main damage to primary target
		primary_target.take_damage(3, user)
		
		# Deal splash damage to all other enemies
		var all_enemies = GameManager.get_alive_enemies()
		for enemy in all_enemies:
			if enemy != primary_target:
				enemy.take_damage(1, user)
		
		print("%s unleashes Lightning Storm!" % user.text)
```

This artifact would work with all existing runes:
- **Power Boost**: Would increase both primary and splash damage
- **Double Trouble**: Would hit an additional random enemy with the full effect
- **Quick Cast**: Would reduce the cooldown from 4 to 3 turns
extends Button
class_name CardBase

signal died(card)
signal ability_used(card)
signal stats_changed(card)
signal status_effect_applied(card, effect_type)

# Core properties
var type: String
var is_player: bool
var has_attacked: bool = false
var ability_used: bool = false

# Stats - Using direct properties for compatibility
var health: int = 0
var max_health: int = 0
var attack: int = 0
var base_attack: int = 0  # Store original attack for temporary modifications

# Status effects
var status_effects = {
	"poison_turns": 0,
	"poison_damage": 1,
	"shield": 0,
	"is_frozen": false,
	"attack_delay": 0,
	"is_invisible": false,
	"attack_boost": 0,
	"shield_active": false
}

# Spell tracking for mage
var spell_count: int = 0

# Artifact
var artifact: Artifact = null

# UI References
@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel
@onready var attack_label = $AttackLabel
@onready var ability_button = $AbilityButton

func _ready() -> void:
	setup_ui()
	connect_signals()
	update_appearance()
	base_attack = attack  # Store original attack value

func setup_ui() -> void:
	if not is_player:
		ability_button.hide()
	update_labels()

func connect_signals() -> void:
	mouse_entered.connect(_on_card_hover)
	mouse_exited.connect(_on_hover_exit)
	if ability_button:
		ability_button.pressed.connect(_on_ability_button_pressed)

func update_appearance() -> void:
	if type in Data.ENEMY_TYPES:
		text = Data.ENEMY_TYPES[type].name
		icon = load(Data.ENEMY_TYPES[type].sprite)
	else:
		text = type.capitalize()
		# Load player character sprite

func take_damage(amount: int, attacker = null) -> void:
	# Check for invisibility
	if status_effects.is_invisible:
		print("%s is invisible and cannot be targeted!" % text)
		return
	
	# Apply shield
	if status_effects.shield > 0:
		var blocked = mini(status_effects.shield, amount)
		amount -= blocked
		status_effects.shield -= blocked
		print("%s's shield blocks %d damage!" % [text, blocked])
	
	# Apply shield_active (Iron Shield effect)
	if status_effects.shield_active:
		amount = max(0, amount - 2)
		status_effects.shield_active = false
		print("%s's iron shield reduces damage by 2!" % text)
	
	health -= amount
	health = max(0, health)
	stats_changed.emit(self)
	update_labels()
	
	if health <= 0:
		died.emit(self)

func attack_target(target) -> void:
	if has_attacked or health <= 0:
		return
	
	var damage = attack + status_effects.attack_boost
	target.take_damage(damage, self)
	has_attacked = true
	
	# Reset temporary attack boost
	if status_effects.attack_boost > 0:
		status_effects.attack_boost = 0
		attack = base_attack

func use_ability(targets = null) -> void:
	if artifact and artifact.can_use():
		artifact.use(self, targets if targets else [])
		ability_used.emit(self)

func apply_status_effect(effect: String, value) -> void:
	status_effects[effect] = value
	status_effect_applied.emit(self, effect)
	update_labels()

func apply_poison() -> void:
	if status_effects.poison_turns > 0:
		take_damage(status_effects.poison_damage)
		status_effects.poison_turns -= 1
		print("%s takes %d poison damage! (%d turns remaining)" % [text, status_effects.poison_damage, status_effects.poison_turns])

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	update_labels()
	print("%s heals for %d health!" % [text, amount])

func update_labels() -> void:
	if health_label:
		health_label.text = str(health) + "/" + str(max_health)
	if attack_label:
		var display_attack = attack + status_effects.attack_boost
		attack_label.text = str(display_attack)
	if health_bar:
		health_bar.value = float(health) / max_health * 100

func _on_card_hover() -> void:
	var tooltip = get_node("/root/Tooltip")
	if tooltip:
		tooltip.set_card_data(
			text,
			health,
			max_health,
			attack,
			Data.passive_abilities.get(type, {}),
			artifact.name if artifact else "",
			artifact.current_cooldown if artifact else 0
		)

func _on_hover_exit() -> void:
	var tooltip = get_node("/root/Tooltip")
	if tooltip:
		tooltip.hide()

func _on_ability_button_pressed() -> void:
	if artifact and artifact.can_use():
		GameManager.on_ability_pressed(self)
