extends Resource

class_name YarnStory

export(Dictionary) var nodes

func add_node(title: String, node: YarnNode):
	nodes[title] = node

func _to_string():
	return "[Story]\nNodes: " + to_json(nodes)
