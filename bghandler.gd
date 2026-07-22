extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if texture == null:
		printerr("Texture is null!")
		return
	var vpsz = get_viewport_rect().size
	var txsz = texture.get_size()
	var widthScale = vpsz.x/txsz.x
	var heightScale = vpsz.y/txsz.y
	var maxSize = max(widthScale,heightScale)
	position = vpsz/2
	scale = Vector2(maxSize,maxSize)
	var shader: ShaderMaterial = material;
	shader.set_shader_parameter("dim",get_meta("dim",1.0))
