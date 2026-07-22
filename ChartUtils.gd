class_name ChartUtils

static var count = 0

## This returns a number for the difficulty of a chart, based on it's contents.[br]
static func getChartDifficulty(json) -> float:
	count += 1
	return count

static func colorChartDifficulty(difficulty: float) -> Color:
	var hue = (120-difficulty*12)/360
	var saturation = 0.5
	if difficulty >= 15:
		saturation -= ((difficulty-15)/5)*0.5
	var value = 1.0
	print("Color Chart Difficulty is ",hue," ",saturation," ",value)
	return Color.from_hsv(hue, saturation, value, 1.0)

## This returns a name for the difficulty based on [param difficulty].[br]
## [br]
## Below 1, the map is labelled Beginner.[br]
## Between 1 and 3, it is Easy.[br]
## Between 3 and 5, it is Normal.[br]
## Between 5 and 10, it is Hard.[br]
## Between 10 and 15, it is Insane.[br]
## Between 15 and 20, it is Expert.[br]
## Between 20 and 30, it is Master.[br]
## Above 30, it is Challenge.
static func nameChartDifficulty(difficulty: float) -> String:
	if (difficulty < 1.0): return "Beginner"
	if (difficulty < 3.0): return "Easy"
	if (difficulty < 5.0): return "Normal"
	if difficulty < 10.0: return "Hard"
	if difficulty < 15.0: return "Insane"
	if difficulty < 20.0: return "Expert"
	if difficulty < 30.0: return "Master"
	return "Challenge"
