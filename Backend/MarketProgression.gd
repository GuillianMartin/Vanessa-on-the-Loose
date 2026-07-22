extends Node
# MARKET PROGRESSION
# Serves as game event attribute changer for loop progression

const DAY_DURATION_SECONDS := 4
const STARTING_MONEY := 100000
const STARTING_REPUTATION := 10000
const STARTING_SATISFACTION := 1000

# Function that serve as event picker
static func get_market_event(day: int) -> Dictionary:
	var events: Array[Dictionary] = [
		{
			"name": "Filipino Vegetable Market",
			"food_category": "Vegetable",
			"background_path": "res://assets/background/Scene1/vegetable_background_day.png",
			"container_path": "res://assets/background/Scene1/container.png",
			"background_node": "BackgroundVegetable",
			"container_node": "ContainerVegetable",
			"price_modifier": {"Vegetable": 1.10},
			"fly_weights": {"Normal": 2, "Swarm": 3},
			"fly_spawn_multiplier": 1.06,
			"customer_spawn_multiplier": 1.12,
			"customer_reward_multiplier": 1.0,
			"spoil_modifier": 1.02,
			"tint": Color(1.0, 1.0, 1.0),
		},
		{
			"name": "Filipino Meat Market",
			"food_category": "Meat",
			"background_path": "res://assets/background/Scene3/background_meat.png",
			"container_path": "res://assets/background/Scene3/container_meat.png",
			"background_node": "BackgroundMeat",
			"container_node": "ContainerMeat",
			"price_modifier": {"Meat": 1.12},
			"fly_weights": {"Normal": 2, "Tank": 2, "Mother": 3},
			"fly_spawn_multiplier": 1.08,
			"customer_spawn_multiplier": 1.16,
			"customer_reward_multiplier": 1.02,
			"spoil_modifier": 1.06,
			"tint": Color(1.0, 1.0, 1.0),
		},
		{
			"name": "Filipino Fruit Market",
			"food_category": "Fruit",
			"background_path": "res://assets/background/Scene2/background_fruit.png",
			"container_path": "res://assets/background/Scene2/container_fruit.png",
			"background_node": "BackgroundFruit",
			"container_node": "ContainerFruit",
			"price_modifier": {"Fruit": 1.10},
			"fly_weights": {"Normal": 3, "Swarm": 2, "Mother": 3},
			"fly_spawn_multiplier": 1.08,
			"customer_spawn_multiplier": 1.16,
			"customer_reward_multiplier": 1.0,
			"spoil_modifier": 1.04,
			"tint": Color(1.0, 1.0, 1.0),
		},
		{
			"name": "Night Market",
			"food_category": "",
			"background_path": "res://assets/background/Scene4/background_night.png",
			"container_path": "res://assets/background/Scene4/container_night.png",
			"background_node": "BackgroundNight",
			"container_node": "ContainerNight",
			"price_modifier": {},
			"fly_weights": {"Normal": 2, "Invisible": 2, "Blink": 2, "Mother": 3},
			"fly_spawn_multiplier": 1.10,
			"customer_spawn_multiplier": 1.20,
			"customer_reward_multiplier": 1.02,
			"spoil_modifier": 1.0,
			"tint": Color(1.0, 1.0, 1.0),
		},
		{
			"name": "Rainy Market",
			"food_category": "",
			"background_path": "res://assets/background/Scene5/background_rainy.png",
			"container_path": "res://assets/background/Scene5/container_rainy.png",
			"background_node": "BackgroundRainy",
			"container_node": "ContainerRainy",
			"background_hframes": 9,
			"background_vframes": 1,
			"background_animation_duration": 0.12,
			"container_hframes": 9,
			"container_vframes": 1,
			"container_animation_duration": 0.12,
			"price_modifier": {},
			"fly_weights": {"Normal": 2, "Poison": 2, "Swarm": 3, "Mother": 3},
			"fly_spawn_multiplier": 1.12,
			"fly_speed_multiplier": 1.02,
			"customer_spawn_multiplier": 1.24,
			"customer_reward_multiplier": 1.06,
			"spoil_modifier": 1.3,
			"tint": Color(1.0, 1.0, 1.0),
		},
	]

	var event_index: int = int((day - 1) / 5.0) % events.size()
	return events[event_index] # Takes the event based on index value

#Helper Functions
static func get_difficulty_level(day: int) -> int:
	return max(day, 1)

static func get_boss_guard_count(day: int) -> int:
	var guards: int = 1 + int(floor(float(max(day, 1)) / 10.0))
	return maxi(guards, 2)

static func get_daily_price_roll() -> float:
	return randf_range(0.9, 1.2)

static func get_market_price_multiplier(day: int, daily_roll: float, event: Dictionary, category: String) -> float:
	var day_inflation: float = 1.0 + (float(max(day - 1, 0)) * 0.025)
	var category_modifiers: Dictionary = event.get("price_modifier", {}) as Dictionary
	var category_modifier: float = float(category_modifiers.get(category, 1.0))
	return day_inflation * daily_roll * category_modifier

static func get_sell_price_multiplier(day: int, event: Dictionary, category: String) -> float:
	var day_demand: float = 1.0 + (float(max(day - 1, 0)) * 0.022)
	var category_modifiers: Dictionary = event.get("price_modifier", {}) as Dictionary
	var category_modifier: float = float(category_modifiers.get(category, 1.0))
	return day_demand * category_modifier * float(event.get("customer_reward_multiplier", 1.0))

static func get_food_spoil_multiplier(event: Dictionary) -> float:
	return float(event.get("spoil_modifier", 1.0))

static func get_fly_count(day: int, event: Dictionary) -> int:
	var base_count: int = 10 + int(floor(float(max(day - 1, 0)) * 0.8))
	return int(ceil(float(base_count) * float(event.get("fly_spawn_multiplier", 1.0))))

static func get_customer_spawn_bounds(day: int, event: Dictionary, rush_active: bool) -> Vector2:
	var spawn_multiplier: float = float(event.get("customer_spawn_multiplier", 1.0))
	var day_speed: float = maxf(0.55, 1.0 - float(max(day - 1, 0)) * 0.018)
	var rush_multiplier: float = 0.45 if rush_active else 1.0
	return Vector2(1.2, 3.2) * day_speed * rush_multiplier / maxf(spawn_multiplier, 0.1)

static func get_customer_patience(initial_fly_count: int) -> float:
	return 100.0 * (1.0 + float(max(initial_fly_count, 0)) * 0.035)

static func should_start_rush(day: int) -> bool:
	var chance: float = minf(0.16 + float(day) * 0.006, 0.35)
	return randf() <= chance

static func get_rush_duration(day: int) -> float:
	return randf_range(18.0, 28.0 + float(day) * 0.35)
