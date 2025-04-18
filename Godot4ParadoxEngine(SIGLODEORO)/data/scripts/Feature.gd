extends Resource
class_name Feature

@export var feature_name: String
@export var feature_desc: String
@export var feature_icon: ImageTexture
@export var feature_possible_terrains: Array[Terrain]
@export var feature_possible_temperatures: Array[Temperature]
@export var feature_possible_precipiration: Array[Precipitation]
@export var feature_natural_fresh_water: bool
@export var feature_must_be_coastal: bool
@export var feature_present: bool # used to show if the feature is present or latent (will grow with minimal development)
# features have resources that can be extracted on top of any in a province inherently
