extends Resource

class_name YarnDialogue

export(String) var actor
export(String) var message

func _to_string():
	return "[Dialogue] " + actor + ": " + message
