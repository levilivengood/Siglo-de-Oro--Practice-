extends Node2D

# essential properties
@export var type: Population_Class
@export var religion: Religion
@export var culture: Culture
@export var ethnicity: Ethnicity
@export var languages: Array[Language]
# accidental properties
@export var orthodoxy: int
@export var zeal: int
@export var unrest: int
@export var amount: int
@export var literate: int

var population_index: int
var population_province: Province
var population_default_growth_rate: float

signal populationDeleted(population) # connected per province
signal populationModified # connected per province, picked up by control for GUI purposes

func assign_essential_properties(atype: Population_Class, areligion: Religion, aculture: Culture, aethnicity: Ethnicity, alanguages: Array[Language]):
	type = atype
	religion = areligion
	culture = aculture
	ethnicity = aethnicity
	languages = alanguages
	
func assign_accidental_properties(aorthodoxy: int, azeal: int, aunrest: int, aamount: int, aliterate: int):
	orthodoxy = aorthodoxy
	zeal = azeal
	unrest = aunrest
	amount = aamount
	literate = aliterate

# essential functions

# particular functions (MAY BE SUPERFLUOUS)
func modify_amount(mamount:int):
	amount += mamount
	
func modify_orthodoxy(mamount:int):
	orthodoxy += mamount

func modify_zeal(mamount:int):
	zeal += mamount
	
func modify_unrest(mamount:int):
	unrest += mamount
	
func modify_literate(mamount:int):
	literate += mamount
	
# other 
func delete_population() -> void:
	populationDeleted.emit(self) # sent to province to remove from list
	#print("Population: ", self, " has been deleted")
	queue_free()
#	self.free() problem is whether this will delete local resource or global resource
	
func affect_population(target_amount: int) -> void:
	# population shrinks or grows by a whole number (never falling to zero in this case)
	amount += target_amount
	populationModified.emit()
	
func change_province(province: Province) -> void:
	population_province = province
	populationModified.emit()
