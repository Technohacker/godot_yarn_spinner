extends Node

# Boilerplate script header common to all generated Yarn scripts
const SCRIPT_HEADER = """extends Node

signal dialogue(yarn_node, actor, message)
signal command(yarn_node, command, parameters)
signal options(yarn_node, options)

var story_state = null
var current_function := \"Start\"
var variables := {}

func set_current_yarn_thread(thread_name: String) -> void:
	current_function = thread_name
	story_state = null

func set_variable(var_name: String, value) -> void:
	variables[\"$\" + var_name] = value

func get_variable(var_name: String):
	return variables[\"$\" + var_name]

func step_through_story(value = null) -> void:
	if current_function != "":
		if story_state is GDScriptFunctionState:
			story_state = story_state.resume(value)
		else:
			story_state = call(current_function)
"""

# Function template
# Newlines are intentional
const FUNCTION = """
func {function_name}() -> void:
"""

# Create a string containing a function in GDScript
static func function(function_name: String, body: Array) -> String:
	# Prepare the start of the function
	var funcstr = FUNCTION.format({
		"function_name": function_name
	})

	# Append the body with indents and newlines
	for line in body:
		funcstr += "\t" + line + "\n"

	return funcstr

static func command(command: String, parameters: Array) -> Array:
	match command:
		"wait":
			return [
				"yield(get_tree().create_timer({duration}), \"timeout\")".format({
					"duration": float(parameters[0])
				})
			]

		# Set a variable to the result of an expression
		"set":
			return [
				"variables[\"{name}\"] {expression}".format({
					"name": parameters[0],
					"expression": preload("./parse_utils.gd").tokens_to_expression(parameters.slice(1, parameters.size()))
				})
			]

		# Stop a block
		"stop":
			return [
				"return"
			]

		# Other command. All parameters are sent as strings
		_:
			for i in parameters.size():
				if !parameters[i].begins_with("\""):
					parameters[i] = "\"" + parameters[i] + "\""

			return [
				"emit_signal(\"command\", self, \"{command}\", {params})".format({
					"command": command,
					"params": parameters
				}),
				"yield()"
			]

static func dialogue(actor: String, message: String) -> Array:
	return [
		"emit_signal(\"dialogue\", self, \"{actor}\", \"{message}\".format(variables))".format({
			"actor": actor,
			"message": message
		}),
		"yield()"
	]

static func jump(target: String) -> Array:
	return [
		"current_function = \"%s\"" % target,
		"return %s()" % target
	]

static func build_options(opts: Array) -> Array:
	var parsed_options := []
	for option in opts:
		parsed_options.append("\"" + option.message + "\".format(variables)")

	return [
		"emit_signal(\"options\", self, [{options}])".format({
			"options": PoolStringArray(parsed_options).join(", ")
		}),
		"match yield():"
	]

static func options(opts: Array) -> Array:
	var body := build_options(opts)

	for option in opts:
		body.append("\t\"" + option.message + "\":")
		for line in jump(option.target):
			body.append("\t\t" + line)

	return body

static func shortcut_options(opts: Array) -> Array:
	var body := build_options(opts)

	for option in opts:
		body.append("\t\"" + option.message + "\":")

		var lines = convert_fibres(option.body)
		if lines.empty():
			body.append("\t\tpass")
		else:
			for line in lines:
				body.append("\t\t" + line)

	return body

static func conditionals(conditionals: Array) -> Array:
	var body = []

	for i in conditionals.size():
		match i:
			0:
				body.append("if {expression}:".format({
					"expression": conditionals[i].expression,
				}))
			_:
				if conditionals[i].expression != "":
					body.append("elif {expression}:".format({
						"expression": conditionals[i].expression,
					}))
				else:
					body.append("else:")

		var lines = convert_fibres(conditionals[i].body)
		if lines.empty():
			body.append("\tpass")
		else:
			for line in lines:
				body.append("\t" + line)

	return body

static func yarn_to_gd(story: YarnStory) -> GDScript:
	var script = GDScript.new()

	# Start the script out with boilerplate
	script.source_code += SCRIPT_HEADER

	if (typeof(story.nodes) == TYPE_DICTIONARY):
		for thread in story.nodes:
			# Each thread is a function
			var body := convert_fibres(story.nodes[thread].body)
			script.source_code += function(thread, body)
	else:
		printerr("could not read story nodes type was {typeof(story.nodes)}")

	script.reload()

	return script

static func convert_fibres(fibres: Array) -> Array:
	var body := []

	var i = 0
	while i < fibres.size():
		var fibre = fibres[i]

		if fibre is YarnCommand:
			fibre = (fibre as YarnCommand)
			body += command(fibre.command, fibre.parameters)
		elif fibre is YarnDialogue:
			fibre = (fibre as YarnDialogue)
			body += dialogue(fibre.actor, fibre.message)
		elif fibre is YarnJump:
			fibre = (fibre as YarnJump)
			body += jump(fibre.target)
		elif fibre is YarnOption:
			var options = [fibre]

			var j = 1
			while (i + j) < fibres.size() && fibres[i + j] is YarnOption:
				options.append(fibres[i + j])
				j += 1

			i += (j - 1)

			body += options(options)
		elif fibre is YarnShortcutOption:
			var options = [fibre]

			var j = 1
			while (i + j) < fibres.size() && fibres[i + j] is YarnShortcutOption:
				options.append(fibres[i + j])
				j += 1

			i += (j - 1)

			body += shortcut_options(options)
		elif fibre is YarnConditional:
			var conditionals = [fibre]
			var j = 1
			while (i + j) < fibres.size() && fibres[i + j] is YarnConditional:
				conditionals.append(fibres[i + j])
				j += 1

			i += (j - 1)
			body += conditionals(conditionals)
		else:
			body += []

		i += 1
	return body
