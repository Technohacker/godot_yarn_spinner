extends Resource

class_name YarnCommand

export(String) var command
export(Array) var parameters

func _to_string():
	return "[Command] " + command + " [" + parameters.join(", ") + "]"
