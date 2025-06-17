# ArtifactFactory.gd
extends Node
class_name ArtifactFactory

# Factory method to create artifacts
static func create_artifact(artifact_name: String) -> Artifact:
	if not Data.artifacts.has(artifact_name):
		print("Error: Artifact '%s' not found in data!" % artifact_name)
		return null
	
	var artifact_data = Data.artifacts[artifact_name]
	var artifact = Artifact.new(
		artifact_name,
		artifact_data.ability,
		artifact_data.cooldown,
		artifact_data.requires_targets,
		artifact_data.tooltip
	)
	
	return artifact

# Factory method to create runes
static func create_rune(rune_name: String) -> Rune:
	if not Data.runes.has(rune_name):
		print("Error: Rune '%s' not found in data!" % rune_name)
		return null
	
	var rune_data = Data.runes[rune_name]
	var rune = Rune.new(
		rune_name,
		rune_data.ability
	)
	
	return rune

# Helper method to attach a rune to an artifact
static func attach_rune_to_artifact(artifact: Artifact, rune_name: String) -> bool:
	var rune = create_rune(rune_name)
	if rune:
		artifact.attach_rune(rune)
		return true
	return false

# Get all available artifact names
static func get_all_artifact_names() -> Array:
	return Data.artifacts.keys()

# Get all available rune names
static func get_all_rune_names() -> Array:
	return Data.runes.keys()

# Get artifact info for UI display
static func get_artifact_info(artifact_name: String) -> Dictionary:
	if Data.artifacts.has(artifact_name):
		return Data.artifacts[artifact_name]
	return {}

# Get rune info for UI display
static func get_rune_info(rune_name: String) -> Dictionary:
	if Data.runes.has(rune_name):
		return Data.runes[rune_name]
	return {}
