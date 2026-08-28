class_name Levels
extends RefCounted
## Endless level curve: moves shrink, score targets grow, stars scale with score.
## Pure math so tests can assert monotonic difficulty.

## 22 moves for levels 1-5, then one less every 5 levels, floor 15.
static func moves_for(level: int) -> int:
	return maxi(15, 22 - int((level - 1) / 5.0))

## Score target compounds ~12% per level plus a linear nudge, rounded to 100.
static func target_for(level: int) -> int:
	var t := 1000.0 * pow(1.12, level - 1) + 400.0 * (level - 1)
	return int(ceil(t / 100.0) * 100.0)

## 1 star = target met, 2 stars = 1.4x, 3 stars = 1.9x.
static func stars_for(score: int, target: int) -> int:
	if score >= int(target * 1.9):
		return 3
	if score >= int(target * 1.4):
		return 2
	if score >= target:
		return 1
	return 0

static func coins_for(stars: int) -> int:
	return 10 + 15 * stars

## Cascade combo praise thresholds (by wave number).
static func praise_for(combo: int) -> String:
	if combo >= 5:
		return "SWEET FRENZY!"
	if combo >= 4:
		return "DIVINE!"
	if combo >= 3:
		return "DELICIOUS!"
	if combo >= 2:
		return "SWEET!"
	return ""
