extends Node

signal energy_changed(energy: float, max_energy: float)

const MAX_ENERGY := 100.0
const SWAT_COST := 3.0
const CUSTOMER_HIT_COST := 20.0

# Combo variables
const COMBO_WINDOW := 1.2 # seconds allowed between hits to maintain combo
const BASE_REGEN_RATE := 12.0 # units per second
const MAX_COMBO := 5

var energy := MAX_ENERGY
var current_combo := 0
var combo_timer := 0.0

func _ready() -> void:
	add_to_group("swatters")
	energy_changed.emit(energy, MAX_ENERGY)

func _process(delta: float) -> void:
	# Handle combo decaying over time
	if current_combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			current_combo = 0
	
	# Regenerate energy passively: base rate + bonus based on current combo tier
	if energy < MAX_ENERGY:
		var combo_multiplier := 1.0 + (current_combo * 0.5) # e.g., 2.5x speed at combo 3
		energy = minf(energy + (BASE_REGEN_RATE * combo_multiplier * delta), MAX_ENERGY)
		energy_changed.emit(energy, MAX_ENERGY)

func can_attack() -> bool:
	return energy >= SWAT_COST

func reset() -> void:
	energy = MAX_ENERGY
	current_combo = 0
	combo_timer = 0.0
	energy_changed.emit(energy, MAX_ENERGY)

func swat() -> bool:
	if not can_attack():
		return false
	energy -= SWAT_COST
	energy_changed.emit(energy, MAX_ENERGY)
	return true

func register_fly_kill() -> void:
	current_combo = mini(current_combo + 1, MAX_COMBO)
	combo_timer = COMBO_WINDOW

func hit_customer() -> void:
	energy = maxf(energy - CUSTOMER_HIT_COST, 0.0)
	current_combo = 0 # Break combo streak on penalty
	energy_changed.emit(energy, MAX_ENERGY)
