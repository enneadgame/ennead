extends SetOffsetStandalone

var fadeToBlackEnd = 0.15
var fadeToBlackNow = 0
var fadeToBlackInvert = true
var fadeToBlackTarget = "N/A"
var fader = null
var returnToMenu: BaseButton = null

func intCommas(value: int):
	var ret = str(value)
	var loop_end = 0 if value > -1 else 1
	for i in range(ret.length()-3,loop_end,-3):
		ret = ret.insert(i,",")
	return ret

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	set_meta("accuracy",get_tree().get_meta("accuracy"))
	set_meta("rating",get_tree().get_meta("rating"))
	set_meta("maxCombo",get_tree().get_meta("maxCombo"))
	set_meta("score",get_tree().get_meta("score"))
	set_meta("ct_miss",get_tree().get_meta("ct_miss"))
	set_meta("ct_bad",get_tree().get_meta("ct_bad"))
	set_meta("ct_okay",get_tree().get_meta("ct_okay"))
	set_meta("ct_good",get_tree().get_meta("ct_good"))
	set_meta("ct_great",get_tree().get_meta("ct_great"))
	set_meta("ct_perfect",get_tree().get_meta("ct_perfect"))
	
	print(get_tree().get_meta("accuracy"))
	
	var accuracy = get_meta("accuracy")
	
	if accuracy != null:
	
		$score.text = intCommas(round(get_meta("score")))
		$stats/accuracy.text = str(round(accuracy*100)/100) + "%"
		$stats/rating.text = str(round(get_meta("rating")*100)/100) + "*"
		$stats/combo.text = "x" + intCommas(round(get_meta("maxCombo")))
		$ratings/perfect/count.text = "x" + intCommas(round(get_meta("ct_perfect")))
		$ratings/great/count.text = "x" + intCommas(round(get_meta("ct_great")))
		$ratings/good/count.text = "x" + intCommas(round(get_meta("ct_good")))
		$ratings/okay/count.text = "x" + intCommas(round(get_meta("ct_okay")))
		$ratings/bad/count.text = "x" + intCommas(round(get_meta("ct_bad")))
		$ratings/miss/count.text = "x" + intCommas(round(get_meta("ct_miss")))
		
		var rank = "F"
		var rankColor = Color(0.8,0.1,0.1)
		if accuracy > 60:
			rank = "D"
			rankColor = Color(0.8,0.2,0.1)
		if accuracy > 70:
			rank = "C"
			rankColor = Color(0.8,0.6,0.1)
		if accuracy > 80:
			rank = "B"
			rankColor = Color(0.3,0.8,0.1)
		if accuracy > 90:
			rank = "A"
			rankColor = Color(0.3,0.6,0.8)
		if accuracy > 95:
			rank = "S"
			rankColor = Color(0.4,0.3,0.8)
		if accuracy > 99:
			rank = "SS"
			rankColor = Color(0.8,0.3,0.7)
		if accuracy == 100:
			rank = "X"
			rankColor = Color(0.8, 0.7, 0.5)
		
		$rank.text = rank
		$rank.label_settings.font_color = rankColor
		var accuracyProgressBar:ProgressBar = get_parent().find_child("ProgressBar")
		accuracyProgressBar.value = accuracy
		accuracyProgressBar.self_modulate = rankColor
	
	fader = get_parent().find_child("fade")
	returnToMenu = get_parent().find_child("returnToMenu")
	returnToMenu.pressed.connect(_on_return_to_menu_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fadeToBlackNow += delta
	if fadeToBlackTarget != "":
		var factor = fadeToBlackNow/fadeToBlackEnd
		if fadeToBlackInvert: factor = 1-factor
		fader.color = Color(0,0,0,factor)
		if fadeToBlackNow > fadeToBlackEnd:
			if fadeToBlackTarget != "N/A":
				get_tree().change_scene_to_file(fadeToBlackTarget)
			else:
				fadeToBlackTarget = ""
				fader.color = Color(0,0,0,0)
	super._process(delta)
	UtilSetOffset.position(self,delta)

func _on_return_to_menu_pressed() -> void:
	fadeToBlackNow = 0
	fadeToBlackEnd = 0.15
	fadeToBlackInvert = false
	fadeToBlackTarget = "res://chart.tscn"
