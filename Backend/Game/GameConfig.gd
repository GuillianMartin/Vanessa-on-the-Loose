extends RefCounted

const BOSS_GUARD_INTERCEPT_CHANCE := 0.35
const GAME_OVER_TEXTURE := preload("res://assets/background/game_over/game_over.png")
const GAME_OVER_FLY_TEXTURE := preload("res://assets/background/game_over/game_over_fly.png")
const TRY_AGAIN_BUTTON_TEXTURE := preload("res://assets/buttons/try_again.png")
const HOME_BUTTON_TEXTURE := preload("res://assets/buttons/home_button.png")
const PIXELIFY_FONT := preload("res://assets/font/PixelifySans.ttf")
const JERSEY_FONT := preload("res://assets/font/Jersey10.ttf")

const BASE_FOOD_COUNT := 8
const TOP_SAFE_AREA := 72.0
const EDGE_PADDING := 30.0
const FOOD_GAP := 1.0
const FOOD_PLACEMENT_ATTEMPTS := 500
const GAME_CANVAS_SIZE := Vector2(1152, 648)
const SWATTER_ATTACK_FRAMES := 4
const SWATTER_ATTACK_FRAME_TIME := 0.045
const SWATTER_OFFSET := Vector2(34, 34)
const MAX_ACTIVE_CUSTOMERS := 5
const MAX_ACTIVE_FLIES_BASE := 25
const MAX_ACTIVE_FLIES_PER_DAY := 1.2
const FLY_REFILL_RATIO := 0.45
const MAX_DEBT_LIMIT: int = -500
const MAX_BANKRUPTCY_STRIKES: int = 3
const RESULT_FRAME_SIZE := Vector2(723, 483)
const RESULT_FLIP_FRAME_COUNT := 17
const RESULT_FLIP_FPS := 15.0
const RESULT_BUTTON_FRAME_SIZE := Vector2(330, 70)
const RESULT_TEXT_AREA_POSITION := Vector2(182, 62)
const RESULT_TEXT_AREA_SIZE := Vector2(477, 294)
const RESULT_BUTTON_POSITION := Vector2(275, 390)
const RESULT_TEXT_COLOR := Color("#5D371E")
const BOSS_WARNING_FRAME_SIZE := Vector2(1063, 570)
const BOSS_WARNING_BUTTON_SIZE := Vector2(322, 37)
const BOSS_SHUTTER_HALF_SIZE := Vector2(1152, 324)
const BOSS_WARNING_TEXT_POSITION := Vector2(258, 154)
const BOSS_WARNING_TEXT_SIZE := Vector2(548, 238)
const BOSS_WARNING_BUTTON_POSITION := Vector2(370, 382)
const BOSS_COUNTDOWN_FONT_SIZE := 118
const GAME_OVER_FRAME_SIZE := Vector2(1152, 648)
const GAME_OVER_BUTTON_FRAME_SIZE := Vector2(169, 143)
const GAME_OVER_DATA_POSITION := Vector2(410, 266)
const GAME_OVER_DATA_SIZE := Vector2(340, 170)
const GAME_OVER_TRY_AGAIN_BUTTON_POSITION := Vector2(363, 458)
const GAME_OVER_HOME_BUTTON_POSITION := Vector2(620, 458)
const PAUSE_BUTTON_FRAME_SIZE := Vector2(94, 92)
const PAUSE_BUTTON_SIZE := Vector2(94, 92)
const PAUSE_MENU_BUTTON_SIZE := Vector2(330, 70)
const SKILL_EFFECT_FRAME_SIZE := Vector2(194, 145)
const SKILL_EFFECT_FRAME_COUNT := 9
const SKILL_EFFECT_FPS := 10.0
const SKILL_EFFECT_OFFSET := Vector2(-20, 0)
const HUD_STAT_FONT_MAX := 16
const HUD_STAT_FONT_MIN := 12

const FINANCIAL_BUTTON_TEXTURE := preload("res://assets/buttons/financial_button.png")
const START_BUTTON_TEXTURE := preload("res://assets/buttons/start_button.png")
const ENTER_BOSS_BUTTON_TEXTURE := preload("res://assets/buttons/enter_boss.png")
const PAUSE_BUTTON_TEXTURE := preload("res://assets/buttons/pause.png")
const QUIT_BUTTON_TEXTURE := preload("res://assets/buttons/quit_button.png")
const RESUME_BUTTON_TEXTURE := preload("res://assets/buttons/resume_button.png")
const BOSS_BG_TOP_TEXTURE := preload("res://assets/ui_container/boss_bg1.png")
const BOSS_BG_BOTTOM_TEXTURE := preload("res://assets/ui_container/boss_bg2.png")
const BOSS_WARNING_CONTAINER_TEXTURE := preload("res://assets/ui_container/boss_warning_container.png")
const RESULT_CONTAINER_TEXTURE := preload("res://assets/ui_container/result_container.png")
const RESULT_FLIP_TEXTURE := preload("res://assets/ui_container/result_flip.png")
const SWATTER_DEFAULT_TEXTURE := preload("res://assets/weapon/swatter/swatter_default.png")
const SWATTER_ATTACK_TEXTURE := preload("res://assets/weapon/swatter/swatter_attack.png")
const HUD_SCENE: PackedScene = preload("res://Objects/HUD.tscn")
const AFTER_DAY_REPORT_SCENE: PackedScene = preload("res://Objects/AfterDayReport.tscn")

const FLY_SCENE := preload("res://Objects/Fly.tscn")
const BOSS_FLY_SCRIPT := preload("res://Backend/Object Behavior/BossFly.gd")
const BOSS_KNIGHT_GUARD_SCRIPT := preload("res://Backend/Object Behavior/BossKnightGuard.gd")
const FOOD_SCRIPT := preload("res://Backend/Object Behavior/Food.gd")
const CUSTOMER_HAND_SCRIPT := preload("res://Backend/Object Behavior/CustomerHand.gd")
const SWATTER_SCRIPT := preload("res://Backend/Swatter.gd")
const MARKET_PROGRESSION := preload("res://Backend/MarketProgression.gd")
const REWARD_MANAGER := preload("res://Backend/RewardManager.gd")
const BUY_SKILLS := preload("res://Backend/Buy_skills.gd")

const icon_paths := {
	"damage": "res://assets/icon/Upgrades/damage.png",
	"speed": "res://assets/icon/Upgrades/speed.png",
	"energy": "res://assets/icon/Upgrades/energy.png",
}

const upgrade_descriptions := {
	"damage": "Increases swatter damage by +1 per level and raises critical hit chance.",
	"speed": "Reduces attack cooldown and lowers energy cost per swat.",
	"energy": "Raises maximum energy and speeds up passive energy regeneration.",
}
