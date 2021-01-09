extends Resource

class_name YarnJump

export(String) var target

func _to_string():
	return "[Jump] to: " + target
