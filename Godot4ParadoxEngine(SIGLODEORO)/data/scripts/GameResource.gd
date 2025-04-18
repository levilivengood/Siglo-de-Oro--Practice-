extends Resource
class_name GameResource

@export var game_resource_name: String
@export var game_resource_desc: String
@export var game_resource_icon: ImageTexture
@export var game_resource_amount: int # how much can be extracted THIS MAKES MORE SENSE AT THE 
# PROVINCE LEVEL, PERHAPS LIKE: province has a primary resource, which can be assigned the resource
# resource, then it has a separate var for primary amount
@export var game_resource_life: int # how long the resource can survive before expiring
# will have raw and refined goods
