extends Node2D
@export var in_dev: bool
var creating_provinces: bool
var modifying_provinces: bool
var accept_mouse_input_for_prov_search = true
#var london = preload("res://data/resources/provinces/1middlesex.tres")
#var essex = preload("res://data/resources/provinces/2essex.tres")
var engculture = preload("res://data/resources/cultures/EnglishCulture.tres")
var englang = preload("res://data/resources/languages/English.tres")
var european = preload("res://data/resources/ethnicities/European.tres")
var catholicism = preload("res://data/resources/religions/Catholicism.tres")
var farmer = preload("res://data/resources/population/Farmer.tres")
var population_unit = preload("res://data/scenes/population_unit.tscn")
var provinces = []
var languages: Array[Language]
#var possible_population_classes: Array[Population]  every possible population is in here to avoid duplication
var possible_ethnicities: Array[Ethnicity]
var province_interacted_with
# lists of provinces of all climates for sake of shaders
@onready var player = $Player
@onready var game_map = $GameMap
@onready var gui = $Player/Camera2D/GUI

signal developmentProvinceSelected(color) # world builder awaits this
signal developmentProvinceToMod(color)
signal developmentGotProvToMod(province:Province)

func _ready():
	player.position = Vector2(2700, 450)
	# will need to create a function for loading the province resources from their file
	# same goes for all resources
	#provinces.append(london)
	#provinces.append(essex)
	dir_contents_load_resource("res://data/resources/provinces/", provinces)
	for province in provinces:
		province.init_province(self, population_unit)
		province.provinceModified.connect(refresh_province_gui)
	player.seekingMapColor.connect(game_map.get_input_map_color)
	game_map.sendingMapColor.connect(get_province_from_map_color)
	gui.debugIncreasePopulation.connect(debug_increase_population)
	gui.debugDecreasePopulation.connect(debug_decrease_population)
	gui.debugTransferPopulation.connect(debug_transfer_population)
	gui.debugCreatingProvince.connect($SiglodeOroWorldBuilder.development_create_new_province) # when button for worldbuilder is pressed, create new is called and then awaits input from get color
	gui.debugModifyingProvince.connect(_development_look_for_mod_prov)
	gui.debugOpenWorldBuilder.connect($SiglodeOroWorldBuilder.development_initialize_world_builder)
	languages.append(englang)
	$GameMap.control = self
	$SiglodeOroWorldBuilder.control = self
	$GameMap/AStarNavigator.create_astar_grid(provinces)
	#var new_prov = provinces[0].generate_new_population(farmer, catholicism, engculture, european, languages)

# https://docs.godotengine.org/en/stable/classes/class_diraccess.html
func dir_contents_load_resource(path, resource_container):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
				var resource_path = path + file_name
				#print(path + file_name)
				var loaded_resource = load(resource_path)
				#print(loaded_resource)
				#resource_container.append()
				resource_container.append(loaded_resource)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _initialization_load_provinces() -> void:
	print("CONTROL: loading province files")
	#for file in province folder:
	
# GUI
func refresh_province_gui(province: Province) -> void:
	#print("CONTROL: debug got refresh prov")
	if gui.province_overview_open:
		gui.open_province_overview(province)	
	else: 
		pass
	
func debug_increase_population() -> void:
	#print("CONTROL: increasing population")
	if province_interacted_with:
		for population in province_interacted_with.province_population:
			province_interacted_with.increase_population(population, 1) # will need to update GUI too
			#print("province new pop = ", population.amount)

func debug_decrease_population() -> void:
	#print("CONTROL: decreasing population")
	if province_interacted_with:
		for population in province_interacted_with.province_population:
			province_interacted_with.remove_population(population, -1) # will need to update GUI too
			#print("province new pop = ", population.amount)
			
func debug_transfer_population() -> void:
	var other_prov: Province
	if province_interacted_with and province_interacted_with.province_population.size() > 0:
		#print("CONTROL: debug transfer pop")
		if province_interacted_with == provinces[0]:
			other_prov = provinces[1]
		else:
			other_prov = provinces[0]
		#print("CONTROL: debug transfer pop ", province_interacted_with.province_name, " to ", other_prov.province_name)
		province_interacted_with.transfer_population(other_prov, province_interacted_with.province_population[0], 20) # will not work if no pops in province
		#print("CONTROL: ", province_interacted_with.province_name, " ", province_interacted_with.province_population, "; ", other_prov.province_name, " ", other_prov.province_population)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _development_look_for_mod_prov() -> void:
	print("dev look for mod prov")
	modifying_provinces = true	
	var mod_prov = await(developmentGotProvToMod)
	$SiglodeOroWorldBuilder.development_modify_province(mod_prov)
	
func get_province_from_map_color(color:Color):
	#print("CONTROL: seeking province of color ", color)
	if accept_mouse_input_for_prov_search:
		if not creating_provinces and not modifying_provinces:
			for province in provinces: # consider turning into a C++ function
				#print(color, " = ", province.province_color)
				if str(color) == province.province_color:
					#print("CONTROL: match found: ", province.province_name)
					gui.open_province_overview(province)
					province_interacted_with = province
					return province
				else:
					print("CONTROL: no province found")
		else:
			for province in provinces: # C++
				if str(color) == province.province_color:
					print("province already exists")
					if $SiglodeOroWorldBuilder.setting_provinces_as_adjacent == true:
						print("control.getprovfrommapcol: click existing province")
						$SiglodeOroWorldBuilder.province_being_modified.add_adjacency(province)
						$SiglodeOroWorldBuilder.setting_provinces_as_adjacent = false
					developmentGotProvToMod.emit(province)
					return
			print("province uncreated...")
			developmentProvinceSelected.emit(str(color)) # world builder main create func awaits this
		
