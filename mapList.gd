extends VBoxContainer

var mapTemplate: Button
var scroller: ScrollContainer
var dir: DirAccess
var timePerFileSync = 10000
var lastResync = -timePerFileSync

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(OS.get_data_dir())
	dir = DirAccess.open("user://")
	DirAccess.make_dir_recursive_absolute("user://ennead/charts")
	dir.make_dir_recursive("ennead/charts")
	dir.change_dir("ennead")
	scroller = get_parent()
	mapTemplate = scroller.find_child("mapTemplate")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Time.get_ticks_msec()-lastResync > timePerFileSync:
		print("Synchronizing files.")
		lastResync = Time.get_ticks_msec()
		var scroll = scroller.scroll_vertical
		for i in get_children():
			i.queue_free()
		dir.change_dir("charts")
		var files = dir.get_files()
		for fname in files:
			print("File.")
			var archive = ZIPReader.new()
			archive.open("user://ennead/charts/" + fname)
			var buffer = archive.read_file("map")
			var content = buffer.get_string_from_utf8()
			var json: Dictionary = JSON.parse_string(content)
			var copy = mapTemplate.duplicate()
			add_child(copy)
			copy.visible = true
			print(copy.get_children())
			print(copy.find_child("VBoxContainer",true,false))
			copy.find_child("name",true,false).text = json.get("Title","Untitled Song")
			copy.find_child("artist",true,false).text = ", ".join(json.get("Mappers"))
			var difficulty = ChartUtils.getChartDifficulty(json)
			var difficultyName = ChartUtils.nameChartDifficulty(difficulty)
			var difficultyColor = ChartUtils.colorChartDifficulty(difficulty)
			print(difficulty,difficultyName,difficultyColor)
			copy.find_child("difficulty",true,false).text = \
				"(" + str(round(difficulty*100)/100) + ") " + difficultyName
			copy.find_child("difficulty",true,false).modulate = difficultyColor
		print("Finished!")
		scroller.scroll_vertical = scroll
