# Rune.gd
extends Resource
class_name Rune

var name: String
var modify_func: Callable

func _init(_name: String, _modify_func: Callable):
	name = _name
	modify_func = _modify_func

func modify(base_ability: Callable) -> Callable:
	return func(user, targets): modify_func.call(base_ability, user, targets)
