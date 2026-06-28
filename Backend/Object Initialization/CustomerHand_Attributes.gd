extends Node

class CustomerAsset:
    var default_texture: Texture2D
    var damage_texture: Texture2D
    var closed_texture: Texture2D
    var scale: Vector2 = Vector2.ONE
    var hit_sfx_path: String = "" # Optional path to hit SFX

    func _init(p_default: Texture2D = null, p_damage: Texture2D = null, p_closed: Texture2D = null, p_scale: Vector2 = Vector2.ONE, p_hit_sfx_path: String = "") -> void:
        default_texture = p_default
        damage_texture = p_damage
        closed_texture = p_closed
        scale = p_scale
        hit_sfx_path = p_hit_sfx_path

func create_customer_asset(default_path: String, damage_path: String, closed_path: String, scale: Vector2 = Vector2(1.5, 1.5), hit_sfx_path: String = "") -> CustomerAsset:
    var asset := CustomerAsset.new()
    if default_path != "":
        asset.default_texture = load(default_path)
    if damage_path != "":
        asset.damage_texture = load(damage_path)
    if closed_path != "":
        asset.closed_texture = load(closed_path)
    asset.scale = scale
    asset.hit_sfx_path = hit_sfx_path
    return asset

var Customers := {
    "default": create_customer_asset(
        "res://assets/customer/default_customer/hand_default.png",
        "res://assets/customer/default_customer/hand_damage.png",
        "res://assets/customer/default_customer/hand_closed.png",
        Vector2(1.5, 1.5),
        "res://assets/Sound Effects/customer_sound/ouch1.mp3" # placeholder for hit sfx
    ),
    "female": create_customer_asset(
        "res://assets/customer/female_customer/hand_default.png",
        "res://assets/customer/female_customer/hand_damage.png",
        "res://assets/customer/female_customer/hand_grab.png",
        Vector2(1.5, 1.5),
        "res://assets/Sound Effects/customer_sound/ouch2.mp3"
    ),
    "formal": create_customer_asset(
        "res://assets/customer/formal_customer/hand_default.png",
        "res://assets/customer/formal_customer/hand_damage.png",
        "res://assets/customer/formal_customer/hand_grab.png",
        Vector2(1.5, 1.5),
        "res://assets/Sound Effects/customer_sound/ouch3.mp3"
    ),
}
