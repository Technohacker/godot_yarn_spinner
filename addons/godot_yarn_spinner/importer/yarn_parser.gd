extends Reference

var parse_utils = preload("./parse_utils.gd").new()

"""
Reads a line and counts its level of indentation
"""
func read_line_with_indent(file: File) -> Dictionary:
	var line = file.get_line()
	var dedent = line.dedent()
	return {
		"indent": line.length() - dedent.length(),
		"content": dedent.strip_edges()
	}

"""
Parses the given Yarn file line-by-line
"""
func parse(yarn_file: File) -> YarnStory:
	var script := YarnStory.new()

	while !yarn_file.eof_reached():
		var line: String = read_line_with_indent(yarn_file)["content"]

		if line.begins_with("title:"):
			# New node
			var title = line.replace("title:", "").strip_edges()
			script.add_node(title, new_node(yarn_file))

	return script

"""
Starts a new node
"""
func new_node(file: File) -> YarnNode:
	var node := YarnNode.new()

	# Parse header until body starts
	while !file.eof_reached():
		var line: String = read_line_with_indent(file)["content"]

		if line.begins_with("tags:"):
			var tags := line.replace("tags:", "").split(" ")
			for tag in tags:
				node.add_tag(tag.strip_edges())
		elif line == "---":
			break
		else:
			var header := line.split(":", true, 1)
			node.add_header(header[0].strip_edges(), header[1].strip_edges())

	# Header's done, parse body now
	node.body = parse_body(file)

	return node

func parse_body(file: File, indent_level := 0) -> Array:
	# The body is an array of Yarn* resources
	var body := []

	while !file.eof_reached():
		# Read the next line
		var line := read_line_with_indent(file)

		if line.indent < indent_level:
			# Return early if we fall to a lower indent level
			# Rewind the file by the length of the line before quitting
			file.seek(file.get_position() - (line.indent + line.content.length() + 1))
			return body
		elif line.indent > indent_level:
			# Increase the indent level when we find a higher indent
			indent_level = line.indent

		if line.content.begins_with("[["):
			# Option/Jump
			var option = line.content.replace("[[", "").replace("]]", "").split("|", true, 1)
			if option.size() == 2:
				# Option
				# Syntax: [[<message>|<target>]]
				var node = YarnOption.new()
				node.message = option[0].strip_edges()
				node.target = option[1].strip_edges()
				body.append(node)
			else:
				# Jump
				# Syntax: [[<target>]]
				var node = YarnJump.new()
				node.target = option[0].strip_edges()
				body.append(node)

		elif line.content.begins_with("->"):
			# Shortcut option. Parse the sub-body with this function
			# Syntax:
			# -> <Message> << if <condition> >>
			#	<body>
			var node = YarnShortcutOption.new()
			var condition = ""
			if line.content.ends_with(">>"):
				# This option is gated with a condition
				var conditional = (line.content.split("<<", false, 1)[1].replace(">>", "") as String).split(" ", false, 1)
				line.content = line.content.split("<<", false, 1)[0]
				if conditional[0] == "if":
					print(conditional)
					# Just making sure it's an actual conditional
					condition = parse_utils.tokens_to_expression(parse_command_args(conditional[1]))

			node.condition = condition
			node.message = line.content.replace("->", "").strip_edges()
			# +1 to start it off
			node.body = parse_body(file, indent_level + 1)
			print(node)
			body.append(node)

		elif line.content.begins_with("<<"):
			# Command/Conditional
			# Syntax:
			# << <command> <arguments> >>
			var command = (line.content.replace("<<", "").replace(">>", "") as String).split(" ", false, 1)

			if (!command.empty()):
				# This could be a conditional
				match command[0]:
					"if", "elif", "else":
						# Conditional. Parse the sub-body with this function
						# Syntax:
						# << <type> <expression> >>
						var node = YarnConditional.new()
						node.expression = parse_utils.tokens_to_expression(parse_command_args(command[1] if command.size() != 1 else ""))
						# +1 to start it off
						node.body = parse_body(file, indent_level + 1)
						
						# The conditional could also only contain options, in which case, replace it with
						# YarnOption blocks with conditions
						var only_options = true
						for subnode in node.body:
							if !(subnode is YarnOption):
								# We have a non-option node, put the conditional node back in
								body.append(node)
								only_options = false
								break

						if only_options:
							for i in node.body.size():
								(node.body[i] as YarnOption).condition = node.expression
								body.append(node.body[i])

					"endif":
						# Ignore since we've handled the other conditionals
						# TODO: Not strictly compatible with Yarn since endif marks the end of an if-else tree,
						# not by indentation
						pass

					_:
						# Plain command
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
			# Syntax:
			# <Actor>: <Message>
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

"""
Convert command arguments/expression strings into an array of tokens
"""
func parse_command_args(args: String) -> Array:
	# Regex to match subquotes:
	# Split into individual tokens separated by spaces
	# Includes string quotes if any
	# https://stackoverflow.com/questions/2817646/javascript-split-string-on-space-or-on-quotes-to-array
	var commandRegex = '[^\\s"]+|"[^"]+"'
	var params = []
	var regex = RegEx.new()

	regex.compile(commandRegex)

	for param in regex.search_all(args):
		params.push_back(param.get_string() as String)

	return params
