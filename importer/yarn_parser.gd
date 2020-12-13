extends Node

"""
Reads a line and counts its level of indentation
"""
static func read_line_with_indent(file: File):
	var line = file.get_line()
	var dedent = line.dedent()
	return {
		"indent": line.length() - dedent.length(),
		"content": line.dedent().strip_edges()
	}

"""
Parses the given Yarn file line-by-line
"""
static func parse(yarn_file: File):
	var script = YarnStory.new()

	while !yarn_file.eof_reached():
		var line = read_line_with_indent(yarn_file)["content"]

		if line.begins_with("title:"):
			# New node
			var title = line.replace("title:", "").strip_edges()
			script.add_node(title, new_node(yarn_file))

	return script

"""
Starts a new node
"""
static func new_node(file: File):
	var node = YarnNode.new()

	# Parse header until body starts
	while !file.eof_reached():
		var line = read_line_with_indent(file)["content"]

		if line.begins_with("tags:"):
			var tags = line.replace("tags:", "").split(" ")
			for tag in tags:
				node.add_tag(tag.strip_edges())
		elif line == "---":
			break
		else:
			var header = line.split(":", true, 1)
			node.add_header(header[0].strip_edges(), header[1].strip_edges())

	# Header's done, parse body now
	node.body = parse_body(file)

	return node



static func parse_body(file: File, indent_level = 0):
	var body = []

	while !file.eof_reached():
		var line = read_line_with_indent(file)

		if line.indent < indent_level:
			# Early return if we fall to a lower indent level
			file.seek(file.get_position() - (line.indent + line.content.length() + 1))
			return body
		elif line.indent > indent_level:
			indent_level = line.indent

		if line.content.begins_with("[["):
			# Option/Jump
			var option = line.content.replace("[[", "").replace("]]", "").split("|", true, 1)
			if option.size() == 2:
				# Option
				var node = YarnOption.new()
				node.message = option[0].strip_edges()
				node.target = option[1].strip_edges()
				body.append(node)
			else:
				# Jump
				var node = YarnJump.new()
				node.target = option[0].strip_edges()
				body.append(node)
		elif line.content.begins_with("->"):
			# Shortcut option. Parse the sub-body with this function
			var node = YarnShortcutOption.new()
			node.message = line.content.replace("->", "").strip_edges()
			# +1 to start it off
			node.body = parse_body(file, indent_level + 1)
			body.append(node)
		elif line.content.begins_with("<<"):
			# Command
			var command = (line.content.replace("<<", "").replace(">>", "") as String).split(" ", false, 1)

			if (!command.empty()):
				var node = YarnCommand.new()
				node.command = command[0]
				if (command.size() > 1):
					node.parameters = parse_command_args(command[1])
				else:
					node.parameters = []
				body.append(node)

		elif line.content == "===":
			# End of body
			break
		elif line.content.length() != 0 && !line.content.begins_with("//"):
			# Normal dialogue (not a comment)
			var dialogue = line.content.split(":")
			var node = YarnDialogue.new()
			if dialogue.size() == 2:
				# Actor mentioned
				node.actor = dialogue[0].strip_edges()
				node.message = dialogue[1].strip_edges()
			else:
				# No actor
				node.actor = ""
				node.message = dialogue[0].strip_edges()

			# Apply character escapes to the message
			node.message = node.message.json_escape()

			body.append(node)

	return body


static func parse_command_args(args : String):
	# Regex to match subquotes: 
	# https://stackoverflow.com/questions/2817646/javascript-split-string-on-space-or-on-quotes-to-array
	var commandRegex = '[^\\s"]+|"[^"]+"'
	var params = []
	var regex = RegEx.new()

	regex.compile(commandRegex)

	for param in regex.search_all(args):
		params.push_back(param.get_string() as String)

	return params

