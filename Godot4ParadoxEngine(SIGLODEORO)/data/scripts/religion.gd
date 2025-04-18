extends Resource
class_name Religion

@export var religion_name: String
@export var religion_icon: ImageTexture
@export var religion_exclusive: bool
@export var religions_syncretized: Array[Religion] # syncretized religions work this way. A pop has a main religion, and it is syncretized with some number of others. (THIS WON'T WORK?)
