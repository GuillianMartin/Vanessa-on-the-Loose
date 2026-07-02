extends Node

class FlyAsset:
	var texture: Texture2D
	var frame_count: int

	func _init(p_texture: Texture2D = null, p_frame_count: int = 1) -> void:
		texture = p_texture
		frame_count = p_frame_count


var BossFlies := {
		"Boss" : [
			{
			"name": "Normal",
			"flying": FlyAsset.new(load("res://assets/Flies/boss/boss_flying.png"), 5),
			"eating": FlyAsset.new(load("res://assets/Flies/boss/boss_eating.png"), 12),
			"poison": FlyAsset.new(load("res://assets/Flies/boss/boss_fly_poison.png"), 18),
			"shockwave": FlyAsset.new(load("res://assets/Flies/boss/boss_shockwave.png"), 22),
			"boss_kill": FlyAsset.new(load("res://assets/Flies/boss/boss_kill.png"), 11),
			"boss_revive": FlyAsset.new(load("res://assets/Flies/boss/boss_revive.png"), 26),
			"boss_stun": FlyAsset.new(load("res://assets/Flies/boss/boss_stun.png"), 6),
			"boss_summon": FlyAsset.new(load("res://assets/Flies/boss/boss_summon.png"), 22),
			"poison_effect": FlyAsset.new(load("res://assets/Flies/boss/effects/poison_effect.png"), 9),
			"shockwave_effect": FlyAsset.new(load("res://assets/Flies/boss/effects/shockwave_effect.png"), 14),
			}
		]
}
