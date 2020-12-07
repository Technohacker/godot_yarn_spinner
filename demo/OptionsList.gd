extends VBoxContainer

signal select_option(option)

func _on_YarnStory_options(yarn_node, options):
	for option in options:
		var button = Button.new()
		button.text = option
		button.connect("pressed", self, "_on_option_selected", [option])
		self.add_child(button)
	self.visible = true

func _on_option_selected(option):
	reset_menu()
	emit_signal("select_option", option)

func reset_menu():
	self.visible = false
	for option in self.get_children():
		option.queue_free()
