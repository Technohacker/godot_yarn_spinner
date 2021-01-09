extends Resource

class_name YarnOption

export(String) var message
export(String) var target

func _to_string():
	return "[Option] message: " + message + " to: " + target
