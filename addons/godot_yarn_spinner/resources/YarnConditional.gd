extends Resource

class_name YarnConditional

export(String) var expression
export(Array) var body

func _to_string():
	return "[Conditional] Expression: " + expression + " [\n" + PoolStringArray(body).join("\n") + "\n]"
