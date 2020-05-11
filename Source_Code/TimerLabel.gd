extends Label

onready var timer : Timer = get_node("../../../../Timer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = str(GlobalValues.timer_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.text = "%.1f" % timer.time_left
