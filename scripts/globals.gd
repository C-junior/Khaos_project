# Globals.gd
extends Node

enum CardType { 
    PALADIN,    # 0
    MAGE,       # 1
    KNIGHT,     # 2 (Existing, often referred to as Warrior)
    ARCHER,     # 3
    CLERIC,     # 4
    ASSASSIN,   # 5 (replaces ROGUE)
    BERSERKER,  # 6
    NECRODANCER,# 7
    GUARDIAN,   # 8
    ENEMY,      # 9
    BOSS        # 10
}

var selected_characters: Array = [] # Declare the variable
var game_has_started: bool = false # Flag to indicate if the game has been started from character selection
