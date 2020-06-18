extends Resource

class_name YarnShortcutOption

export(String) var message
export(Array) var body

func _to_string():
	return "[ShortcutOption] " + message + " [\n" + PoolStringArray(body).join("\n") + "\n]"
