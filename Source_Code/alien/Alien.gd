extends "res://agent/Agent.gd"

signal crystal_collected
signal crystal_dropped_off

# AI state Constants
const exploring_choose_destination : int = 0
const exploring_moving_to_destination : int = 1
const exploring_arrived_at_destination : int = 2
const picking_up_crystal_choose_destination : int = 3
const picking_up_crystal_moving_to_destination : int = 4
const picking_up_crystal_arrived_at_destination : int = 5
const dropping_off_crystal_choose_destination : int = 6
const dropping_off_crystal_moving_to_destination : int = 7
const dropping_off_crystal_arrived_at_destination : int = 8

var current_ai_state : int = exploring_choose_destination
var previous_ai_state : int = -1
var carrying_crystal : bool = false
var current_destination : Vector2
var previous_destination : Vector2
var previous_position : Vector2
var collection_target : Vector2
var previous_pixel_position : Vector2
var distance_moved : float = 0.0
var current_communication_target : KinematicBody2D = null
var time_idling : float = 0.0

var dropoff_locations : = PoolVector2Array() #setget dropoff_locations_set, dropoff_locations_get
var brute_force_locations : = PoolVector2Array() #setget brute_force_locations_set, brute_force_locations_get
var crystal_locations : = PoolVector2Array() #setget crystal_locations_set, crystal_locations_get
var crystal_location_blacklist : = PoolVector2Array() #setget crystal_location_blacklist_set, crystal_location_blacklist_get
var movement_location_blacklist : = PoolVector2Array() #setget movement_location_blacklist_set, movement_location_blacklist_get
var movement_location_yellowlist : = PoolVector2Array() #setget movement_location_yellowlist_set, movement_location_yellowlist_get

func init_alien(ID : int, camera : Position2D, tile_map : TileMap, line_2d : Line2D, dropoff_locations : PoolVector2Array) -> void:
	init_agent(camera, tile_map, line_2d)
	self.crystal_locations = []
	self.crystal_location_blacklist = []
	self.collection_target = Vector2(-1, -1)
	self.movement_location_blacklist = []
	self.movement_location_blacklist += dropoff_locations
	self.brute_force_locations = []
	self.dropoff_locations = dropoff_locations
	self.ID = ID
	self.current_ai_state = exploring_choose_destination
	var id_counter : int = 0
	for j in range(0, GlobalValues.map_bounds.y):
		for i in range(0, GlobalValues.map_bounds.x):
			if id_counter == self.ID and self.tile_map.get_cell(i, j) >= GlobalValues.walk_tile_first:
				self.brute_force_locations.append(Vector2(i, j))
			id_counter += 1
			if id_counter > GlobalValues.num_aliens - 1:
				id_counter = 0
	if self.ID % 2 == 0:
		self.brute_force_locations.invert()

func _physics_process(delta : float) -> void:
	run_ai(delta)

func run_ai(delta: float) -> void:
	# Get the current Agent location
	self.current_position = self.tile_map.get_map_loc_from_pos(self.global_position.x, self.global_position.y)

	# Choose the current state in the AI FSM
	match self.current_ai_state:
		exploring_choose_destination:
			self.state_color = Color.green
			if GlobalValues.brute_force == true:
				var found_dest : bool = false
				for i in range(0, self.brute_force_locations.size()):
					self.current_destination = self.brute_force_locations[i]
					self.brute_force_locations.remove(i)
					self.brute_force_locations.append(self.current_destination)
					if set_destination(int(self.current_destination.x), int(self.current_destination.y)) == 1:
						print("#### BRUTE FORCE EXPLORING ERROR: exploring_choose_destination BAD DESTINATION: ", self.current_destination)
					else:
						self.previous_ai_state = self.current_ai_state
						self.current_ai_state = exploring_moving_to_destination
						found_dest = true
						print("#### BRUTE FORCE EXPLORING: exploring_choose_destination - Agent: ", self.ID, " is now in state ", self.current_ai_state, " and is moving to a BRUTE FORCE LOCATION at: ", self.current_destination)
						Logger.info("#### BRUTE FORCE EXPLORING: exploring_choose_destination - Agent: " + str(self.ID) + " is now in state " + str(self.current_ai_state) + " and is moving to a BRUTE FORCE LOCATION at: " + str(self.current_destination))
						break
				if found_dest == false:
					GlobalValues.brute_force = false
					self.previous_ai_state = self.current_ai_state
					self.current_ai_state = exploring_choose_destination
			else:
				_set_new_random_end_point()
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = exploring_moving_to_destination
				print("#### EXPLORING: exploring_choose_destination - Agent: ", self.ID, " is now in state ", self.current_ai_state, " and is moving to EXPLORE at: ", self.current_destination, " its crystal_locations list is: ", self.crystal_locations)
				Logger.info("#### EXPLORING: exploring_choose_destination - Agent: " + str(self.ID) + " is now in state " + str(self.current_ai_state) + " and is moving to EXPLORE at: " + str(self.current_destination) + " its crystal_locations list is: " + str(self.crystal_locations))
		exploring_moving_to_destination:
			move_along_path()
			if self.current_position == self.current_destination and self.crystal_locations.size() == 0: 
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = exploring_arrived_at_destination
			elif self.crystal_locations.size() > 0 and self.carrying_crystal == false:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = picking_up_crystal_choose_destination
			elif self.carrying_crystal == true: # Brute Force, No Detection
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = dropping_off_crystal_choose_destination
		exploring_arrived_at_destination:
			self.previous_ai_state = self.current_ai_state
			self.current_ai_state = exploring_choose_destination
		picking_up_crystal_choose_destination:
			self.state_color = Color.yellow
			var found_crystal : bool = false
			var remove_locs := PoolVector2Array()
			for i in range(0, self.crystal_locations.size()):
				self.current_destination = self.crystal_locations[i]
				if self.collection_target != self.current_destination:
					self.collection_target = self.current_destination
				remove_locs.append(self.current_destination)
				if set_destination(int(self.current_destination.x), int(self.current_destination.y)) == 1:
					print("#### PICKING UP ERROR: picking_up_crystal_choose_destination BAD DESTINATION: ", self.current_destination)
				else:
					self.previous_ai_state = self.current_ai_state
					self.current_ai_state = picking_up_crystal_moving_to_destination
					found_crystal = true
					print("#### PICKING UP: picking_up_crystal_choose_destination - Agent: ", self.ID, " is now in state ", self.current_ai_state, " and is moving to COLLECT a crystal at: ", self.current_destination, " its crystal_locations list is: ", self.crystal_locations)
					Logger.info("#### PICKING UP: picking_up_crystal_choose_destination - Agent: " + str(self.ID) + " is now in state " + str(self.current_ai_state) + " and is moving to COLLECT a crystal at: " + str(self.current_destination) + " its crystal_locations list is: " + str(self.crystal_locations))
					break
			for location in remove_locs:
				_remove_crystal_from_locations(location)
			if found_crystal == false:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = exploring_choose_destination
		picking_up_crystal_moving_to_destination:
			move_along_path()
			if self.current_position == self.current_destination: 
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = picking_up_crystal_arrived_at_destination
			elif self.carrying_crystal == true and self.current_position != self.current_destination:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = dropping_off_crystal_choose_destination
		picking_up_crystal_arrived_at_destination:
			if self.carrying_crystal == true:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = dropping_off_crystal_choose_destination
			elif self.carrying_crystal == false and self.crystal_locations.size() > 0:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = picking_up_crystal_choose_destination
			else:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = exploring_choose_destination
		dropping_off_crystal_choose_destination:
			self.state_color = Color.red
			var found_dropoff : bool = false
			for i in range(0, self.dropoff_locations.size()):
				self.current_destination = self.dropoff_locations[i]
				if set_destination(int(self.current_destination.x), int(self.current_destination.y)) == 1:
					print("#### DROPPING OFF ERROR: dropping_off_crystal_choose_destination BAD DESTINATION: ", self.current_destination)
				else:
					self.previous_ai_state = self.current_ai_state
					self.current_ai_state = dropping_off_crystal_moving_to_destination
					found_dropoff = true
					print("#### DROPPING OFF: dropping_off_crystal_choose_destination - Agent: ", self.ID, " is now in state ", self.current_ai_state, " and is moving to DROP OFF a crystal at: ", self.current_destination, " its dropoff_locations list is: ", self.dropoff_locations)
					Logger.info("#### DROPPING OFF: dropping_off_crystal_choose_destination - Agent: " + str(self.ID) + " is now in state " + str(self.current_ai_state) + " and is moving to DROP OFF a crystal at: " + str(self.current_destination) + " its dropoff_locations list is: " + str(self.dropoff_locations))
					break
			if found_dropoff == false:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = exploring_choose_destination
		dropping_off_crystal_moving_to_destination:
			move_along_path()
			if self.current_position == self.current_destination: 
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = dropping_off_crystal_arrived_at_destination
		dropping_off_crystal_arrived_at_destination:
			self.carrying_crystal = false
			# Remove the collection target from the location list if the agent picked up a different crystal than the one it intended to
			_remove_crystal_from_locations(self.collection_target)
			if self.crystal_locations.size() > 0:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = picking_up_crystal_choose_destination
			else:
				self.previous_ai_state = self.current_ai_state
				self.current_ai_state = exploring_choose_destination

# Append crystal location to crystal_locations, and move to collect it if the agent doesn't have one yet
func _on_CrystalDetection_area_entered(area: Area2D) -> void:
	var loc : Vector2 = tile_map.get_map_loc_from_pos(area.position.x, area.position.y)
	if GlobalValues.detecting_crystals and not loc in self.crystal_locations and not loc in self.crystal_location_blacklist and area.visible == true:
		self.crystal_locations.append(loc)
		print("## CRYSTAL DETECTION: _on_CrystalDetection_area_entered - Agent: ", self.ID, " has found crystals at: ", self.crystal_locations, " and will not re-detect those at: ", self.crystal_location_blacklist, " unless through communication.")
		Logger.info("## CRYSTAL DETECTION: _on_CrystalDetection_area_entered - Agent: " + str(self.ID) + " has found crystals at: " + str(self.crystal_locations) + " and will not re-detect those at: " + str(self.crystal_location_blacklist) + " unless through communication.")

# Return to the dropoff point once we collect a crystal
func _on_CrystalCollision_area_entered(area: Area2D) -> void:
	if self.carrying_crystal == false and area.visible == true:
		# Handle the crystal removal
		self.carrying_crystal = true
		area.visible = false
		area.queue_free()
		emit_signal("crystal_collected")
		# Explicit crystal location
		var loc : Vector2 = self.tile_map.get_map_loc_from_pos(area.position.x, area.position.y)
		# Print relevant log info
		print("## CRYSTAL COLLECTED: _on_CrystalCollision_area_entered - Agent: ", self.ID, " has COLLECTED a crystal from ", loc, ": crystal being carried = ", self.carrying_crystal)
		Logger.info("## CRYSTAL COLLECTED: _on_CrystalCollision_area_entered - Agent: " + str(self.ID) + " has COLLECTED a crystal from " + str(loc) + ": crystal being carried = " + str(self.carrying_crystal))
		# Add location to blacklist and change state
		_add_location_to_movement_location_blacklist(loc)
		_add_crystal_to_crystal_location_blacklist(loc)
		# Check to see if we collected a different crystal than the one we wanted
		if loc != self.collection_target and GlobalValues.detecting_crystals == true:
			self.crystal_locations.append(self.collection_target)
			self.collection_target = loc
			print("## CRYSTAL COLLECTED REMEMBERED: _on_CrystalCollision_area_entered - Agent: ", self.ID, " has REMEMBERED a crystal at: ", self.collection_target, " its list is: ", self.crystal_locations)
			Logger.info("## CRYSTAL COLLECTED REMEMBERED: _on_CrystalCollision_area_entered - Agent: " + str(self.ID) + " has REMEMBERED a crystal at: " + str(self.collection_target) + " its list is: " + str(self.crystal_locations))

# Remove a crystal at a given location from the list of crystal_locations
func _remove_crystal_from_locations(loc : Vector2) -> void:
	var remove_locs = []
	for i in range(0, self.crystal_locations.size()):
		if self.crystal_locations[i] == loc:
			remove_locs.append(i)
	remove_locs.invert()
	for location in remove_locs:
		self.crystal_locations.remove(location)
		print("# REMOVE FROM LOCATIONS: _remove_crystal_from_locations - Agent: ", self.ID, " had a crystal location: ", loc, " removed from it's list. That list is now: ", self.crystal_locations)
		Logger.info("# REMOVE FROM LOCATIONS: _remove_crystal_from_locations - Agent: " + str(self.ID) + " had a crystal location: " + str(loc) + " removed from it's list. That list is now: " + str(self.crystal_locations))
	return

# Remove a crystal at a given location from the crystal_location_blacklist
func _remove_crystal_from_crystal_location_blacklist(loc : Vector2) -> void:
	var remove_locs = []
	for i in range(0, self.crystal_location_blacklist.size()):
		if self.crystal_location_blacklist[i] == loc:
			remove_locs.append(i)
	remove_locs.invert()
	for location in remove_locs:
		self.crystal_location_blacklist.remove(location)
		print("# REMOVE CRYSTAL FROM LOCATION BLACKLIST: Agent: ", self.ID, " had a crystal location: ", loc, " removed from it's crystal location blacklist. That list is now: ", self.crystal_location_blacklist)
		Logger.info("# REMOVE CRYSTAL FROM LOCATION BLACKLIST: Agent: " + str(self.ID) + " had a crystal location: " + str(loc) + " removed from it's crystal location blacklist. That list is now: " + str(self.crystal_location_blacklist))
	return

# Remove a crystal at a given location from the movement_location_blacklist
func _remove_location_from_movement_location_blacklist(loc : Vector2) -> void:
	var remove_locs = []
	for i in range(0, self.movement_location_blacklist.size()):
		if self.movement_location_blacklist[i] == loc:
			remove_locs.append(i)
	remove_locs.invert()
	for location in remove_locs:
		self.movement_location_blacklist.remove(location)
		print("# REMOVE LOCATION FROM MOVEMENT BLACKLIST: Agent: ", self.ID, " had a crystal location: ", loc, " removed from it's movement location blacklist. That list is now: ", self.movement_location_blacklist)
		Logger.info("# REMOVE LOCATION FROM MOVEMENT BLACKLIST: Agent: " + str(self.ID) + " had a crystal location: " + str(loc) + " removed from it's movement location blacklist. That list is now: " + str(self.movement_location_blacklist))
	return

# Remove a crystal at a given location from the movement_location_yellowlist
func _remove_location_from_movement_location_yellowlist(loc : Vector2) -> void:
	var remove_locs = []
	for i in range(0, self.movement_location_yellowlist.size()):
		if self.movement_location_yellowlist[i] == loc:
			remove_locs.append(i)
	remove_locs.invert()
	for location in remove_locs:
		self.movement_location_yellowlist.remove(location)
		print("# REMOVE LOCATION FROM MOVEMENT YELLOWLIST: Agent: ", self.ID, " had a crystal location: ", loc, " removed from it's movement location yellowlist.")
		Logger.info("# REMOVE LOCATION FROM MOVEMENT YELLOWLIST: Agent: " + str(self.ID) + " had a crystal location: " + str(loc) + " removed from it's movement location yellowlist.")
	return

# Add a location to the movement blacklist
func _add_location_to_movement_location_blacklist(loc : Vector2) -> void:
	if not loc in self.dropoff_locations and not loc in self.movement_location_blacklist:
		# Add a valid location to the 'black list'
		self.movement_location_blacklist.append(loc)
		self.movement_location_blacklist = GlobalValues.remove_duplicates_from_list(self.movement_location_blacklist)
		print("# ADD LOCATION TO MOVEMENT BLACKLIST: Agent: ", self.ID, " had a location, ", loc, ", added to its movement blacklist ", self.movement_location_blacklist)
		Logger.info("# ADD LOCATION TO MOVEMENT BLACKLIST: Agent: " + str(self.ID) + " had a location, " + str(loc) + ", added to its movement blacklist " + str(self.movement_location_blacklist))
		# Add surrounding locations to a 'yellow list'
		var new_yellow_list : = PoolVector2Array()
		new_yellow_list.append(loc)
		new_yellow_list = movement_location_yellowlist_BFS(new_yellow_list, 0, 5) # level values can be 1, 5, 13, 25, 41, etc. for 1, 2, 3, 4, 5 layers
		self.movement_location_yellowlist += new_yellow_list
		self.movement_location_yellowlist = GlobalValues.remove_duplicates_from_list(self.movement_location_yellowlist)

# Add a location to the movement blacklist
func _add_crystal_to_crystal_location_blacklist(loc : Vector2) -> void:
	if not loc in self.crystal_location_blacklist:
		# Add a valid location to the 'black list'
		self.crystal_location_blacklist.append(loc)
		self.crystal_location_blacklist = GlobalValues.remove_duplicates_from_list(self.crystal_location_blacklist)
		print("# ADD LOCATION TO CRYSTAL BLACKLIST: Agent: ", self.ID, " had a location, ", loc, ", added to its crystal_location_blacklist ", self.crystal_location_blacklist)
		Logger.info("# ADD LOCATION TO CRYSTAL BLACKLIST: Agent: " + str(self.ID) + " had a location, " + str(loc) + ", added to its crystal_location_blacklist " + str(self.crystal_location_blacklist))

func movement_location_yellowlist_BFS(considering : PoolVector2Array, pos : int, level : int) -> PoolVector2Array:
	if level == 0:
		pass
	else:
		var current : Vector2 = considering[pos]
		level -= 1
		
		# Up
		if not self.tile_map.is_outside_map_bounds(Vector2(current.x, current.y - 1)) and not Vector2(current.x, current.y - 1) in considering:
			considering.append(Vector2(current.x, current.y - 1))
		# Down
		if not self.tile_map.is_outside_map_bounds(Vector2(current.x, current.y + 1)) and not Vector2(current.x, current.y + 1) in considering:
			considering.append(Vector2(current.x, current.y + 1))
		# Left
		if not self.tile_map.is_outside_map_bounds(Vector2(current.x - 1, current.y)) and not Vector2(current.x - 1, current.y) in considering:
			considering.append(Vector2(current.x - 1, current.y))
		# Right
		if not self.tile_map.is_outside_map_bounds(Vector2(current.x + 1, current.y)) and not Vector2(current.x + 1, current.y) in considering:
			considering.append(Vector2(current.x + 1, current.y))
		
		pos += 1
		considering = movement_location_yellowlist_BFS(considering, pos, level)
		
	return considering

# State 0 - exploring
func _set_new_random_end_point() -> void:
	var yellow_rand_val = randf()
	self.previous_destination = self.current_destination
	self.current_destination = get_random_cell_position()
	while ((self.current_destination in self.movement_location_blacklist) or 
		   (self.current_destination in self.movement_location_yellowlist and 
			yellow_rand_val < GlobalValues.yellow_list_chance) or
		   (self.current_destination == self.current_position)):
		self.current_destination = get_random_cell_position()
		yellow_rand_val = randf()
	
	while set_destination(int(self.current_destination.x), int(self.current_destination.y)) == 1:
		print("# SET NEW ENDPOINT ERROR: _set_new_random_end_point BAD DESTINATION: ", self.current_destination)
		yellow_rand_val = randf()
		self.previous_destination = self.current_destination
		self.current_destination = get_random_cell_position()
		while ((self.current_destination in self.movement_location_blacklist) or 
			   (self.current_destination in self.movement_location_yellowlist and 
				yellow_rand_val < GlobalValues.yellow_list_chance) or
			   (self.current_destination == self.current_position)):
			self.current_destination = get_random_cell_position()
			yellow_rand_val = randf()


func _on_DropoffCollision_area_entered(area: Area2D) -> void:
	if self.carrying_crystal == true:
		self.carrying_crystal = false
		emit_signal("crystal_dropped_off")
		print("## DROPOFF COLLISION: _on_DropoffCollision_area_entered - Agent: ", self.ID, " has DROPPED OFF its crystal. # of crystals being carried = ", self.carrying_crystal)
		Logger.info("## DROPOFF COLLISION: _on_DropoffCollision_area_entered - Agent: " + str(self.ID) + " has DROPPED OFF its crystal. # of crystals being carried = " + str(self.carrying_crystal))
	
func _on_CommunicationDetection_area_entered(area: Area2D) -> void:
	# Make sure we're communicating with another "Alien"
	if area.get_parent().name == "Alien" and GlobalValues.communicating == true:
		self.current_communication_target = area.get_parent()

		# Update crystal black lists
		var black_list1 : = PoolVector2Array()
		var black_list2 : = PoolVector2Array()
		black_list1 = self.crystal_location_blacklist
		black_list2 = self.current_communication_target.crystal_location_blacklist
		black_list1 += black_list2
		black_list1 = GlobalValues.remove_duplicates_from_list(black_list1)
		self.crystal_location_blacklist = black_list1
		self.current_communication_target.crystal_location_blacklist = black_list1

		# Update movement location black lists
		var movement_black_list1 : = PoolVector2Array()
		var movement_black_list2 : = PoolVector2Array()
		movement_black_list1 = self.movement_location_blacklist
		movement_black_list2 = self.current_communication_target.movement_location_blacklist
		movement_black_list1 += movement_black_list2
		movement_black_list1 = GlobalValues.remove_duplicates_from_list(movement_black_list1)
		self.movement_location_blacklist = movement_black_list1
		self.current_communication_target.movement_location_blacklist = movement_black_list1

		# Update movement location yellow lists
		var movement_yellow_list1 : = PoolVector2Array()
		var movement_yellow_list2 : = PoolVector2Array()
		movement_yellow_list1 = self.movement_location_yellowlist
		movement_yellow_list2 = self.current_communication_target.movement_location_yellowlist
		movement_yellow_list1 += movement_yellow_list2
		movement_yellow_list1 = GlobalValues.remove_duplicates_from_list(movement_yellow_list1)
		self.movement_location_yellowlist = movement_yellow_list1
		self.current_communication_target.movement_location_yellowlist = movement_yellow_list1

		# Append both lists of crystals to one another
		var selfL : PoolVector2Array = self.crystal_locations
		var areaL : PoolVector2Array = self.current_communication_target.crystal_locations
		selfL += areaL

		# Remove duplicate crystal entries
		selfL = GlobalValues.remove_duplicates_from_list(selfL)

		# Find the nearest dropoff
		var drop_dist : float = 9999999.9
		var curr_drop_dist : float = 0.0
		var selected_dropoff : Vector2
		for i in range(0, self.dropoff_locations.size()):
			curr_drop_dist = GlobalValues.relative_distance(self.dropoff_locations[i], self.tile_map.get_map_loc_from_pos(self.position.x, self.position.y))
			if curr_drop_dist < drop_dist:
				drop_dist = curr_drop_dist
				selected_dropoff = dropoff_locations[i]

		# Find the distances of all the crystals, relative to the closest dropoff point
		var all_items = []
		for i in range(0, selfL.size()):
			all_items.append([Vector2(selfL[i].x, selfL[i].y), GlobalValues.relative_distance(selfL[i], selected_dropoff)])

		# Sort all_items based on distance to nearest dropoff
		all_items.sort_custom(GlobalValues, "custom_sort_1")

		# Place half the items in all_items into one entity, and the other half in the other
		var list1 : = PoolVector2Array()
		var list2 : = PoolVector2Array()
		var dividing_point : int = int(floor(all_items.size() / 2.0))
		for i in range(0, dividing_point):
			if not all_items[i][0] in self.current_communication_target.crystal_location_blacklist:
				list2.append(all_items[i][0])
		for i in range(dividing_point, all_items.size()):
			if not all_items[i][0] in self.crystal_location_blacklist:
				list1.append(all_items[i][0])

	#	# Split new list into two sub lists and assign one to each alien in the communication
	#	var list1 : = PoolVector2Array()
	#	var list2 : = PoolVector2Array()
	#	for i in range(0, len(selfL)):
	#		if i % 2 == 0:
	#			list1.append(selfL[i])
	#		else:
	#			list2.append(selfL[i])

		# Assign new lists to the two communicating agents
		self.crystal_locations = list1
		self.current_communication_target.crystal_locations = list2

		# If the crystal we were going to is no longer there, either explore or go to the next one
		if self.carrying_crystal == false and self.current_destination in self.crystal_location_blacklist and self.crystal_locations.size() == 0:
			print("## COMMUNICATION - Agent: ", self.ID, " has CHANGED to exploring_choose_destination as its crystal WAS NOT THERE...")
			Logger.info("## COMMUNICATION - Agent: " + str(self.ID) + " has CHANGED to exploring_choose_destination as its crystal WAS NOT THERE...")
			self.current_ai_state = exploring_choose_destination
		elif self.carrying_crystal == false and self.current_destination in self.crystal_location_blacklist and self.crystal_locations.size() > 0:
			print("## COMMUNICATION - Agent: ", self.ID, "has CHANGED to picking_up_crystal_choose_destination as its crystal WAS NOT THERE...")
			Logger.info("## COMMUNICATION - Agent: " + str(self.ID) + " has CHANGED to picking_up_crystal_choose_destination as its crystal WAS NOT THERE...")
			self.current_ai_state = picking_up_crystal_choose_destination

		if self.current_communication_target.carrying_crystal == false and self.current_communication_target.current_destination in self.current_communication_target.crystal_location_blacklist and self.current_communication_target.crystal_locations.size() == 0:
			print("## COMMUNICATION - Agent: ", self.current_communication_target.ID, " has CHANGED to exploring_choose_destination as its crystal WAS NOT THERE...")
			Logger.info("## COMMUNICATION - Agent: " + str(self.current_communication_target.ID) + " has CHANGED to exploring_choose_destination as its crystal WAS NOT THERE...")
			self.current_communication_target.current_ai_state = exploring_choose_destination
		elif self.current_communication_target.carrying_crystal == false and self.current_communication_target.current_destination in self.current_communication_target.crystal_location_blacklist and self.current_communication_target.crystal_locations.size() > 0:
			print("## COMMUNICATION - Agent: ", self.current_communication_target.ID, "has CHANGED to picking_up_crystal_choose_destination as its crystal WAS NOT THERE...")
			Logger.info("## COMMUNICATION - Agent: " + str(self.current_communication_target.ID) + " has CHANGED to picking_up_crystal_choose_destination as its crystal WAS NOT THERE...")
			self.current_communication_target.current_ai_state = picking_up_crystal_choose_destination

		# Report agent communication
		print("## COMMUNICATION HAS OCCURRED! ##")
		Logger.info("## COMMUNICATION HAS OCCURRED! ##")
		print("## COMMUNICATION - Agent: ", self.ID, " has communicated with agent: ", self.current_communication_target.ID, ", and now has knowledge of crystals at locations: ", self.crystal_locations)
		Logger.info("## COMMUNICATION - Agent: " + str(self.ID) + " has communicated with agent: " + str(self.current_communication_target.ID) + ", and now has knowledge of crystals at locations: " + str(self.crystal_locations))
		print("## COMMUNICATION - Agent: ", self.current_communication_target.ID, " has communicated with agent: ", self.ID, ", and now has knowledge of crystals at locations: ", self.current_communication_target.crystal_locations)
		Logger.info("## COMMUNICATION - Agent: " + str(self.current_communication_target.ID) + " has communicated with agent: " + str(self.ID) + ", and now has knowledge of crystals at locations: " + str(self.current_communication_target.crystal_locations))

		# Print the blacklist if it isn't too long
		if self.movement_location_blacklist.size() <= 10:
			print("## COMMUNICATION - The movement black list is:", self.movement_location_blacklist)
			Logger.info("## COMMUNICATION - The movement black list is:" + str(self.movement_location_blacklist))

		# Print the yellowlist if it isn't too long
		if self.movement_location_yellowlist.size() <= 10:
			print("## COMMUNICATION - The movement yellow list is:", self.movement_location_yellowlist)
			Logger.info("## COMMUNICATION - The movement yellow list is:" + str(self.movement_location_yellowlist))

		# Set communication target to nothing
		self.current_communication_target = null
