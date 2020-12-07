extends CanvasLayer

var commands = {}

var block_progress = false

func _init():
	commands['showcake'] = funcref(self, "show_cake")

func _ready():
	$YarnStory.Start()

func _on_DialogText_Label_line_complete():
	if (!block_progress):
		$YarnStory.step_through_story()

func _on_YarnStory_options(yarn_node, options):
	block_progress = true

func _on_select_option(option):
	block_progress = false
	$YarnStory.step_through_story(option)

func _on_YarnStory_command(yarn_node, command, parameters):
	if (commands.has(command)):
		commands[command].call_funcv(parameters)

func show_cake(visiblity):
	$TextureRect.visible = visiblity
