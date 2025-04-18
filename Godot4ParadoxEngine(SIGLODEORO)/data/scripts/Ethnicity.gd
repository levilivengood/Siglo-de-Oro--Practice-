extends Resource
class_name Ethnicity

# populations have ethnicity. when they live together they can miscegenate and produce new 
# populations of new ethnicities which can be affected by different laws
# ideas for ethnicities:
# European
# Arab
# Egyptian
# Berber
# Mesopotamian
# Iranian
# Jewish
# Uralic
# Turk
# Mongol
# Chinese
# Korean
# Japanese
# Austronesian
# South East Asian
# Aryan
# Dravidian
# Melanesian
# Papuan
# Australian
# Abbysinian 
# Nilotic
# East African
# West African
# Central African
# South African
# Andean
# Mesoamerican 
# Caribbean
# North American
# South American

@export var ethnicity_name: String
@export var ethnicity_half_mix: Ethnicity # lost third
@export var ethnicity_quarters: Array[Ethnicity] # up to three; lost second
@export var ethnicity_eigths: Array[Ethnicity] # up to seven; lost first

signal creatingNewEthnicity(new_ethnicity)
