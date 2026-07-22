class_name FileExtensionHandler

static func compare(a:PackedByteArray,b:PackedByteArray) -> bool:
	var index = 0
	for i in a:
		if i != b[index]: return false
		index += 1
	return true

static func find(a:PackedByteArray,sequence:PackedByteArray) -> int:
	var buffer = a.duplicate() # this is destructive; make a copy first
	var index = 0
	while len(buffer) > 0:
		if compare(buffer,sequence): return index
		index += 1
		buffer.remove_at(0)
	return 0

static func determineImageExtension(buffer:PackedByteArray) -> String:
	if compare(PackedByteArray([137,80,78,71,13,10,26,10]),buffer):
		return ".png"
	if compare(PackedByteArray([0xFF,0xD8]),buffer):
		var index = find(buffer,[0xFF,0xE0])
		index += 2
		if compare(PackedByteArray([74,70,73,70,0]),buffer.slice(index)):
			return ".jpg" # GOD DAMN WHY IS THAT SO MUCH EFFORT JESUS FUCKING CHRIST
	printerr("Could not determine correct image extension. Returning empty string and hoping the caller can figure it out.")
	return ""

static func determineAudioExtension(buffer:PackedByteArray) -> String:
	if compare(PackedByteArray([82,73,70,70]),buffer):
		return ".wav"
	if compare(PackedByteArray([73,68,51]),buffer):
		return ".mp3" # TAGGED mp3
	if compare(PackedByteArray([0x4F,0x67,0x67,0x53]),buffer):
		return ".ogg"
	if compare(PackedByteArray([0xff,0xfb]),buffer):
		return ".mp3" # UNTAGGED mp3. This is a less confident answer.
	printerr("Could not determine correct audio extension. Returning empty string and hoping the caller can figure it out.")
	return ""

static func loadArbitraryImage(buffer:PackedByteArray) -> Texture:
	var extension = determineImageExtension(buffer)
	var image = Image.new()
	if extension == ".png":
		image.load_png_from_buffer(buffer)
	elif extension == ".jpg":
		image.load_jpg_from_buffer(buffer)
	if image.is_empty():
		printerr("Could not load image from extension "+extension+"!")
		return null
	return ImageTexture.create_from_image(image)
static func loadArbitraryAudio(buffer:PackedByteArray) -> AudioStream:
	var extension = determineAudioExtension(buffer)
	if extension == ".wav":
		return AudioStreamWAV.load_from_buffer(buffer)
	elif extension == ".mp3":
		return AudioStreamMP3.load_from_buffer(buffer)
	elif extension == ".ogg":
		return AudioStreamOggVorbis.load_from_buffer(buffer)
	printerr("Could not load audio from extension "+extension+"!")
	return null
