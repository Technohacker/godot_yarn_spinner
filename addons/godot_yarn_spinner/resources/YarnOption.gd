extends Resource

class_name YarnOption

export(String) var message
export(String) var condition
export(String) var target

func _to_string():
	return "[Option] if: " + condition + " message: " + message + " to: " + target
