class_name ChartUtils

static var count = 0

## This returns a number for the difficulty of a chart, based on it's contents.[br]
static func getChartDifficulty(json) -> float:
	count += 100
	return count

static func colorChartDifficulty(difficulty: float) -> Color:
	var hue = (120-(difficulty/1000.0)*12)/360
	var saturation = 0.5
	if difficulty >= 15:
		saturation -= ((difficulty-15)/5)*0.5
	var value = 1.0
	print("Color Chart Difficulty is ",hue," ",saturation," ",value)
	return Color.from_hsv(hue, saturation, value, 1.0)

## This returns a name for the difficulty based on [param difficulty].[br]
## [br]
## 0-500: Beginner
## 500-1000: Easy
## 1000-1500: Normal
## 1500-2000: Hard
## 2000-2500: Challenge
## 2500-3000: Insane
## 3000-3500: Expert
## 3500-4000: Extra
## 4000-4500: Extreme
## 
static func nameChartDifficulty(difficulty: float) -> String:
	if difficulty < 1000.0: return "Easy"
	if difficulty < 2000.0: return "Normal"
	if difficulty < 2500.0: return "Hard"
	if difficulty < 3000.0: return "Challenge"
	if difficulty < 3500.0: return "Insane"
	if difficulty < 4000.0: return "Expert"
	if difficulty < 4500.0: return "Extra"
	if difficulty < 5000.0: return "Extreme"
	return "Master"
