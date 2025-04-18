extends Resource
class_name Language

# language is mostly relevant for merchants, but also gatekeeps migration and leads to certain 
# effects regarding linguistic minorities
# also accounts for intra-linguistic diversity and (close) language families
# Ideas:
# English
# French
# Irish
# Welsh
# Cornish
# Manx
# Breton
# German
# Polish
# Czech (includes moravian?)
# Shtokavian (serbian, etc)
# Bulgarian
# Greek
# Turkish



@export var language_name: String
@export var language_relatives: Array[Language]
@export var language_standardization: int
