extends Node

signal state_changed(new_state, old_state)
signal wave_changed(new_wave)
signal upgrade_points_changed(points)

enum State {
	PLAYER_TURN,
	ENEMY_TURN,
	UPGRADE_PHASE,
	GAME_OVER
}

var current_state: int = State.PLAYER_TURN:
	set(value):
		var old_state = current_state
		current_state = value
		state_changed.emit(value, old_state)

var current_wave: int = 0:
	set(value):
		current_wave = value
		wave_changed.emit(value)

var upgrade_points: int = 0:
	set(value):
		upgrade_points = value
		upgrade_points_changed.emit(value)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_player_turn() -> bool:
	return current_state == State.PLAYER_TURN

func is_enemy_turn() -> bool:
	return current_state == State.ENEMY_TURN

func is_upgrade_phase() -> bool:
	return current_state == State.UPGRADE_PHASE

func is_game_over() -> bool:
	return current_state == State.GAME_OVER
