extends Resource
class_name Province

# province resources are generated based on first the init files then save game if they have been 
# modified. 
# how to handle memory:
# population units should be instantiated ONLY when being modified. Otherwise they are stored as 
# dictionaries. When instantiated, the dictionary reference is deleted / replaced once the 
# population unit has finished and the unit is deleted. 



@export var province_id: int
@export var province_origin: Vector2
@export var province_name: String  
@export var province_color: String # because the editor hates colors we need to do this crap
@export var province_adjacencies: Array[Dictionary] # [{"0":{"adjacent": ID, "cost": INT, "river":bool}, "1":{...}}]
@export_enum("Land", "Lake", "Sea", "Impassible") var province_type: int 
@export var province_climate: Climate # weather
@export var province_terrain: Terrain # material
@export var province_feature: Feature # things like forests
@export var province_natural_fresh_water: bool # true if has a freshwater lake or is on a river, but not if irrigated
@export var province_resources: Array[Dictionary] # [{"type":x,"amount":x},...]
@export var province_region: String
@export var province_population_resources: Array[Population] # replace with dict references
@export var province_population_data: Array[Dictionary]
@export var DEBUG_adjacencies: Array[Dictionary]

func assign_land_province_resource_base_properties(new_id: int, new_origin: Vector2, new_name: String, new_color: String, new_climate: Climate, new_terrain: Terrain, new_feature: Feature, new_nat_water: bool, new_region: String, new_resources: Array[Dictionary], new_population: Array[Dictionary]) -> void:
	province_id = new_id
	province_origin = new_origin
	province_name = new_name
	province_color = new_color
	province_type = 0
	province_climate = new_climate
	province_terrain = new_terrain
	province_feature = new_feature
	province_region = new_region
	province_natural_fresh_water = new_nat_water
	province_resources = new_resources
	province_population_data = new_population

func assign_non_land_province_resource_base_properties(new_id: int, new_origin: Vector2, new_name: String, new_color: String, new_type: int) -> void:
	province_id = new_id
	province_origin = new_origin
	province_name = new_name
	province_color = new_color
	province_type = new_type

# not sure exactly how I want to handle these. I don't think I want to save a reference for every 
# single pop in the game. It makes more sense to group them within their provinces when saving. 
# some of these only exist to make it possible to access information via the province itself
# var possible_population_classes: Array[Population] # reference to common list in GameControl; must compare abstracted versions w/o unrest etc
var province_population: Array # holds population_units
var province_cities = [] # how will we handle cities? some will still exist, others will come about through events, but some should be dynamic? how will they get names?
var province_claims = [] 
var province_owners = [] 
var province_occupier
var province_units = []
var province_buildings = []
var province_building_cap: int # based on natural features
var province_unrest: int # based on unrest of population. once it reaches a certain point, revolt.
var control
var population_object
# var former_populations: Array[Population]  stores any abstract population that has been removed so it can be recovered and not duplicated (seems unwieldy)
# necessary functions: (h) = private, helper functions
#	-transfer population / (h)receive population
#	-grow population / shrink population (called as population grows or declines from negative growth rate)
#	-split population (called as a consequence of moving or change in essential characteristic) (if a new population class is created this way, it is save to the GameControl list)
#	-merge population (only called if a population splits, if a population moves, or an essential characteristic has changed)
#	-affect population growth rate (called when dealing with resources, needs, war, etc)
#	-increase/decrease population unrest/orthodoxy/zeal 
#	-change population religion
#	-change population culture
#	-change population language
#	-(h)remove population (amount or wholesale)
#	-generate new population class 
#	-(h)send data to GameControl
#	-update province
#	-(h)distribute resources
#	-(h)handle trade
#	-(h)handle tax

signal provinceModified(province) # sent out for GUI to update

func add_adjacency(province) -> void:
	# will change; also is that "adjacent" the right spelling of the key??
	# might have to just store the prov and not just the id
	self.DEBUG_adjacencies.append({"adjacent":province})
	print({"adjacent":province})
	ResourceSaver.save(self, "res://data/resources/provinces/" + str(province_id) + province_name + ".tres")
	#for adj in province.DEBUG_adjacencies:
		#if adj.adjacent == province:
			#break
		#else:
			#pass	
	if {"adjacent":self} in province.DEBUG_adjacencies:
		pass
	else:
		print({"adjacent":self})
		province.DEBUG_adjacencies.append({"adjacent":self})
		ResourceSaver.save(province, "res://data/resources/provinces/" + str(province.province_id) + province.province_name + ".tres")
	

func merge_population(population, merge_target) -> void:
	# called during transfer of population by receiving province
	merge_target.amount += population.amount
	merge_target.unrest += population.unrest
	merge_target.orthodoxy += population.orthodoxy
	merge_target.zeal += population.zeal
	merge_target.literate += population.literate
	#population.delete_population()
	provinceModified.emit(self)
	
func remove_population(population, famount: int) -> void:
	# must take a negative int
	#print("PROVINCE: removing population")
	if famount + population.amount <= 0:
		population.delete_population()
		province_population.erase(population) # already doing this? maybe the signal unnecessary
		provinceModified.emit(self)
	else:
		population.affect_population(famount)

func increase_population(population, famount: int) -> void:
	#print("PROVINCE: increasing population")
	population.affect_population(famount)
	
	
func generate_new_population(type: Population_Class, religion: Religion, culture: Culture, ethnicity: Ethnicity, languages: Array[Language]):
	# creates a new instance of population. used for splitting or essential changes
	# will need to add child? or will storing in province resource work?
	var new_pop = population_object.instantiate()
	new_pop.assign_essential_properties(type, religion, culture, ethnicity, languages)
	control.add_child(new_pop)
	#print("PROVINCE: gen new pop, ", new_pop.type.population_class_name, " ", new_pop.religion.religion_name, " ", new_pop.culture.culture_name, " ", new_pop.ethnicity.ethnicity_name, " ", new_pop.languages[0].language_name)	
	return new_pop
	
func generate_population_from_resource(resource: Population): # replace with from dict function
	# provinces are assigned populations via editor as resources. at runtime these are converted into objects. 
	var new_pop = generate_new_population(resource.population_type, resource.population_religion, resource.population_culture, resource.population_ethnicity, resource.population_languages)
	new_pop.assign_accidental_properties(resource.population_orthodoxy, resource.population_zeal, resource.population_unrest, resource.population_amount, resource.population_literate)
	control.add_child(new_pop)
	#print("PROVINCE: gen pop from res, ", new_pop.type.population_class_name, " ", new_pop.religion.religion_name, " ", new_pop.culture.culture_name, " ", new_pop.ethnicity.ethnicity_name, " ", new_pop.languages[0].language_name)	
	return new_pop
	
func _generate_population_from_dict(pop: Dictionary, index: int):
	# {
	#"type":, 
	#"religion":, 
	#"culture":, 
	#"ethnicity":, 
	#"languages":, 
	#"orthodoxy":, 
	#"zeal":, 
	#"unrest":, 
	#"amount":, 
	#"literate":
	#}
	print("p")
	var new_pop = generate_new_population(pop.type, pop.religion, pop.culture, pop.ethnicity, pop.languages)
	new_pop.assign_accidental_properties(pop.orthodoxy, pop.zeal, pop.unrest, pop.amount, pop.literate)
	new_pop.population_index = index
	control.add_child(new_pop)
	#print("PROVINCE: gen pop from res, ", new_pop.type.population_class_name, " ", new_pop.religion.religion_name, " ", new_pop.culture.culture_name, " ", new_pop.ethnicity.ethnicity_name, " ", new_pop.languages[0].language_name)	
	return new_pop

func _return_population_to_dict(pop)->void: # this is not the correct format
	var pop_to_dict = {
		"type":pop.population_type,
		"religion":pop.population_religion,
		"culture": pop.population_culture,
		"ethnicity": pop.population_ethnicity,
		"languages": pop.population_languages,
		"orthodoxy": pop.population_orthodoxy,
		"zeal": pop.population_zeal,
		"unrest": pop.population_unrest,
		"amount": pop.populatiton_amount,
		"literate": pop.population_literate
	}
	province_population_data[pop.population_index] = pop_to_dict
	pop.delete_population()
	
func transfer_population(destination_province: Province, population, famount:int):
	# transfers a certain amount of a specific population to a certain province
	# how it works:
	#	-function takes the destination province, a source population, and an amount of the source population
	#	-generates a new pop based on the param pop's essential characteristics.
	#	-check if there is population in dest prov
	#	-check if famount is larger than actual amount, set former to latter if the case
	#	-accidental properties are assigned proportionally:
	#		-ratio of source pop property to source pop total amount
	#		-this is multiplied with the famount to get amount of respective property to transfer
	#	-source population has these assigned properties subtracted 
	#	-transfered pop's province is changed, its amount is set to famount, 
	#	-target prov receives new pop and its amount is subtracted from the source population's
	#print("PROVINCE: transfering population")
	
	# idea: split based on "chance"
	# i.e.: a(100/50)->b(30/10), moving 20; 50% chance to move one, but we are moving 20, so 10 will have unrest, 10 will not
	# if b->a, 1/3 chance. moving 20 so 7 unrest rest; if it were 2 being moved, 2/3 = .6 so 1 will be moved (round up always)
	# dang it straight up works perfectly... It's less chance and more proportion. 
	if population.amount <= 0:
		print("PROVINCE: unable to transfer population; too small")	
	else:
		var new_population = generate_new_population(population.type, population.religion, population.culture, population.ethnicity, population.languages)
		if population.amount < famount:
			#print("PROVINCE: transfer pop: amount to transfer is larger than in province. will set famount to province amount")
			famount = population.amount
		var transfered_population = _assign_accidental_properties(population, new_population, famount)
		#print(transfered_population.orthodoxy, transfered_population.zeal, transfered_population.unrest, transfered_population.literate)
		population.orthodoxy -= transfered_population.orthodoxy
		population.zeal -= transfered_population.zeal
		population.unrest -= transfered_population.unrest
		population.literate -= transfered_population.literate
		transfered_population.change_province(destination_province)
		transfered_population.amount = famount
		destination_province.receive_population(transfered_population)
		remove_population(population, -famount)

func _assign_accidental_properties(og_pop, new_pop, famount:int):
	#print("PROVINCE: assign acc")
	if og_pop.zeal > 0:
		new_pop.zeal = _get_accidental_property_amount(float(og_pop.zeal)/og_pop.amount, famount)
	#else:
		#print("zeal less than 0")
	if og_pop.orthodoxy > 0:
		new_pop.orthodoxy = _get_accidental_property_amount(float(og_pop.orthodoxy)/og_pop.amount, famount)
	if og_pop.unrest > 0:
		new_pop.unrest = _get_accidental_property_amount(float(og_pop.unrest)/og_pop.amount, famount)
	if og_pop.literate > 0:
		new_pop.literate = _get_accidental_property_amount(float(og_pop.literate)/og_pop.amount, famount)
	return new_pop
	
func _get_accidental_property_amount(property_ratio:float, famount:int) -> int:
	#print("PROVINCE: getting accidental property amount... famount: ", famount, " property_ratio: ", property_ratio)
	return roundi(famount * property_ratio)
	
func receive_population(population) -> void:
	# called by transfer population in target province
	var merge_test = _does_this_pop_exist_placeholder_function(population)
	#print("PROVINCE: merge test is ", merge_test)
	if not merge_test:
		province_population.append(population)
	else: 
		merge_population(merge_test[0], merge_test[1]) 

func calculate_growth_rate(population):
	print("PROVINCE: calculating growth rate")		
	provinceModified.emit(self)

func _does_this_pop_exist_placeholder_function(population):
	# replace with C++ module
	var pop_pair = []
	for comppop in province_population:
		if _compare_abstract_populations(population, comppop):
			pop_pair.append(population)
			pop_pair.append(comppop)
			return pop_pair
	return false
		
func _compare_abstract_populations(population1, population2:) -> bool:
	# make this prettier
	if population1.religion == population2.religion:
		#print("PROVINCE: compare prov relig same")
		if population1.culture == population2.culture:
			#print("PROVINCE: compare prov culture same")
			if population1.ethnicity == population2.ethnicity:
				#print("PROVINCE: compare prov ethnic same")
				if population1.type == population2.type:
					#print("PROVINCE: compare prov type same")
					if population1.languages == population2.languages:
						#print("PROVINCE: compare prov lang same")
						# then these two pops can be grouped together (share amount)
						return true
					else: 
						return false
				else: 
					return false
			else: 
				return false
		else: 
			return false
	else: 
		return false

func emit_signal_to_refresh_gui():
	provinceModified.emit(self)		
		
func init_province(new_parent, popob) -> void:
	control = new_parent
	population_object = popob
	for population in province_population_resources: # should only be done when necessary
		var new_pop = generate_population_from_resource(population)
		province_population.append(new_pop)
		new_pop.population_province = self
		new_pop.populationModified.connect(emit_signal_to_refresh_gui)
	province_population_resources.clear()
	#print("PROVINCE: debug prop res: ", province_population_resources)
		#population.populationDeleted.connect(save_former_population)
