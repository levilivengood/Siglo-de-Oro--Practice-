extends Resource
class_name Population_Class

@export var population_class_name: String
@export var population_class_needs: Array[Dictionary] # [{1:{need:resource, amount:x}, {...}}] # this should be based on type so it doesn't have to be assigned for every individual pop
#@export var population_class_default_growth_rate: float # 0.04 / per annum generally (THIS SHOULD BE PART OF INDIVIDUAL POP TYPES)
