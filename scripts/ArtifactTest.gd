# ArtifactTest.gd
# Simple test script to verify artifact and rune functionality
extends Node

func test_artifact_creation():
	print("=== Testing Artifact Creation ===")
	
	# Test creating artifacts
	var thunder_bolt = ArtifactFactory.create_artifact("Thunder Bolt")
	if thunder_bolt:
		print("✓ Thunder Bolt artifact created successfully")
		print("  - Name: %s" % thunder_bolt.name)
		print("  - Cooldown: %d" % thunder_bolt.cooldown)
		print("  - Requires targets: %s" % thunder_bolt.requires_targets)
		print("  - Rarity: %s" % thunder_bolt.rarity) # Check rarity
		if thunder_bolt.rarity == null or thunder_bolt.rarity.is_empty():
			print("  ✗ WARN: Thunder Bolt rarity is not set!")
	else:
		print("✗ Failed to create Thunder Bolt artifact")
	
	# Test creating runes
	var power_boost = ArtifactFactory.create_rune("Power Boost")
	if power_boost:
		print("✓ Power Boost rune created successfully")
		print("  - Name: %s" % power_boost.name)
	else:
		print("✗ Failed to create Power Boost rune")
	
	# Test attaching rune to artifact
	if thunder_bolt and power_boost:
		thunder_bolt.attach_rune(power_boost)
		print("✓ Rune attached to artifact successfully")
	
	print("=== Test Complete ===\n")

func test_all_artifacts():
	print("=== Testing All Artifacts ===")
	
	var artifact_names = ArtifactFactory.get_all_artifact_names()
	for artifact_name in artifact_names:
		var artifact = ArtifactFactory.create_artifact(artifact_name)
		if artifact:
			print("✓ %s - Cooldown: %d, Targets: %s, Rarity: %s" % [artifact_name, artifact.cooldown, artifact.requires_targets, artifact.rarity])
			if artifact.rarity == null or artifact.rarity.is_empty():
				print("  ✗ WARN: %s rarity is not set!" % artifact_name)
		else:
			print("✗ Failed to create %s" % artifact_name)
	
	print("=== Test Complete ===\n")

func test_all_runes():
	print("=== Testing All Runes ===")
	
	var rune_names = ArtifactFactory.get_all_rune_names()
	for rune_name in rune_names:
		var rune = ArtifactFactory.create_rune(rune_name)
		if rune:
			print("✓ %s created successfully" % rune_name)
		else:
			print("✗ Failed to create %s" % rune_name)
	
	print("=== Test Complete ===\n")

func _ready():
	# Run tests when the script is loaded
	test_artifact_creation()
	test_all_artifacts()
	test_all_runes()
