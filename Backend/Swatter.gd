extends Node

signal energy_changed(energy: float, max_energy: float)

const MAX_ENERGY := 100.0
const SWAT_COST := 3.0
const CUSTOMER_HIT_COST := 20.0
const BASE_DAMAGE := 1
const BASE_ATTACK_COOLDOWN := 0.18
const HIT_WINDOW := 0.14
const DAILY_SWAT_COST_INCREASE := 0.3 

# Combo variables
const COMBO_WINDOW := 1.2 # seconds allowed between hits to maintain combo
const BASE_REGEN_RATE := 12.0
const MAX_COMBO := 5

var max_energy := MAX_ENERGY
var swat_cost := SWAT_COST
var regen_rate := BASE_REGEN_RATE
var damage := BASE_DAMAGE
var crit_chance := 0.0
var attack_cooldown := BASE_ATTACK_COOLDOWN
var cooldown_timer := 0.0
var hit_window_timer := 0.0
var energy := MAX_ENERGY
var current_combo := 0
var combo_timer := 0.0
var damage_level := 0
var speed_level := 0
var energy_level := 0
var current_day := 1

func _ready() -> void:
	add_to_group("swatters")
	energy_changed.emit(energy, max_energy)

func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	if hit_window_timer > 0.0:
		hit_window_timer -= delta

	# Handle combo decaying over time
	if current_combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			current_combo = 0
	
	# Regenerate energy passively: base rate + bonus based on current combo tier
	if energy < max_energy:
		var combo_multiplier := 1.0 + (current_combo * 0.5) # e.g., 2.5x speed at combo 3
		energy = minf(energy + (regen_rate * combo_multiplier * delta), max_energy)
		energy_changed.emit(energy, max_energy)

func get_effective_swat_cost() -> float:
	var day_penalty := float(max(current_day - 1, 0)) * DAILY_SWAT_COST_INCREASE
	return maxf(swat_cost + day_penalty, 4.0)

func set_day(day: int) -> void:
	current_day = max(day, 1)

func can_attack() -> bool:
	return energy >= get_effective_swat_cost() and cooldown_timer <= 0.0

func reset() -> void:
	energy = max_energy
	current_combo = 0
	combo_timer = 0.0
	cooldown_timer = 0.0
	hit_window_timer = 0.0
	energy_changed.emit(energy, max_energy)

func reset_upgrades() -> void:
	max_energy = MAX_ENERGY
	swat_cost = SWAT_COST
	regen_rate = BASE_REGEN_RATE
	damage = BASE_DAMAGE
	crit_chance = 0.0
	attack_cooldown = BASE_ATTACK_COOLDOWN
	damage_level = 0
	speed_level = 0
	energy_level = 0
	reset()

func swat() -> bool:
	if not can_attack():
		return false
	energy -= get_effective_swat_cost()
	cooldown_timer = attack_cooldown
	hit_window_timer = HIT_WINDOW
	energy_changed.emit(energy, max_energy)
	return true

func is_swat_active() -> bool:
	return hit_window_timer > 0.0

func get_damage() -> int:
	var final_damage := damage
	if randf() < crit_chance:
		final_damage += max(1, int(ceil(float(damage) * 0.75)))
	return final_damage

func register_fly_kill() -> void:
	current_combo = mini(current_combo + 1, MAX_COMBO)
	combo_timer = COMBO_WINDOW

func drain_energy_to_ratio(ratio: float) -> void:
	energy = clampf(max_energy * ratio, 0.0, max_energy)
	energy_changed.emit(energy, max_energy)

func hit_customer() -> void:
	energy = maxf(energy - CUSTOMER_HIT_COST, 0.0)
	current_combo = 0 # Break combo streak on penalty
	energy_changed.emit(energy, max_energy)

func get_upgrade_cost(upgrade_name: String) -> int:
	match upgrade_name:
		"damage":
			return 75 + damage_level * 85
		"speed":
			return 60 + speed_level * 70
		"energy":
			return 65 + energy_level * 75
	return 999999

func upgrade(upgrade_name: String) -> bool:
	match upgrade_name:
		"damage":
			damage_level += 1
			damage = BASE_DAMAGE + damage_level
			crit_chance = minf(0.08 * float(damage_level), 0.35)
		"speed":
			speed_level += 1
			attack_cooldown = maxf(BASE_ATTACK_COOLDOWN - float(speed_level) * 0.018, 0.06)
			swat_cost = maxf(SWAT_COST - float(speed_level) * 0.55, 4.0)
		"energy":
			energy_level += 1
			max_energy = MAX_ENERGY + float(energy_level) * 18.0
			regen_rate = BASE_REGEN_RATE + float(energy_level) * 2.5
			swat_cost = maxf(swat_cost - 0.35, 4.0)
			energy = minf(energy + 18.0, max_energy)
			energy_changed.emit(energy, max_energy)
		_:
			return false

	return true
