extends Control

signal chart_loaded

class Note:
	var time = 0
	var pos = 0
	func _init(time: float,position: int) -> void:
		self.time = time
		self.pos = position

var notes = []
static var leadtime = 1.0
static var judgementwindow = 0.35
var time = -1.0
var musicPlayer: AudioStreamPlayer
var musicStream: AudioStreamWAV

var scoreDisplay = 0.0
var ratingDisplay = 0.0
var accDisplay = 100.0
var playback = false
var autoplay = true
var lastResync = 0.0

func getTempDir() -> String:
	var env = OS.get_environment("TEMP")
	if env == "": return "/tmp/"
	if not env.ends_with("/"): env = env + "/"
	return env

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	musicPlayer = get_parent().find_child("music")
	musicStream = musicPlayer.stream
	loadChart()

func complete():
	pass

func intCommas(value: int):
	var ret = str(value)
	var loop_end = 0 if value > -1 else 1
	for i in range(ret.length()-3,loop_end,-3):
		ret = ret.insert(i,",")
	return ret

func updateScores(delta: float):
	if not playback:
		set_meta("totalAccuracy",0)
		set_meta("judgements",0)
		set_meta("score",0)
		set_meta("ct_miss",0)
		set_meta("ct_bad",0)
		set_meta("ct_okay",0)
		set_meta("ct_good",0)
		set_meta("ct_perfect",0)
		set_meta("combo",0)
	if get_meta("judgements") == 0:
		set_meta("accuracy",100)
	else:
		set_meta("accuracy",get_meta("totalAccuracy")/get_meta("judgements")*100)
	set_meta("rating",(get_meta("difficulty")*1.1)*((get_meta("accuracy")/100)**2))
	var fastFactor = 0.1/delta
	var slowFactor = 0.2/delta
	scoreDisplay = (scoreDisplay*fastFactor+get_meta("score"))/(fastFactor+1)
	ratingDisplay = (ratingDisplay*slowFactor+get_meta("rating"))/(slowFactor+1)
	accDisplay = (accDisplay*slowFactor+get_meta("accuracy"))/(slowFactor+1)
	$VBoxContainer/score.text = intCommas(round(scoreDisplay))
	$VBoxContainer/rating.text = "Rating: " + str(round(ratingDisplay*100)/100) + "*"
	$VBoxContainer/accuracy.text = "Accuracy: " + str(round(accDisplay*100)/100) + "%"
	$ProgressBar.max_value = musicPlayer.stream.get_length()
	$ProgressBar.value = time

func finishJudgement(accuracy: float,score: float,judgement: String):
	set_meta("ct_"+judgement,get_meta("ct_"+judgement)+1)
	set_meta("judgements",get_meta("judgements")+1)
	set_meta("totalAccuracy",get_meta("totalAccuracy")+accuracy)
	set_meta("score",get_meta("score")+score)
	if judgement == "miss":
		set_meta("combo",0)
	else:
		set_meta("combo",get_meta("combo")+1)
	$Judgement.text = TranslationServer.translate("judgement."+judgement) + "\n" + str(get_meta("combo"))

func doJudgement(note: Note, time: float) -> void:
	var distance = abs(note.time-time)
	var score = 1-(distance/judgementwindow)
	score = clamp(score,0,1)
	score **= 2
	score *= 10000000/get_meta("notes")
	if distance > judgementwindow:
		finishJudgement(0.0,score,"miss")
	elif distance > judgementwindow/2:
		finishJudgement(0.4,score,"bad")
	elif distance > judgementwindow/3:
		finishJudgement(0.6,score,"okay")
	elif distance > judgementwindow/4:
		finishJudgement(0.8,score,"good")
	else:
		finishJudgement(1.0,score,"perfect")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var start = 0
	if time > delta+AudioServer.get_time_since_last_mix():
		playback = musicPlayer.playing
	if Input.is_action_just_pressed("editor_playback"):
		playback = not playback
	if musicPlayer.playing != playback and time > 0:
		musicPlayer.playing = playback
		musicPlayer.seek(time)
	if playback:
		if time > 0:
			time = musicPlayer.get_playback_position()+AudioServer.get_time_since_last_mix()
		else:
			time += delta
		#time += delta
		#if (Time.get_ticks_msec()-lastResync > 1):
			#if abs((musicPlayer.get_playback_position()+AudioServer.get_time_since_last_mix())-time) > 0.05:
				#start = Time.get_ticks_msec()
				#musicPlayer.seek(time)
				#print("resync time")
				#print(Time.get_ticks_msec()-start)
				#lastResync = Time.get_ticks_msec()
	else:
		musicPlayer.stop()
	size = get_viewport_rect().size
	$GridContainer.position = (size/2)-($GridContainer.size/2)
	var gsize = min(size.x,size.y)/2
	$GridContainer.size = Vector2(gsize,gsize)
	for panel: Panel in $GridContainer.get_children():
		var targetcolor = Color(0.5,0.5,0.5)
		var factor = 0.05/delta
		var color = (panel.self_modulate*factor+targetcolor)/(factor+1)
		if Input.is_action_pressed(panel.name):
			color = Color(1.0,1.0,1.0)
		panel.self_modulate = color
		for indicator: Panel in panel.get_children():
			indicator.queue_free()
	#print("for note in notes")
	#print(Time.get_ticks_msec()-start)
	while len(notes) != 0 and self.time-notes[0].time > judgementwindow:
		if playback: doJudgement(notes[0],time)
		notes.remove_at(0)
	if len(notes) == 0:
		complete()
	# render notes
	for note: Note in notes:
		if note.time-leadtime < self.time:
			var clone: Panel = $hitindicator.duplicate()
			var sizeFactor = (self.time-note.time+leadtime)/leadtime
			var noteName = "note" + str(note.pos)
			if (sizeFactor > 1): sizeFactor = 0
			sizeFactor = sizeFactor*sizeFactor
			clone.modulate = Color(1,1,1,sizeFactor)
			clone.size = $GridContainer/note1.size*sizeFactor
			clone.position = ($GridContainer/note1.size/2) - (clone.size/2)
			var parent = $GridContainer.find_child(noteName)
			parent.add_child(clone)
			clone.visible = true
	#print("for note in notes")
	#print(Time.get_ticks_msec()-start)
	var index = 0
	var toRemove = []
	var pressedLanes = []
	for i in range(1,10):
		if Input.is_action_just_pressed("note" + str(i)): pressedLanes.append(i)
	var candidates = []
	for i in range(1,10):
		candidates.append([])
	for note: Note in notes:
		if note.time > time+judgementwindow: break
		if abs(note.time-time) > judgementwindow: continue
		if (not note.pos in pressedLanes) and autoplay == false: continue
		if autoplay == true and abs(note.time-time) > delta+0.01: continue
		# self.time = note.time ; sizeFactor = 0.0
		# self.time = note.time+leadtime ; sizeFactor = 1.0
		#
		# sizeFactor = ((self.time-note.time)/leadtime)*0.5
		var noteName = "note" + str(note.pos)
		candidates[note.pos-1].append(note)
		if playback: doJudgement(note,time)
		index += 1
	#print("for lanecandidates in candidates: for candidate in lanecandidates")
	start = Time.get_ticks_msec()
	for lanecandidates in candidates:
		var closestCandidateDistance = time+1000
		var closestCandidate = null
		for candidate: Note in lanecandidates:
			var distance = abs(candidate.time-time)
			if distance < closestCandidateDistance:
				closestCandidateDistance = distance
				closestCandidate = candidate
			else:
				break
		notes.erase(closestCandidate)
	updateScores(delta)
	#print(Time.get_ticks_msec()-start)

func loadDemoChart() -> void:
	for i in range(675):
		notes.append(Note.new(3 + (i/6.0),(i%9)+1))
	musicPlayer.stream = AudioStreamWAV.load_from_file("lost.wav")

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
		notes.append(Note.new(
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
	$Sprite2D.texture = FileExtensionHandler.loadArbitraryImage(archive.read_file("cover"))

func loadChart() -> void:
	#loadDemoChart() # TODO: replace with actual chart loading
	loadRhythiaChart("/home/cookii/Downloads/rhythia-4f634ff1-00b7-4e14-a0c3-074e863a7ac9-1781125160342.rhm")
	set_meta("notes",len(notes))
	musicPlayer.volume_linear = 0.05
	chart_loaded.emit(notes)
