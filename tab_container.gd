extends TabContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	UtilSetOffset.position(self,delta)


func _on_tab_clicked(tab: int) -> void:
	if get_tab_title(tab) == "Quit":
		get_tree().quit(0)
