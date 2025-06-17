extends Node

signal game_loaded
signal character_unlocked(char_type)
signal khaos_gems_changed(amount)

const SAVE_PATH = "user://game_save.json"
const SAVE_VERSION = 1

var player_data = {
	"characters": {},
	"khaos_gems": 0,
	"current_wave": 0,
	"unlocked_artifacts": []
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var save_data = {
		"version": SAVE_VERSION,
		"player_data": player_data,
	}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_initialize_default_data()
		return
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not save_file:
		return
		
	var save_data = JSON.parse_string(save_file.get_as_text())
	if validate_save_data(save_data):
		player_data = save_data.player_data
		game_loaded.emit()

func validate_save_data(save_data: Dictionary) -> bool:
	if not save_data.has("version") or save_data.version != SAVE_VERSION:
		return false
	if not save_data.has("player_data"):
		return false
	return true

func _initialize_default_data() -> void:
	player_data.characters = {
		"Knight": {"health": 10, "attack": 2, "unlocked": true},
		"Mage": {"health": 8, "attack": 3, "unlocked": true},
		"Paladin": {"health": 12, "attack": 1, "unlocked": true},
		"Rogue": {"health": 7, "attack": 4, "unlocked": false},
		"Warlock": {"health": 9, "attack": 3, "unlocked": false}
	}
	save_game()

func unlock_character(char_type: String) -> void:
	if char_type in player_data.characters:
		player_data.characters[char_type].unlocked = true
		save_game()
		character_unlocked.emit(char_type)

func add_khaos_gems(amount: int) -> void:
	player_data.khaos_gems += amount
	save_game()
	khaos_gems_changed.emit(player_data.khaos_gems)

func get_khaos_gems() -> int:
	return player_data.khaos_gems

func is_character_unlocked(char_type: String) -> bool:
	return player_data.characters.get(char_type, {}).get("unlocked", false)

func get_character_stats(char_type: String) -> Dictionary:
	return player_data.characters.get(char_type, {})
