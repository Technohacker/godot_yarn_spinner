extends Resource

class_name YarnNode

export(Array) var tags
export(Dictionary) var headers
export(Array) var body

func add_tag(tag: String):
	tags.append(tag)

func add_header(key: String, value: String):
	headers[key] = value

func add_to_body(value):
	body.append(value)

func _to_string():
	return "[Node]\nTags: " + PoolStringArray(tags).join(", ") + " Headers: " + to_json(headers) + " Body: [\n" + PoolStringArray(body).join("\n") + "\n]"
