extends Resource

class_name YarnShortcutOption

export(String) var message
export(String) var condition
export(Array) var body

func _to_string():
	return "[ShortcutOption] if: " + condition + " message: " + message + " [\n" + PoolStringArray(body).join("\n") + "\n]"
