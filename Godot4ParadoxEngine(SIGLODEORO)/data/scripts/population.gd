extends Resource
class_name Population

# think the best thing to do would be to turn these just into dictionaries instead of having entire 
# resources for each one. makes saving and loading far easier etc
@export var population_type: Population_Class
@export var population_unrest: int # number of "instances" with unrest. 
@export var population_orthodoxy: int # number of "instances" orthodox. 
@export var population_zeal: int # number of "instances" with zeal. 
@export var population_ethnicity: Ethnicity # how to deal with miscegenation?
@export var population_culture: Culture
@export var population_languages: Array[Language]
@export var population_literate: int
@export var population_religion: Religion # in some cases a population can practice multiple religions (they are non-exclusive or syncretic)
@export var population_amount: int
@export var population_default_growth_rate: float # 0.04 / per annum generally

