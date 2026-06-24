extends Node

class FlyAsset:
	var texture: Texture2D
	var frame_count: int

	func _init(p_texture: Texture2D = null, p_frame_count: int = 1) -> void:
		texture = p_texture
		frame_count = p_frame_count

func create_fly_attributes(
	fly_name: String,
	fly_max_health: int,
	fly_speed: float,
	fly_image_scale: Vector2,
	fly_tint: Color,
	fly_hitbox_radius: float,
	fly_health_bar_width: float,
	fly_health_bar_y: float,
	fly_knockback_strength: float,
	fly_eat_time_limit: float,
	fly_can_spawn: bool = false,
	fly_bite_damage_multiplier: float = 1.0,
	fly_unlock_day: int = 1
) -> Dictionary:
	return {
		"name": fly_name,
		"max_health": fly_max_health,
		"speed": fly_speed,
		"image_scale": fly_image_scale,
		"tint": fly_tint,
		"hitbox_radius": fly_hitbox_radius,
		"health_bar_width": fly_health_bar_width,
		"health_bar_y": fly_health_bar_y,
		"knockback_strength": fly_knockback_strength,
		"eat_time_limit": fly_eat_time_limit,
		"can_spawn": fly_can_spawn,
		"bite_damage_multiplier": fly_bite_damage_multiplier,
		"unlock_day": fly_unlock_day,
	}

var Flies := {
	"Base": [
		{
			"name": "Normal",
			"flying": FlyAsset.new(load("res://assets/Flies/fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Normal",
				2,
				120.0,
				Vector2(0.48, 0.40),
				Color.WHITE,
				48.0,
				52.0,
				-66.0,
				360.0,
				2.4
			)
		},
		{
			"name": "Swarm",
			"flying": FlyAsset.new(load("res://assets/Flies/small_fly/small_fly_flying.png"), 7),
			"eating": FlyAsset.new(load("res://assets/Flies/small_fly/small_fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Swarm",
				2,
				230.0,
				Vector2(0.38, 0.32),
				Color.WHITE,
				32.0,
				66.0,
				-60.0,
				430.0,
				1.5
			)
		},
		{
			"name": "Tank",
			"flying": FlyAsset.new(load("res://assets/Flies/chunky_fly/chunky_fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/chunky_fly/chunky_fly_eating.png"), 5),
			"attributes": create_fly_attributes(
				"Tank",
				5,
				75.0,
				Vector2(0.36, 0.34),
				Color.WHITE,
				52.0,
				92.0,
				-92.0,
				290.0,
				3.2
			)
		},
		{
			"name": "Mother",
			"flying": FlyAsset.new(load("res://assets/Flies/mother_fly/mother_fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/mother_fly/mother_fly_birth.png"), 3),
			"attributes": create_fly_attributes(
				"Mother",
				4,
				95.0,
				Vector2(0.58, 0.46),
				Color(0.75, 1.0, 0.78),
				66.0,
				88.0,
				-86.0,
				320.0,
				3.0,
				true
			)
		},
	],

	"Evolved": [
		{
			"name": "Queen",
			"flying": FlyAsset.new(load("res://assets/Flies/mother_fly/mother_fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/mother_fly/mother_fly_birth.png"), 3),
			"attributes": create_fly_attributes(
				"Queen",
				9,
				82.0,
				Vector2(0.66, 0.52),
				Color(0.98, 0.76, 1.0),
				74.0,
				104.0,
				-94.0,
				260.0,
				3.6,
				true,
				1.35,
				5
			)
		},
		{
			"name": "Armored",
			"flying": FlyAsset.new(load("res://assets/Flies/chunky_fly/chunky_fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/chunky_fly/chunky_fly_eating.png"), 5),
			"attributes": create_fly_attributes(
				"Armored",
				8,
				92.0,
				Vector2(0.42, 0.38),
				Color(0.72, 0.82, 0.92),
				56.0,
				88.0,
				-86.0,
				250.0,
				3.0,
				false,
				1.05,
				10
			)
		},
		{
			"name": "Speed",
			"flying": FlyAsset.new(load("res://assets/Flies/small_fly/small_fly_flying.png"), 7),
			"eating": FlyAsset.new(load("res://assets/Flies/small_fly/small_fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Speed",
				2,
				285.0,
				Vector2(0.36, 0.30),
				Color(0.78, 0.94, 1.0),
				30.0,
				62.0,
				-58.0,
				470.0,
				1.25,
				false,
				1.05,
				10
			)
		},
		{
			"name": "Poison",
			"flying": FlyAsset.new(load("res://assets/Flies/fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Poison",
				4,
				138.0,
				Vector2(0.48, 0.40),
				Color(0.58, 1.0, 0.45),
				48.0,
				68.0,
				-70.0,
				330.0,
				2.1,
				false,
				1.65,
				20
			)
		},
		{
			"name": "Fire",
			"flying": FlyAsset.new(load("res://assets/Flies/fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Fire",
				4,
				152.0,
				Vector2(0.48, 0.40),
				Color(1.0, 0.44, 0.22),
				48.0,
				68.0,
				-70.0,
				350.0,
				1.9,
				false,
				1.85,
				20
			)
		},
		{
			"name": "Thief",
			"flying": FlyAsset.new(load("res://assets/Flies/fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Thief",
				3,
				176.0,
				Vector2(0.44, 0.36),
				Color(0.95, 0.95, 0.45),
				42.0,
				64.0,
				-66.0,
				390.0,
				1.8,
				false,
				1.3,
				30
			)
		},
		{
			"name": "Invisible",
			"flying": FlyAsset.new(load("res://assets/Flies/fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Invisible",
				3,
				142.0,
				Vector2(0.48, 0.40),
				Color(1.0, 1.0, 1.0, 0.42),
				46.0,
				62.0,
				-68.0,
				320.0,
				2.3,
				false,
				1.2,
				30
			)
		},
		{
			"name": "Blink",
			"flying": FlyAsset.new(load("res://assets/Flies/fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/fly_eating.png"), 4),
			"attributes": create_fly_attributes(
				"Blink",
				4,
				135.0,
				Vector2(0.46, 0.38),
				Color(0.82, 0.72, 1.0),
				46.0,
				70.0,
				-70.0,
				340.0,
				2.1,
				false,
				1.25,
				40
			)
		},
		{
			"name": "Mega",
			"flying": FlyAsset.new(load("res://assets/Flies/chunky_fly/chunky_fly_flying.png"), 6),
			"eating": FlyAsset.new(load("res://assets/Flies/chunky_fly/chunky_fly_eating.png"), 5),
			"attributes": create_fly_attributes(
				"Mega",
				12,
				62.0,
				Vector2(0.52, 0.48),
				Color(1.0, 0.66, 0.46),
				78.0,
				112.0,
				-104.0,
				220.0,
				3.9,
				false,
				1.55,
				40
			)
		},
	],
}
