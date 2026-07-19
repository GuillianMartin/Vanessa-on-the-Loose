extends Node
# SKILLS
# Purchasable one-shot abilities with a money cost and timed duration.
# Effects are applied by Game.gd when a skill button is pressed.

const ICON_PATH := "res://assets/icon/Skills/%s.png"

enum SkillType {
	MEGA_SWATTER,
	INSTANT_ENERGY,
	FRESH_GOODS,
	BIG_FAN,
}

# id -> skill definition
static func get_skill_definitions() -> Dictionary:
	return {
		"mega_swatter": {
			"id": "mega_swatter",
			"name": "Mega Swatter",
			"type": SkillType.MEGA_SWATTER,
			"icon": ICON_PATH % "mega_swatter",
			"cost": 100,
			"duration": 10.0,
			"description": "Swatter area +100%, damage +50%.",
		},
		"instant_energy": {
			"id": "instant_energy",
			"name": "Instant Energy",
			"type": SkillType.INSTANT_ENERGY,
			"icon": ICON_PATH % "instant_energy",
			"cost": 200,
			"duration": 5.0,
			"description": "No swatter energy consumption.",
		},
		"fresh_goods": {
			"id": "fresh_goods",
			"name": "Fresh Goods",
			"type": SkillType.FRESH_GOODS,
			"icon": ICON_PATH % "fresh_goods",
			"cost": 300,
			"duration": 5.0,
			"description": "Food cannot be damaged.",
		},
		"big_fan": {
			"id": "big_fan",
			"name": "Big Fan",
			"type": SkillType.BIG_FAN,
			"icon": ICON_PATH % "big_fan",
			"cost": 500,
			"duration": 10.0,
			"description": "Blow flies (except boss) to a side.",
		},
	}
