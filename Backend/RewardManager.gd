extends RefCounted

const FLY_SWAT_REWARD := 5

static func calculate_fly_reward(flies_swatted: int) -> int:
	return maxi(flies_swatted, 0) * FLY_SWAT_REWARD
