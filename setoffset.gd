extends Control
class_name UtilSetOffset

# Called every frame. 'delta' is the elapsed time since the previous frame.
static func position(this:Control,delta: float) -> void:
	var offset = this.get_meta("offset",Vector2(0.5,0.5))
	var minsz = this.get_meta("size",Vector2(0.0,0.0))
	this.global_position = (this.get_viewport_rect().size*offset)-(this.size*offset)
	this.custom_minimum_size = (this.get_viewport_rect().size*minsz)

func _progress(delta: float) -> void:
	position(self,delta)
