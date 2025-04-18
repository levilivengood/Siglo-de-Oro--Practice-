extends CanvasLayer

# future version should just be like a character sheet. 

@export var climates: Array[Climate]
@export var terrains: Array[Terrain]
@export var features: Array[Feature]
@export var game_resources: Array[GameResource]
@export var population_classes: Array[Population_Class]
@export var religions: Array[Religion]
@export var cultures: Array[Culture]
@export var ethnicities: Array[Ethnicity]
@export var languages: Array[Language]
@export var provinces: Array[Province]

var prov_marker = preload("res://World Builder/WorldBuilderProvinceMarker.tscn")
var control
var mouse_for_origin = false
var new_prov_origin: Vector2
var prov_mark_inst
var prov_id: int
var prov_type
var fresh_water = false
var feature_present = false
var pops: Array[Dictionary]
var resources: Array[Dictionary] # holds resource dicts to export
var province_data: Array[Dictionary] # stores data of each province
#var selecting_resources = false

var setting_provinces_as_adjacent = false
var province_being_modified: Province

#signal yesNoWaterButton(result: bool)
signal originMousePressed(coord: Vector2) 


# development functions

func development_initialize_world_builder():
	print("init world builder")
	# load each province and store in province data

func development_create_new_province():
	_init_pop_dialogue()
	_init_secondary_chars_options()
	_init_resource_items()
	prov_id = control.provinces.size()+1 # hacky solution. will work so long as newly 
	control.creating_provinces = true
	$NewProvPanel.visible = true
	var new_prov = await(control.developmentProvinceSelected)
	prov_mark_inst = prov_marker.instantiate()
	control.add_child(prov_mark_inst)
	prov_mark_inst.position = control.get_global_mouse_position()
	control.accept_mouse_input_for_prov_search = false
	$NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/IDRichTextLabel.text = str("ID: ", prov_id)
	$NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/ColorRichTextLabel.text = str(new_prov)

func development_generate_new_province_resource():	
	var new_prov_resource = Province.new()
	var prov_name = $NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/NameTextEdit.text
	var prov_color = $NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/ColorRichTextLabel.text
	if prov_type == 0:
		var prov_climate = climates[$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/ClimateItemList.get_selected_items()[0]]
		var prov_terrain = terrains[$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/TerrainItemList.get_selected_items()[0]]
		var prov_feature = features[$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/FeatureItemList.get_selected_items()[0]]
		var prov_region = $NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/RegionTextEdit.text
		new_prov_resource.assign_land_province_resource_base_properties(prov_id, new_prov_origin, prov_name, prov_color, prov_climate, prov_terrain, prov_feature, fresh_water, prov_region, resources, pops)
	else: 
		new_prov_resource.assign_non_land_province_resource_base_properties(prov_id, new_prov_origin, prov_name, prov_color, prov_type)
	new_prov_resource.province_feature.feature_present = feature_present
	var new_prov_resource_path = str("res://data/resources/provinces/", prov_id, $NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/NameTextEdit.text, ".tres")
	control.provinces.append(new_prov_resource) #eventually will need a reference to it also all will need to be loaded from the folder so that the ID thing works. 
	ResourceSaver.save(new_prov_resource, new_prov_resource_path)

func development_generate_new_province_dictionary(): # doesn't work if feature not present
	var prov_name = $NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/NameTextEdit.text
	var prov_color = $NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/ColorRichTextLabel.text
	var new_province_dictionary: Dictionary
	if prov_type == 0:
		var prov_climate = climates[$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/ClimateItemList.get_selected_items()[0]].climate_name
		var prov_terrain = terrains[$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/TerrainItemList.get_selected_items()[0]].terrain_name
		var prov_feature = features[$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/FeatureItemList.get_selected_items()[0]].feature_name
		var prov_region = $NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/RegionTextEdit.text
		#if $NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/FeaturePresentCheckBox.pressed:
			#prov_feature.feature_present = false
		#else:
			#prov_feature.feature_present = true
		new_province_dictionary = {
			"province_id": prov_id,
			"province_name": prov_name,
			"province_color": prov_color,
			"province_type": prov_type,
			"province_climate": prov_climate,
			"province_terrain": prov_terrain,
			"province_feature": prov_feature,
			"province_natural_fresh_water": prov_climate,
			"province_region": prov_region,
			"province_resources": resources,
			"province_population": pops
		}
	else: 
		new_province_dictionary = {
			"province_id": prov_id,
			"province_name": prov_name,
			"province_color": prov_color,
			"province_type": prov_type
		}
	print("new prov dict, ", new_province_dictionary)
	
func development_modify_province(province: Province):
	print("mod prov")
	province_being_modified = province
	$ModifyProvincePanel.visible = true
	$ModifyProvincePanel/ModifyProvinceHBoxContainer/ModifyProvinceVBoxContainer/NameModifyProvinceRichTextLabel.text = province.province_name
	$ModifyProvincePanel/ModifyProvinceHBoxContainer/ModifyProvinceVBoxContainer/RegionModifyProvinceRichTextLabel.text = province.province_region
	$ModifyProvincePanel/ModifyProvinceHBoxContainer/ModifyProvinceVBoxContainer/ColorModifyProvinceRichTextLabel.text = province.province_color
	for p_adj in province.DEBUG_adjacencies:
		$ModifyProvincePanel/ModifyProvinceHBoxContainer/ModifyProvinceVBoxContainer2/ModifyProvinceAdjacenciesItemList.add_item(str(p_adj))
	for pop in province.province_population:
		$ModifyProvincePanel/ModifyProvinceHBoxContainer/ModifyProvinceVBoxContainer2/ModifyProvincePopsItemList.add_item(str(pop.type.population_class_name))
	# allows to change anything about a province, but used in particular to add adjacencies once 
	# multiple provinces have been made

func _init_resource_items():
	for resource in game_resources:
		#print("res: ", resource.resource_name)
		$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceItemList.add_item(resource.game_resource_name)

func _unhandled_input(event):
	if event is InputEventMouseButton and mouse_for_origin:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				originMousePressed.emit(control.get_global_mouse_position())
	
#func _activate_create_population_panel() -> void:
	#print("act")
	
func _on_get_origin_button_pressed():
	mouse_for_origin = true
	new_prov_origin = await(originMousePressed)
	$NewProvPanel/HBoxContainer/BasicPropertiesVBoxContainer/OriginRichTextLabel.text = str(new_prov_origin)
	prov_mark_inst.position = new_prov_origin

func _init_secondary_chars_options():
	for climate in climates:
		$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/ClimateItemList.add_item(climate.climate_name)
	for terrain in terrains:
		$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/TerrainItemList.add_item(terrain.terrain_name)
	for feature in features:
		$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer/FeatureItemList.add_item(feature.feature_name)

func _on_prov_type_item_list_item_activated(index):
	prov_type = index
	if index == 0:	
		$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer.visible = true
		$NewProvPanel/HBoxContainer/TertiaryPropertiesVBoxContainer.visible = true
		# store index too
	else:
		$NewProvPanel/HBoxContainer/SecondaryPropertiesVBoxContainer.visible = false
		$NewProvPanel/HBoxContainer/TertiaryPropertiesVBoxContainer.visible = false
		print("generate prov with respective index")


func _on_generate_button_pressed():
	# must test to see all data entered is correct
	development_generate_new_province_dictionary() 
	development_generate_new_province_resource()
	print("closing window")
	control.creating_provinces = false
	control.accept_mouse_input_for_prov_search = false
	$NewProvPanel.visible = false
	control.gui.close_new_prov_window()
	prov_mark_inst.queue_free()
		
func _init_pop_dialogue():
	for pop_class in population_classes:
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopClassItemList.add_item(pop_class.population_class_name)
	for religion in religions:
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopReligionItemList.add_item(religion.religion_name)
	for culture in cultures:
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopCultureItemList.add_item(culture.culture_name)
	for ethnicity in ethnicities:
		$CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopEthnicityItemList.add_item(ethnicity.ethnicity_name)
	for language in languages:
		$CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopLanguagesItemList.add_item(language.language_name)
		
func _on_new_pop_button_pressed():
	if $CreatePopulationPanel.visible == true:
		$CreatePopulationPanel.visible = false
	else:
		$CreatePopulationPanel.visible = true

func _on_pop_complete_button_pressed(): # will have to work on this
	if $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopClassItemList.get_selected_items().size() < 1:
		print("WTF!!!")
		return
	var selected_class_index = $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopClassItemList.get_selected_items()[0]
	var selected_class = population_classes[selected_class_index].population_class_name
	if $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopReligionItemList.get_selected_items().size() < 1:
		print("WTF!!!")
		return
	var selected_religion_index = $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopReligionItemList.get_selected_items()[0]
	var selected_religion = religions[selected_religion_index].religion_name
	if $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopCultureItemList.get_selected_items().size() < 1:
		print("WTF!!!")
		return
	var selected_culture_index = $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopCultureItemList.get_selected_items()[0]
	var selected_culture = cultures[selected_culture_index].culture_name
	if $CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopEthnicityItemList.get_selected_items().size() < 1:
		print("WTF!!!")
		return
	var selected_ethnicity_index = $CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopEthnicityItemList.get_selected_items()[0]
	var selected_ethnicity = ethnicities[selected_ethnicity_index].ethnicity_name
	if $CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopLanguagesItemList.get_selected_items().size() < 1:
		print("WTF!!!")
		return
	var selected_languages_indices = $CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopLanguagesItemList.get_selected_items()
	var selected_languages: Array[String]
	for language in selected_languages_indices:
		selected_languages.append(languages[language].language_name)
	var pop_amount_text = $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopAmountTextEdit.text
	if not pop_amount_text.is_valid_int() or pop_amount_text.to_int() < 0:
		print("pop amount must be positive int")
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopAmountTextEdit.clear()
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopAmountTextEdit.placeholder_text = "Population amount must be a positive integer"
		return
	var pop_ortho_text = $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopOrthodoxyTextEdit2.text
	if not pop_ortho_text.is_valid_int() or pop_ortho_text.to_int() < 0:
		print("ortho amount must be positive int")
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopOrthodoxyTextEdit2.clear()
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopOrthodoxyTextEdit2.placeholder_text = "Population orthodoxy must be a positive integer smaller than the population amount"
		return
	var pop_zeal_text = $CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopZealTextEdit3.text
	if not pop_zeal_text.is_valid_int() or pop_zeal_text.to_int() < 0:
		print("zeal amount must be positive int")
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopZealTextEdit3.clear()
		$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopZealTextEdit3.placeholder_text = "Population zeal must be a positive integer smaller than the population amount"
		return
	var pop_unrest_text = $CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopUnrestTextEdit2.text
	if not pop_unrest_text.is_valid_int() or pop_unrest_text.to_int() < 0:
		print("unrest amount must be positive int")
		$CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopUnrestTextEdit2.clear()
		$CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopUnrestTextEdit2.placeholder_text = "Population unrest must be a positive integer smaller than the population amount"
		return
	var pop_literate_text = $CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopLiterateTextEdit3.text
	if not pop_literate_text.is_valid_int() or pop_literate_text.to_int() < 0:
		print("literate amount must be positive int")
		$CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopLiterateTextEdit3.clear()
		$CreatePopulationPanel/PopHBoxContainer/PopVBoxContainer2/PopLiterateTextEdit3.placeholder_text = "Population literate must be a positive integer smaller than the population amount"
		return
	var affected_pops = [pop_ortho_text.to_int(), pop_unrest_text.to_int(), pop_zeal_text.to_int(), pop_literate_text.to_int()]
	for pop in affected_pops:
		print(pop)
		if pop > pop_amount_text.to_int():
			print("amount too small")
			$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopAmountTextEdit.clear()
			$CreatePopulationPanel/PopHBoxContainer/CreatePopulationVBoxContainer/PopAmountTextEdit.placeholder_text = str("Population amount must be larger than orthodoxy, zeal, unrest, and literate altogether. Must be larger than, ", pop)
			return
	var pop_dict = {
		"type": selected_class,
		"religion": selected_religion,
		"culture": selected_culture,
		"ethnicity": selected_ethnicity,
		"languages": selected_languages,
		"orthodoxy": pop_ortho_text,
		"zeal": pop_zeal_text,
		"unrest": pop_unrest_text,
		"amount": pop_amount_text,
		"literate": pop_literate_text
	}
	var pop_tool_tip: String
	for key in pop_dict:
		pop_tool_tip += str("(", pop_dict[key], "), ")
	pops.append(pop_dict)
	$NewProvPanel/HBoxContainer/TertiaryPropertiesVBoxContainer/PopsItemList.add_item(pop_dict.type)
	$NewProvPanel/HBoxContainer/TertiaryPropertiesVBoxContainer/PopsItemList.set_item_tooltip(-1, pop_tool_tip)
	print(pops)


func _on_new_resource_button_pressed():
	if $ResourceAmountPopUpPanel.visible == true:
		$ResourceAmountPopUpPanel.visible = false
	else:
		$ResourceAmountPopUpPanel.visible = true


func _on_resource_amount_pop_up_button_pressed() -> void:
	if  $ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceItemList.get_selected_items().size() > 0:
		var selected_resource_index = $ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceItemList.get_selected_items()[0]
		var selected_resource = game_resources[selected_resource_index]
		var selected_resource_amount = $ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.text
		if $ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceItemList.is_item_selectable(selected_resource_index):
			if selected_resource_amount.is_valid_int():
				if int(selected_resource_amount) > 0:
					#print(selected_resource)
					var new_res_dict = {
						"type":selected_resource.game_resource_name,
						"amount": selected_resource_amount
					}
					var new_res_dict_string = str(new_res_dict.type, ": ", new_res_dict.amount)
					$NewProvPanel/HBoxContainer/TertiaryPropertiesVBoxContainer/ResourcesItemList.add_item(new_res_dict_string)
					resources.append(new_res_dict)
					#print(resources)
					$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.clear()
					$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.placeholder_text = "Amount"
					$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceItemList.set_item_disabled(selected_resource_index, true)
					$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceItemList.deselect_all()
				else:
					print("Resource amount too small, must be larger than 0")
					$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.clear()
					$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.placeholder_text = "Set an integer greater than zero"
			else:
				$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.clear()
				$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.placeholder_text = "Set an integer greater than zero"
				print("Resource amount invalid, set to a positive integer")
		else:
			print("Resource not selectable")
			$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.clear()
			$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.placeholder_text = "Resource not selectable"
	else:
		print("wtf")
		$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.clear()
		$ResourceAmountPopUpPanel/ResourceAmountPopUpHBoxContainer/ResourceAmountPopUpTextEdit.placeholder_text = "Amount"


func _on_fresh_water_check_box_toggled(toggled_on):
	if fresh_water == false:
		fresh_water = true
	else:
		fresh_water = false


func _on_feature_present_check_box_toggled(toggled_on):
	if feature_present == false:
		feature_present = true
	else:
		feature_present = false


func _on_modify_province_adjacencies_button_pressed():
	print("click a province to make adjacent")
	setting_provinces_as_adjacent = true
	# opens separate window to allow putting in ID or perhaps it allows for clicking directly on the map
