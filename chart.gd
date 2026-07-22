extends Control
class_name ChartCommon

enum ModType {
	## Plays the chart for you.
	AUTO,
	## Changes the speed the chart is played at.[br]
	## The strength of this refers to the modifier of the playback speed.
	## A range between 0.5 and 2.0 is expected.
	SPEED
}

signal chart_loaded

@export var musicPlayer: AudioStreamPlayer
var musicStream: AudioStreamWAV

class ChartPlayer:
	var musicPlayer: AudioStreamPlayer
	var musicStream: AudioStreamWAV
	var judgementWindow: float
	var playback = false
	var on_finish:Callable
	func ready(player:AudioStreamPlayer,on_finish:Callable,judgementWindow:float=0):
		self.judgementWindow = judgementWindow
		self.musicPlayer = player
		self.musicStream = musicPlayer.stream
		self.on_finish = on_finish
		#note: commented out because len(notes) == 0 is a better indicator. DO NOT ADD BACK.
		#if on_finish:
			#musicPlayer.finished.connect(on_finish)
	func process(delta:float,chart:ChartCommon):
		if musicPlayer.playing != playback and chart.time > 0:
			musicPlayer.playing = playback
			musicPlayer.seek(chart.time)
		if playback:
			if chart.time > 0:
				chart.time = musicPlayer.get_playback_position()+AudioServer.get_time_since_last_mix()
			else:
				chart.time += delta
		else:
			musicPlayer.stop()
		
		# do misses
		while len(chart.notes) != 0 and chart.time-chart.notes[0].time > chart.judgementwindow:
			if playback: doJudgement(chart.notes[0],chart.time,chart)
			chart.notes.remove_at(0)
		# finish logic
		if len(chart.notes) == 0:
			on_finish.call()
		
		# press detection
		if playback:
			var pressedLanes = []
			for i in range(1,10):
				if Input.is_action_just_pressed("note" + str(i)): pressedLanes.append(i)
			var candidates = []
			# press handling
			for i in range(1,10):
				candidates.append([])
			for note: Note in chart.notes:
				if note.time > chart.time+chart.judgementwindow: break
				if abs(note.time-chart.time) > chart.judgementwindow: continue
				if (not note.pos in pressedLanes) and chart.autoplay == false: continue
				if chart.autoplay == true and note.time-chart.time > delta+0.01: continue
				# self.time = note.time ; sizeFactor = 0.0
				# self.time = note.time+leadtime ; sizeFactor = 1.0
				#
				# sizeFactor = ((self.time-note.time)/leadtime)*0.5
				candidates[note.pos-1].append(note)
				if playback: doJudgement(note,chart.time,chart)
			#pressed note removal
			for lanecandidates in candidates:
				var closestCandidateDistance = chart.time+1000
				var closestCandidate = null
				for candidate: Note in lanecandidates:
					var distance = abs(candidate.time-chart.time)
					if distance < closestCandidateDistance:
						closestCandidateDistance = distance
						closestCandidate = candidate
					else:
						break
				chart.notes.erase(closestCandidate)
	func finishJudgement(accuracy: float,score: float,judgement: String,chart: ChartCommon):
		chart.set_meta("ct_"+judgement,chart.get_meta("ct_"+judgement)+1)
		chart.set_meta("judgements",chart.get_meta("judgements")+1)
		chart.set_meta("totalAccuracy",chart.get_meta("totalAccuracy")+accuracy)
		chart.set_meta("score",chart.get_meta("score")+score)
		if judgement == "miss":
			chart.set_meta("combo",0)
		else:
			chart.set_meta("combo",chart.get_meta("combo")+1)
		chart.get_node("Judgement").text = TranslationServer.translate("judgement."+judgement) + "\n" + str(chart.get_meta("combo"))
	func doJudgement(note: Note, time: float, chart: ChartCommon) -> void:
		var distance = abs(note.time-time)
		var score = 1-(distance/judgementWindow)
		score = clamp(score,0,1)
		score **= 2
		score *= 10000000/chart.get_meta("notes")
		if distance > judgementWindow:
			finishJudgement(0.0,score,"miss",chart)
		elif distance > judgementWindow/2:
			finishJudgement(0.4,score,"bad",chart)
		elif distance > judgementWindow/3:
			finishJudgement(0.6,score,"okay",chart)
		elif distance > judgementWindow/4:
			finishJudgement(0.8,score,"good",chart)
		elif distance > judgementWindow/5:
			finishJudgement(0.9,score,"great",chart)
		else:
			finishJudgement(1.0,score,"perfect",chart)

class ChartEditor extends Node:
	var chart:ChartCommon
	func ready(chart:ChartCommon):
		chart.add_child(self)
		self.owner = chart.owner
		self.chart = chart
	func process(delta:float):
		if chart.chartPlayer:
			if Input.is_action_just_released("editor_playback"):
				chart.chartPlayer.playback = not chart.chartPlayer.playback
		if Input.is_action_just_pressed("editor_forward"):
			chart.time += chart.time%chart
		for idx in range(1,10):
			if Input.is_action_just_pressed("note" + str(idx)):
				if Input.is_key_pressed(KEY_SHIFT):
					var newNote = Note.new(chart.time,idx)
					chart.allNotes.insert(0,newNote)
					chart.reloadNotes()
					print("add note")
				if Input.is_key_pressed(KEY_ALT):
					if chart.notes[0].time == chart.time and chart.notes[0].pos == idx:
						chart.allNotes.erase(chart.notes[0])
						chart.reloadNotes()
						print("removed note at time ",chart.notes[0].time," -- im at ",chart.time)

class ChartRenderer extends Node:
	var progress:ProgressBar
	var grid:GridContainer
	var hitIndicatorTemplate:Panel
	var ui:VBoxContainer
	var judgement:Label
	var bg:Sprite2D
	var chart:ChartCommon
	var scoreDisplay = 0.0
	var ratingDisplay = 0.0
	var accDisplay = 100.0
	var maxCombo = 0
	func intCommas(value: int):
		var ret = str(value)
		var loop_end = 0 if value > -1 else 1
		for i in range(ret.length()-3,loop_end,-3):
			ret = ret.insert(i,",")
		return ret
	func ready(chart:ChartCommon):
		self.chart = chart
		chart.add_child(self)
		self.owner = chart.owner
		progress = $"../ProgressBar"
		grid = $"../grid"
		hitIndicatorTemplate = $"../hitindicator"
		ui = $"../UI"
		judgement = $"../Judgement"
	func updateScores(delta: float):
		if chart.renderPlaybackUI == false: return
		if chart.featurePlayerEnabled == false: return
		if not chart.chartPlayer.playback:
			chart.set_meta("totalAccuracy",0)
			chart.set_meta("judgements",0)
			chart.set_meta("score",0)
			chart.set_meta("ct_miss",0)
			chart.set_meta("ct_bad",0)
			chart.set_meta("ct_okay",0)
			chart.set_meta("ct_good",0)
			chart.set_meta("ct_perfect",0)
			chart.set_meta("combo",0)
		if chart.get_meta("judgements") == 0:
			chart.set_meta("accuracy",100)
		else:
			chart.set_meta("accuracy",chart.get_meta("totalAccuracy")/chart.get_meta("judgements")*100)
		chart.set_meta("rating",(chart.get_meta("difficulty")*1.1)*((chart.get_meta("accuracy")/100)**2))
		var fastFactor = 0.1/delta
		var slowFactor = 0.2/delta
		scoreDisplay = (scoreDisplay*fastFactor+chart.get_meta("score"))/(fastFactor+1)
		ratingDisplay = (ratingDisplay*slowFactor+chart.get_meta("rating"))/(slowFactor+1)
		accDisplay = (accDisplay*slowFactor+chart.get_meta("accuracy"))/(slowFactor+1)
		$"../UI/score".text = intCommas(round(scoreDisplay))
		$"../UI/rating".text = "Rating: " + str(round(ratingDisplay*100)/100) + "*"
		$"../UI/accuracy".text = "Accuracy: " + str(round(accDisplay*100)/100) + "%"
		$"../ProgressBar".max_value = chart.chartPlayer.musicPlayer.stream.get_length()
		$"../ProgressBar".value = chart.time
		maxCombo = max(maxCombo,chart.get_meta("combo"))
	func process(delta:float):
		var size = chart.get_viewport_rect().size
		# move editor ui
		$"../EditorDetails".position = size*Vector2(0,1)
		$"../EditorDetails".position -= $"../EditorDetails".size*Vector2(0,1)
		# change colors of notes
		grid.position = (size/2)-(grid.size/2)
		var gsize = min(size.x,size.y)/2
		grid.size = Vector2(gsize,gsize)
		for panel: Panel in grid.get_children():
			var targetcolor = Color(0.5,0.5,0.5)
			var factor = 0.05/delta
			var color = (panel.self_modulate*factor+targetcolor)/(factor+1)
			if Input.is_action_pressed(panel.name):
				color = Color(1.0,1.0,1.0)
			panel.self_modulate = color
			for indicator: Panel in panel.get_children():
				indicator.queue_free()
		
		
		# render notes
		for note: Note in chart.notes:
			if note.time-chart.leadtime < chart.time:
				var clone: Panel = hitIndicatorTemplate.duplicate()
				var sizeFactor = (chart.time-note.time+chart.leadtime)/chart.leadtime
				var noteName = "note" + str(note.pos)
				if (sizeFactor > 1): sizeFactor = 0
				sizeFactor = sizeFactor*sizeFactor
				clone.modulate = Color(1,1,1,sizeFactor)
				var note1 = grid.get_node("note1")
				clone.size = note1.size*sizeFactor
				clone.position = (note1.size/2) - (clone.size/2)
				var parent = grid.find_child(noteName)
				parent.add_child(clone)
				clone.visible = true
		
		# update scores
		updateScores(delta)

class Note:
	var time = 0
	var pos = 0
	func _init(time: float,position: int) -> void:
		self.time = time
		self.pos = position

class Gimmick:
	var time = 0
	func _init(time: float) -> void:
		self.time = time

class TimingPoint:
	var time = 0
	var bpm = -1
	var sig = -1
	var key = -1
	func _init(time: float, bpm: float, sig: float, key: int):
		self.time = time
		self.bpm = bpm
		self.sig = sig
		self.key = key

var notes = []
var allNotes = []
var allGimmicks = []
var allTimingPoints = []
static var leadtime = 1.0
static var judgementwindow = 0.35
var time = -leadtime
var autoplay = false
var lastResync = 0.0
var maxCombo = 0
var fadeToBlackEnd = 0
var fadeToBlackNow = 0
var fadeToBlackTarget = ""

## Whether or not this Chart renders, supports playback, or supports editing.
@export_group("Features","feature")
## Whether or not the chart can be played.[br]
@export var featurePlayerEnabled = false
## Whether or not the chart is rendered.
@export var featureRendererEnabled = true
## Whether or not the chart can be edited.[br]
## If [code]featurePlayerEnabled[/code] is [code]false[/code], this may behave oddly.
@export var featureEditorEnabled = false
@export_group("Rendering","render")
## Whether or not the playback UI should be rendered.
## false is recommended if featurePlayerEnabled is false.
@export var renderPlaybackUI = true
## Whether or not the editor UI should be rendered.
## false is recommended if featurePlayerEnabled is false.
@export var renderEditorUI = true
@export_group("Playback","player")
## The mods that are enabled for this play.
## The value of each key does not matter unless specified in the ModType.
@export var playerMods:Dictionary[ModType,float] = {}
@export_group("Editor","editor")
var chartPlayer:ChartPlayer = null
var chartRenderer:ChartRenderer = null
var chartEditor:ChartEditor = null

func getTempDir() -> String:
	var env = OS.get_environment("TEMP")
	if env == "": return "/tmp/"
	if not env.ends_with("/"): env = env + "/"
	return env
	
func _song_finish() -> void:
	complete()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if featurePlayerEnabled:
		if featureEditorEnabled:
			push_error("featureEditorEnabled and featurePlayerEnabled are mutually exclusive. Please turn one off.")
		chartPlayer = ChartPlayer.new()
		chartPlayer.ready(musicPlayer,_song_finish)
		chartPlayer.playback = not featureEditorEnabled
		chartPlayer.judgementWindow = judgementwindow
	if featureEditorEnabled:
		chartEditor = ChartEditor.new()
		chartEditor.ready(self)
	if featureRendererEnabled:
		chartRenderer = ChartRenderer.new()
		chartRenderer.ready(self)
	loadChart()

func complete():
	get_tree().set_meta("accuracy",get_meta("accuracy"))
	get_tree().set_meta("rating",get_meta("rating"))
	get_tree().set_meta("maxCombo",maxCombo)
	get_tree().set_meta("score",get_meta("score"))
	get_tree().set_meta("ct_miss",get_meta("ct_miss"))
	get_tree().set_meta("ct_bad",get_meta("ct_bad"))
	get_tree().set_meta("ct_okay",get_meta("ct_okay"))
	get_tree().set_meta("ct_good",get_meta("ct_good"))
	get_tree().set_meta("ct_great",get_meta("ct_great"))
	get_tree().set_meta("ct_perfect",get_meta("ct_perfect"))
	fadeToBlackEnd = 0.15
	fadeToBlackNow = -0.05
	fadeToBlackTarget = "res://complete.tscn"
	print("BOINK!!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if fadeToBlackTarget != "":
		fadeToBlackNow += delta
		$fade.color = Color(0,0,0,fadeToBlackNow/fadeToBlackEnd)
		if fadeToBlackNow > fadeToBlackEnd:
			get_tree().change_scene_to_file(fadeToBlackTarget)
		return
	if featurePlayerEnabled: chartPlayer.process(delta,self)
	if featureRendererEnabled: chartRenderer.process(delta)
	if featureEditorEnabled: chartEditor.process(delta)

func loadDemoChart() -> void:
	for i in range(675):
		allNotes.append(Note.new(3 + (i/6.0),(i%9)+1))
	musicPlayer.stream = AudioStreamWAV.load_from_file("lost.wav")

func convertRhythiaChart(from: String,to: String) -> JSON:
	var archive = ZIPReader.new()
	archive.open(from)
	if not archive.file_exists("map"): return
	var bytes = archive.read_file("map")
	var content = bytes.get_string_from_utf8()
	var jsonRhythia = JSON.parse_string(content)
	var jsonEnnead = JSON.parse_string("{}")
	jsonEnnead["title"] = jsonRhythia["Title"]
	jsonEnnead["songAuthor"] = ""
	jsonEnnead["difficultyName"] = jsonRhythia["CustomDifficultyName"] if jsonRhythia["CustomDifficultyName"] else ""
	jsonEnnead["charters"] = jsonRhythia["Mappers"]
	jsonEnnead["onlineID"] = ""
	jsonEnnead["notes"] = []
	for note in jsonRhythia["Notes"]:
		jsonEnnead["notes"].append({
			"time":note["Time"]/1000.0,
			"pos":(round(note["X"])+round(note["Y"])*3)+1
		})
	jsonEnnead["gimmicks"] = []
	jsonEnnead["timingPoints"] = []
	content = JSON.stringify(jsonEnnead,"",true,true)
	bytes = content.to_utf8_buffer()
	var archivePacker = ZIPPacker.new()
	archivePacker.start_file("map.json")
	archivePacker.write_file(bytes)
	archivePacker.close_file()
	archivePacker.start_file("bg.png")
	archivePacker.write_file(archive.read_file(jsonRhythia["ImagePath"]))
	archivePacker.close_file()
	archivePacker.start_file("song.mp3")
	archivePacker.write_file(archive.read_file("audio"))
	archivePacker.close_file()
	archivePacker.close()
	archive.close()
	return jsonEnnead

func loadEnneadChart(path: String) -> void:
	var archive = ZIPReader.new()
	archive.open(path)
	if not archive.file_exists("map.json"): return
	var bytes = archive.read_file("map")
	var content = bytes.get_string_from_utf8()
	var json = JSON.parse_string(content)
	set_meta("songTitle",json["title"],)
	set_meta("songArtist",json["songAuthor"],)
	set_meta("difficultyName",json["difficultyName"],)
	set_meta("charter",json["charter"])
	set_meta("onlineID",json["onlineID"])
	for note in json["notes"]:
		allNotes.append(Note.new(
			note["time"],
			note["pos"]
		))
	for gimmick in json["gimmicks"]:
		allGimmicks.append(Gimmick.new(gimmick["time"]))
	for timingpoint:Dictionary[String,float] in json["timingPoints"]:
		allTimingPoints.append(TimingPoint.new(
			timingpoint.get("time"),
			timingpoint.get("bpm",60.0),
			timingpoint.get("sig",4.0),
			round(timingpoint.get("key",1.0))
		))

func loadRhythiaChart(path: String) -> void:
	var archive = ZIPReader.new()
	archive.open(path)
	if not archive.file_exists("map"): return
	var bytes = archive.read_file("map")
	var content = bytes.get_string_from_utf8()
	var json = JSON.parse_string(content)
	set_meta("title",json["Title"])
	set_meta("mappers",json["Mappers"])
	for note in json["Notes"]:
		allNotes.append(Note.new(
			note["Time"]/1000.0,
			(round(note["X"])+round(note["Y"])*3)+1))
	
	#var audioPath = getTempDir() + "audio" + FileExtensionHandler.determineAudioExtension(archive.read_file("audio"))
	#var audioFile = FileAccess.open(audioPath,FileAccess.WRITE)
	#audioFile.store_buffer(archive.read_file("audio"))
	#audioFile.close()
	musicPlayer.stream = FileExtensionHandler.loadArbitraryAudio(archive.read_file("audio"))
	
	#var coverPath = getTempDir() + "cover" + FileExtensionHandler.determineImageExtension(archive.read_file("cover"))
	#var coverFile = FileAccess.open(coverPath,FileAccess.WRITE)
	#coverFile.store_buffer(archive.read_file("cover"))
	#coverFile.close()
	$bg.texture = FileExtensionHandler.loadArbitraryImage(archive.read_file("cover"))
	archive.close()

func loadChart() -> void:
	#loadDemoChart() # TODO: replace with actual chart loading
	loadRhythiaChart("/home/cookii/Downloads/rhythia-4f634ff1-00b7-4e14-a0c3-074e863a7ac9-1781125160342.rhm")
	set_meta("notes",len(allNotes))
	musicPlayer.volume_linear = 0.05
	reloadNotes()
	chart_loaded.emit(notes)

func reloadNotes() -> void:
	notes.clear()
	notes.append_array(allNotes)
