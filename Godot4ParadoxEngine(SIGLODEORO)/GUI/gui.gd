extends CanvasLayer

var province_overview_open = false

signal debugIncreasePopulation
signal debugDecreasePopulation
signal debugTransferPopulation

signal debugOpenWorldBuilder
signal debugCreatingProvince
signal debugModifyingProvince

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func open_province_overview(province: Province) -> void:
	province_overview_open = true
	#print("GUI: opening province overview...")
	$ProvinceOverviewPanel.visible = true
	$ProvinceOverviewPanel/ProvinceNameRichTextLabel.text = province.province_name
	$ProvinceOverviewPanel/HBoxContainer/PopulationItemList.clear()
	if province.province_population.size() > 0:
		for population in province.province_population:
			var province_text = str(population.type.population_class_name, "amount: ", str(population.amount), "unrest: ", str(population.unrest), "orthodoxy: ", str(population.orthodoxy), "zeal: ", str(population.zeal), "literate: ", str(population.literate))
			$ProvinceOverviewPanel/HBoxContainer/PopulationItemList.add_item(province_text)

func close_province_overview() -> void:
	province_overview_open = false
	$ProvinceOverviewPanel.visible = false

func _on_increase_pop_button_pressed():
	debugIncreasePopulation.emit()


func _on_decrease_pop_button_pressed():
	debugDecreasePopulation.emit()


func _on_transfer_pop_button_pressed():
	debugTransferPopulation.emit()


func _on_province_overview_close_button_pressed():
	close_province_overview()


func _on_create_province_button_pressed() -> void:
	# used to generate province data for json file
	debugCreatingProvince.emit() # to control then gui.debugCreatingProvince.connect($SiglodeOroWorldBuilder.development_create_new_province)
	visible = false # will have to reverse this


func _on_modify_province_button_pressed() -> void:
	debugModifyingProvince.emit()
	visible = false


func _on_world_builder_button_pressed() -> void:
	debugOpenWorldBuilder.emit()
	$PopulationDebugToolPanel/HBoxContainer/VBoxContainer2/CreateProvinceButton.visible = true
	$PopulationDebugToolPanel/HBoxContainer/VBoxContainer2/ModifyProvinceButton.visible = true
	$PopulationDebugToolPanel/HBoxContainer/VBoxContainer2/WorldBuilderButton.disabled = true
	
func close_new_prov_window() -> void:
	print("GUI: closing new prov window")
	$PopulationDebugToolPanel/HBoxContainer/VBoxContainer2/WorldBuilderButton.disabled = false
	$PopulationDebugToolPanel/HBoxContainer/VBoxContainer2/CreateProvinceButton.visible = false
	$PopulationDebugToolPanel/HBoxContainer/VBoxContainer2/ModifyProvinceButton.visible = false
