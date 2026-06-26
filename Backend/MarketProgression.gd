extends Node

const DAY_DURATION_SECONDS := 4.0
const STARTING_MONEY := 1000
const STARTING_REPUTATION := 10000 # original 10
const STARTING_SATISFACTION := 10000 # original 10

static func get_market_event(day: int) -> Dictionary:
	var events := [
		{
			"name": "Filipino Vegetable Market",
			"food_category": "Vegetable",
			"background_path": "res://assets/background/Scene1/vegetable_background_day.png",
			"container_path": "res://assets/background/Scene1/container.png",
			"background_node": "BackgroundVegetable",
			"container_node": "ContainerVegetable",
			"price_modifier": {"Vegetable": 1.10},
			"fly_weights": {"Swarm": 3},
			"fly_spawn_multiplier": 1.12,
			"customer_spawn_multiplier": 1.0,
			"customer_reward_multiplier": 2,
			"spoil_modifier": 1.0,
			"tint": Color(0.94, 1.0, 0.88),
		},
		{
			"name": "Filipino Meat Market",
			"food_category": "Meat",
			"background_path": "res://assets/background/Scene3/background_meat.png",
			"container_path": "res://assets/background/Scene3/container_meat.png",
			"background_node": "BackgroundMeat",
			"container_node": "ContainerMeat",
			"price_modifier": {"Meat": 1.10},
			"fly_weights": {"Queen": 3, "Tank": 2},
			"fly_spawn_multiplier": 1.0,
			"customer_spawn_multiplier": 0.95,
			"customer_reward_multiplier": 2.0,
			"spoil_modifier": 1.08,
			"tint": Color(1.0, 0.90, 0.86),
		},
		{
			"name": "Filipino Fruit Market",
			"food_category": "Fruit",
			"background_path": "res://assets/background/Scene2/background_fruit.png",
			"container_path": "res://assets/background/Scene2/container_fruit.png",
			"background_node": "BackgroundFruit",
			"container_node": "ContainerFruit",
			"price_modifier": {"Fruit": 1.10, "Vegetable": 1.05},
			"fly_weights": {"Tank": 3},
			"fly_spawn_multiplier": 1.06,
			"customer_spawn_multiplier": 1.05,
			"customer_reward_multiplier": 2.0,
			"spoil_modifier": 1.0,
			"tint": Color(1.0, 0.95, 0.82),
		},
		{
			"name": "Night Market",
			"food_category": "",
			"background_path": "res://assets/background/Scene1/vegetable_background_day.png",
			"container_path": "res://assets/background/Scene1/container.png",
			"background_node": "BackgroundVegetable",
			"container_node": "ContainerVegetable",
			"price_modifier": {},
			"fly_weights": {"Poison": 2, "Fire": 2, "Invisible": 2, "Blink": 2},
			"fly_spawn_multiplier": 1.2,
			"customer_spawn_multiplier": 1.3,
			"customer_reward_multiplier": 2.2,
			"spoil_modifier": 1.0,
			"tint": Color(0.78, 0.82, 1.0),
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
			"fly_weights": {"Normal": 2, "Mother": 2},
			"fly_spawn_multiplier": 0.9,
			"fly_speed_multiplier": 0.82,
			"customer_spawn_multiplier": 0.75,
			"customer_reward_multiplier": 2.2,
			"spoil_modifier": 1.3,
			"tint": Color(0.82, 0.92, 1.0),
		},
	]

	var event_index := int((day - 1) / 5) % events.size()
	return events[event_index]

static func get_difficulty_level(day: int) -> int:
	return max(day, 1)

static func get_daily_price_roll() -> float:
	return randf_range(0.9, 1.2)

static func get_market_price_multiplier(day: int, daily_roll: float, event: Dictionary, category: String) -> float:
	var day_inflation := 1.0 + (float(max(day - 1, 0)) * 0.025)
	var category_modifiers := event.get("price_modifier", {}) as Dictionary
	var category_modifier := float(category_modifiers.get(category, 1.0))
	return day_inflation * daily_roll * category_modifier

static func get_sell_price_multiplier(day: int, event: Dictionary, category: String) -> float:
	var day_demand := 1.0 + (float(max(day - 1, 0)) * 0.022)
	var category_modifiers := event.get("price_modifier", {}) as Dictionary
	var category_modifier := float(category_modifiers.get(category, 1.0))
	return day_demand * category_modifier * float(event.get("customer_reward_multiplier", 1.0))

static func get_food_spoil_multiplier(event: Dictionary) -> float:
	return float(event.get("spoil_modifier", 1.0))

static func get_fly_count(day: int, event: Dictionary) -> int:
	var base_count := 10 + int(floor(float(max(day - 1, 0)) * 1.4))
	return int(ceil(float(base_count) * float(event.get("fly_spawn_multiplier", 1.0))))

static func get_customer_spawn_bounds(day: int, event: Dictionary, rush_active: bool) -> Vector2:
	var spawn_multiplier := float(event.get("customer_spawn_multiplier", 1.0))
	var day_speed := maxf(0.55, 1.0 - float(max(day - 1, 0)) * 0.018)
	var rush_multiplier := 0.45 if rush_active else 1.0
	return Vector2(1.2, 3.2) * day_speed * rush_multiplier / maxf(spawn_multiplier, 0.1)

static func get_customer_patience(initial_fly_count: int) -> float:
	return 100.0 * (1.0 + float(max(initial_fly_count, 0)) * 0.035)

static func should_start_rush(day: int) -> bool:
	var chance := minf(0.16 + float(day) * 0.006, 0.35)
	return randf() <= chance

static func get_rush_duration(day: int) -> float:
	return randf_range(18.0, 28.0 + float(day) * 0.35)
