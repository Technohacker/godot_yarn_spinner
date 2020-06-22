extends Node

const SCRIPT_HEADER = """extends Node

signal dialogue(actor, message)
signal command(command, parameters)
signal options(options)

var story_state = null
var current_function = \"start\"

func set_current_yarn_thread(thread_name: String):
	current_function = thread_name
	story_state = null

func step_through_story(value = null):
	if current_function != "":
		if story_state is GDScriptFunctionState:
			story_state = story_state.resume(value)
		else:
			story_state = call(current_function)
"""

const FUNCTION = """
func {function_name}():
"""

static func function(function_name, body):
	var funcstr = FUNCTION.format({
		"function_name": function_name
	})
	for line in body:
		funcstr += "\t" + line + "\n"
	return funcstr

static func command(command, parameters):
	match command:
		"wait":
			return [
				"yield(get_tree().create_timer({duration}), \"timeout\")".format({
					"duration": float(parameters[0])
				})
			]
		"stop":
			return [
				"return"
			]
		_:
			var parameters_str = "["
			for param in parameters:
				parameters_str += "\"" + param.replace("\"", "\\\"") + "\","

			parameters_str += "]"

			return [
				"emit_signal(\"command\", \"{command}\", {parameters})".format({
					"command": command,
					"parameters": parameters_str
				}),
				"yield()"
			]

static func dialogue(actor, message):
	return [
		"emit_signal(\"dialogue\", \"{actor}\", \"{message}\")".format({
			"actor": actor,
			"message": message
		}),
		"yield()"
	]

static func jump(target: String):
	return [
		"current_function = \"%s\"" % target,
		"return %s()" % target
	]

static func options(opts: Array):
	var options_str = "["
	for option in opts:
		options_str += "\"" + option.message + "\", "

	options_str += "]"

	var body = [
		"emit_signal(\"options\", {options})".format({
			"options": options_str
		}),
		"match yield():"
	]

	for option in opts:
		body += [
			"\t\"" + option.message + "\":"
		]
		for line in jump(option.target):
			body += [
				"\t\t" + line
			]

	return body

static func shortcut_options(opts: Array):
	var options_str = "["
	for option in opts:
		options_str += "\"" + option.message + "\", "

	options_str += "]"

	var body = [
		"emit_signal(\"options\", {options})".format({
			"options": options_str
		}),
		"match yield():"
	]

	for option in opts:
		body += [
			"\t\"" + option.message + "\":",
		]
		
		var lines = convert_fibres(option.body) as Array
		if lines.empty():
			body += [
				"\t\tpass"
			]
		else:
			for line in lines:
				body += [
					"\t\t" + line
				]

	return body


static func yarn_to_gd(story: YarnStory):
	var script = GDScript.new()

	# Start the script out with boilerplate
	script.source_code += SCRIPT_HEADER

	for thread in story.nodes:
		# Each thread is a function
		var body = convert_fibres(story.nodes[thread].body)

		script.source_code += function(thread, body)

	script.reload()

	return script

static func convert_fibres(fibres: Array):
	var body = []

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
		else:
			body += []

		i += 1
	return body
