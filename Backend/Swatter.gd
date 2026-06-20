extends Node

signal energy_changed(energy: float, max_energy: float, reloading: bool)
signal reload_started(duration: float)
signal reload_finished()

const MAX_ENERGY := 100.0
const SWAT_COST := 5.0
const CUSTOMER_HIT_COST := 20.0
const RELOAD_TIME := 3.0

var energy := MAX_ENERGY
var reloading := false
var reload_timer := 0.0

func _ready() -> void:
	add_to_group("swatters")
	energy_changed.emit(energy, MAX_ENERGY, reloading)

func _process(delta: float) -> void:
	if not reloading:
		return

	reload_timer -= delta
	if reload_timer > 0.0:
		return

	energy = MAX_ENERGY
	reloading = false
	reload_finished.emit()
	energy_changed.emit(energy, MAX_ENERGY, reloading)

func can_attack() -> bool:
	return not reloading and energy > 0.0

func reset() -> void:
	energy = MAX_ENERGY
	reloading = false
	reload_timer = 0.0
	energy_changed.emit(energy, MAX_ENERGY, reloading)

func swat() -> bool:
	if not can_attack():
		return false

	_use_energy(SWAT_COST)
	return true

func hit_customer() -> void:
	if reloading:
		return

	_use_energy(CUSTOMER_HIT_COST)

func _use_energy(amount: float) -> void:
	energy = maxf(energy - amount, 0.0)
	if energy <= 0.0:
		_start_reload()
	else:
		energy_changed.emit(energy, MAX_ENERGY, reloading)

func _start_reload() -> void:
	reloading = true
	reload_timer = RELOAD_TIME
	reload_started.emit(RELOAD_TIME)
	energy_changed.emit(energy, MAX_ENERGY, reloading)
