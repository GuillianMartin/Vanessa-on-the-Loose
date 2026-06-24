extends Node

class FoodAsset:
	var texture: Texture2D
	var frame: int

	func _init(p_texture: Texture2D = null, p_frame: int = 0) -> void:
		texture = p_texture
		frame = p_frame

const FOOD_SIZE_MULT := 2.5

func create_food_attributes(
	food_name: String,
	food_visual_size: float,
	food_max_freshness: float,
	food_spoil_rate: float,
	food_nutrition: int,
	food_radius: float,
	food_base_price: float
) -> Dictionary:
	return {
		"name": food_name,
		"visual_size": food_visual_size,
		"max_freshness": food_max_freshness,
		"spoil_rate": food_spoil_rate,
		"nutrition": food_nutrition,
		"food_radius": food_radius,
		"base_price": food_base_price
	}

var Foods := {
	"Vegetable": [
		{
			"name": "Carrot",
			"default": FoodAsset.new(load("res://assets/Foods/Vegetable/carrot/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Vegetable/carrot/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Vegetable/carrot/critical.png"), 5),
			"attributes": create_food_attributes(
				"Carrot",
				100.0 * FOOD_SIZE_MULT,
				95.0,
				0.6,
				1,
				50.0,
				25.0
			)
		},
		{
			"name": "Cabbage",
			"default": FoodAsset.new(load("res://assets/Foods/Vegetable/cabbage/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Vegetable/cabbage/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Vegetable/cabbage/critical.png"), 5),
			"attributes": create_food_attributes(
				"Cabbage",
				100.0 * FOOD_SIZE_MULT,
				105.0,
				0.5,
				1,
				50.0 * FOOD_SIZE_MULT,
				35.0
			)
		},
		{
			"name": "Tomato",
			"default": FoodAsset.new(load("res://assets/Foods/Vegetable/tomato/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Vegetable/tomato/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Vegetable/tomato/critical.png"), 5),
			"attributes": create_food_attributes(
				"Tomato",
				96.0 * FOOD_SIZE_MULT,
				90.0,
				0.55,
				1,
				48.0 * FOOD_SIZE_MULT,
				30.0
			)
		},
	],

	"Meat": [
		{
			"name": "Pork",
			"default": FoodAsset.new(load("res://assets/Foods/Meat/Pork/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Meat/Pork/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Meat/Pork/critical.png"), 5),
			"attributes": create_food_attributes(
				"Pork",
				96.0 * FOOD_SIZE_MULT,
				90.0,
				0.55 ,
				1,
				48.0 * FOOD_SIZE_MULT,
				30.0
			)
		},
		{
			"name": "Chicken",
			"default": FoodAsset.new(load("res://assets/Foods/Meat/Chicken/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Meat/Chicken/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Meat/Chicken/critical.png"), 5),
			"attributes": create_food_attributes(
				"Chicken",
				96.0 * FOOD_SIZE_MULT,
				90.0,
				0.55,
				1,
				48.0 * FOOD_SIZE_MULT,
				30.0
			)
		},
	],
}