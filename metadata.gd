extends Control

var chart = self.get_parent().find_child("Editor/Chart")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	chart.set_meta("songTitle",$VBoxContainer/songtitle.text)
	chart.set_meta("songArtist",$VBoxContainer/songartist.text)
	chart.set_meta("charter",$VBoxContainer/charter.text)
	chart.set_meta("difficultyName",$VBoxContainer/difficulty.text)

func _on_chart_chart_loaded() -> void:
	$VBoxContainer/songtitle.text = chart.get_meta("songTitle")
	$VBoxContainer/songartist.text = chart.get_meta("songArtist")
	$VBoxContainer/charter.text = chart.get_meta("charter")
	$VBoxContainer/difficulty.text = chart.get_meta("difficultyName")
