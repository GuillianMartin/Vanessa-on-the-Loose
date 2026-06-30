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
	food_radius: float,
	food_max_freshness: float,
	food_spoil_rate: float,
	food_nutrition: int,
	food_base_price: float,
	food_tint: Color = Color.WHITE
) -> Dictionary:
	return {
		"name": food_name,
		"visual_size": food_visual_size,
		"max_freshness": food_max_freshness,
		"spoil_rate": food_spoil_rate,
		"nutrition": food_nutrition,
		"food_radius": food_radius,
		"base_price": food_base_price,
		"tint": food_tint
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
				50.0 * FOOD_SIZE_MULT,
				95.0,
				0.6,
				1,
				13.0
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
				50.0 * FOOD_SIZE_MULT,
				105.0,
				0.5,
				1,
				16.0
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
				48.0 * FOOD_SIZE_MULT,
				90.0,
				0.55,
				1,
				11.0
			)
		},
	],

	"Fruit": [
		{
			"name": "Banana",
			"default": FoodAsset.new(load("res://assets/Foods/Fruits/banana/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Fruits/banana/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Fruits/banana/critical.png"), 5),
			"attributes": create_food_attributes(
				"Mango",
				96.0 * FOOD_SIZE_MULT,
				48.0 * FOOD_SIZE_MULT,
				88.0,
				0.72,
				1,
				12.0
			)
		},
		{
			"name": "watermelon",
			"default": FoodAsset.new(load("res://assets/Foods/Fruits/watermelon/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Fruits/watermelon/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Fruits/watermelon/critical.png"), 5),
			"attributes": create_food_attributes(
				"watermelon",
				82.0 * FOOD_SIZE_MULT,
				42.0 * FOOD_SIZE_MULT,
				82.0,
				0.78,
				1,
				14.0
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
				48.0 * FOOD_SIZE_MULT,
				90.0,
				0.55 ,
				1,
				26.0
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
				48.0 * FOOD_SIZE_MULT,
				90.0,
				0.55,
				1,
				23.0
			)
		},
		{
			"name": "Fish",
			"default": FoodAsset.new(load("res://assets/Foods/Meat/fish/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Meat/fish/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Meat/fish/critical.png"), 5),
			"attributes": create_food_attributes(
				"Fish",
				96.0 * FOOD_SIZE_MULT,
				48.0 * FOOD_SIZE_MULT,
				90.0,
				0.55 ,
				1,
				19.0
			)
		},
		{
			"name": "Sausage",
			"default": FoodAsset.new(load("res://assets/Foods/Meat/sausage/default.png"), 1),
			"notgood": FoodAsset.new(load("res://assets/Foods/Meat/sausage/notgood.png"), 1),
			"critical": FoodAsset.new(load("res://assets/Foods/Meat/sausage/critical.png"), 5),
			"attributes": create_food_attributes(
				"Sausage",
				96.0 * FOOD_SIZE_MULT,
				48.0 * FOOD_SIZE_MULT,
				90.0,
				0.55 ,
				1,
				17.0
			)
		},
	],
}
