extends Node2D

var astar_grid: AStar2D

func create_astar_grid(provinces) -> void:
	print("GAME MAP / ASTAR NAV: generating grid...")
	var new_astar = AStar2D.new()
	#var point_id = 1
	var debug_line_count = 0
	for province in provinces: # good to replace with C++ too
		# this should create a point for each province, assigned an id corresponding to province id
		# simultaneously it goes through each adjacency and checks to see if the adjacent province 
		# exists, creates a connection if it does, otherwise it skips until that province is created
		# since ALL segments are bidirectional. Also checks that points aren't already connected
		new_astar.add_point(province.province_id, province.province_origin, 1) # default weight of 1 because astar is implemented silly. 
		print("Point id: ", province.province_id)
		#point_id += 1
		for adjacency in province.DEBUG_adjacencies:
			print(adjacency)
			#if new_astar.has_point(adjacency.adjacent.province_id) and not new_astar.are_points_connected(province.province_id, adjacency.adjacent.province_id):
				#print("can add adjacency betweeen", province.province_id, " and ", adjacency.adjacent.province_id)
				#new_astar.connect_points(province.province_id, adjacency.adjacent.province_id) 
				##print(" ", new_astar.are_points_connected(province.province_id, adjacency.adjacent))
				#var new_line = Line2D.new()
				#debug_line_count += 1
				#print("new line created; total: ", debug_line_count)
				#get_parent().control.add_child(new_line)
				#new_line.width = 0.5
				#new_line.add_point(province.province_origin)
				#new_line.add_point(adjacency.adjacent.province_origin)
			#else: 
				#print("unable to add adjacencies")
				#break
