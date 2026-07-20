class_name GameConfig
extends RefCounted

const MAP_SIZE := Vector2(1600.0, 960.0)
const NAV_CELL_SIZE := 24.0
const SPATIAL_CELL_SIZE := 128.0
const CIVILIAN_COUNT := 40

const CIVILIAN_SPEED := 62.0
const CIVILIAN_FLEE_SPEED := 102.0
const CIVILIAN_DANGER_RADIUS := 180.0
const CIVILIAN_RADIUS := 8.0

const ZOMBIE_SPEED := 54.0
const ZOMBIE_SIGHT_RADIUS := 310.0
const ZOMBIE_ATTACK_RANGE := 19.0
const ZOMBIE_HEALTH := 100.0

const POLICE_SPEED := 76.0
const POLICE_SIGHT_RADIUS := 430.0
const POLICE_SAFE_RANGE := 145.0
const POLICE_ATTACK_RANGE := 185.0
const POLICE_DAMAGE := 34.0
const POLICE_ATTACK_COOLDOWN := 0.7

const GAS_RADIUS := 92.0
const GAS_DURATION := 5.5
const GAS_INFECTION_CHANCE := 0.82
const GAS_INCUBATION := 7.0
const GAS_COOLDOWN := 4.0
const POLICE_COOLDOWN := 2.0

const COLORS := {
	"civilian": Color("#52d9e8"),
	"infected": Color("#e3b341"),
	"zombie": Color("#79d34d"),
	"police": Color("#5b8cff"),
	"building": Color("#27343d"),
	"building_roof": Color("#354650"),
	"road": Color("#303941"),
	"sidewalk": Color("#69757a"),
	"grass": Color("#314b3b"),
}

static func obstacle_rects() -> Array[Rect2]:
	return [
		Rect2(110, 105, 310, 190),
		Rect2(545, 105, 230, 190),
		Rect2(910, 105, 265, 190),
		Rect2(1300, 105, 190, 190),
		Rect2(110, 430, 245, 210),
		Rect2(480, 430, 320, 210),
		Rect2(955, 430, 225, 210),
		Rect2(1305, 430, 185, 210),
		Rect2(120, 770, 300, 130),
		Rect2(550, 770, 225, 130),
		Rect2(960, 770, 300, 130),
	]
