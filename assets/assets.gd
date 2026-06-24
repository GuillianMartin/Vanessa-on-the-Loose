extends Node

class FoodAsset:
	var texture: Texture2D
	var frame: int

var Foods :=  {
	"Vegetable": {
		"Carrot": {
			"default": FoodAsset.new(preload("res://assets/Foods/Vegetable/carrot/default.png"), 1),
			"notgood": FoodAsset.new(preload("res://assets/Foods/Vegetable/carrot/notgood.png"), 1),
			"critical": FoodAsset.new(preload("res://assets/Foods/Vegetable/carrot/critical.png"), 5),
		},
	},
}
