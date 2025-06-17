# Artifact.gd
extends Resource
class_name Artifact

var name: String
var base_ability: Callable
var cooldown: int
var current_cooldown: int = 0
var rune: Rune = null
var requires_targets: bool
var tooltip: String

func _init(_name: String = "", _base_ability: Callable = Callable(), _cooldown: int = 0, _requires_targets: bool = false, _tooltip: String = ""):
	name = _name
	base_ability = _base_ability
	cooldown = _cooldown
	requires_targets = _requires_targets
	tooltip = _tooltip

func attach_rune(_rune: Rune):
	rune = _rune
	if rune and rune.name == "Quick Cast":
		cooldown = max(1, cooldown - 1)

func can_use() -> bool:
	return current_cooldown <= 0

func use(user: CardBase, targets: Array):
	if current_cooldown > 0:
		print("%s is on cooldown for %d turns." % [name, current_cooldown])
		return
	
	print("%s uses %s." % [user.text, name])
	
	var modified_ability = base_ability
	if rune:
		modified_ability = rune.modify(base_ability)
	
	# Handle Mage's Arcane Echo passive
	if user.type == Globals.CardType.MAGE:
		user.spell_count += 1
		if user.spell_count % 3 == 0:
			print("%s's Arcane Echo doubles the effect!" % user.text)
			var original_ability = modified_ability
			modified_ability = func(u, t): 
				original_ability.call(u, t)
				original_ability.call(u, t)
	
	modified_ability.call(user, targets)
	current_cooldown = cooldown
	user.update_labels()

# Alias for backward compatibility
func activate(user: CardBase, targets: Array):
	use(user, targets)

func turn_end():
	if current_cooldown > 0:
		current_cooldown -= 1
