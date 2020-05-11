extends MarginContainer

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var font = self.get_parent().get_font("font_name", "")
	font.size = 48
	add_font_override("font_name", font)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
