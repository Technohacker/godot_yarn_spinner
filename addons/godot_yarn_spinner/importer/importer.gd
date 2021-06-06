tool
extends EditorImportPlugin

func get_importer_name():
	return "com.technohacker.yarn"

func get_visible_name():
	return "Yarn Story"

func get_recognized_extensions():
	return ["yarn"]

func get_save_extension():
	return "gd"

func get_resource_type():
	return "GDScript"

func get_import_options(preset):
	return []

func get_preset_count():
	return 0

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var path = "%s.%s" % [save_path, get_save_extension()]
	# Delete the existing Yarn-to-GD file if it exists
	# TODO: Might not be necessary
	var dir = Directory.new()
	if dir.file_exists(path):
		dir.remove(path)

	# Open the Yarn story file
	var file = File.new()

	var err = file.open(source_file, File.READ)
	if err != OK:
		printerr("Yarn Story file not found")
		return err

	# Parse the Yarn file
	var story = preload("yarn_parser.gd").parse(file)
	# Translate to GDScript
	var script = preload("yarn_to_gd.gd").yarn_to_gd(story)

	# Save to the final path
	return ResourceSaver.save(path, script)
