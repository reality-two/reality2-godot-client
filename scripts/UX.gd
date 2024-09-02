# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------

extends Node

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Public variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
@export var menus: Node
@export var input_box: Node
@export var details_box: Node
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------------------------------------------------------------------------------
signal add_new_node(name: String)
signal send_event(nodeName: String, id: String, event: String, parameters)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Private variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
var mode = "selecting"
var current_details = {}
var current_name = ""
# ------------------------------------------------------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _ready():
	pass
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func unselect():
	if (input_box):
		if mode == "NewNodeEnteringText_1":
			mode = "NewModeEnteringText"
		elif mode == "NewModeEnteringText":
			print("Cancelling")
			set_menu("Reality2")
			mode = "selecting"
# ------------------------------------------------------------------------------------------------------------------------------------------------------


		
# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func set_menu(the_name: String, details = {}):
	print("Showing Menu:" + the_name)
	print("Details:" + JSON.stringify(details))
		
	if menus:
		menus.show_child_by_name(the_name)
	if input_box:
		_setVisibility(input_box, false)
	if details_box:
		_setVisibility(details_box, false)
	mode = "selecting"
	current_name = the_name
	current_details = details
	
	for menu in menus.get_children():
		print(menu.name + " : ", menu.visible)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# What to do when a menu is selected
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func menu_selected(slot, id):
	print ("Selected Menu : ", slot.name, ", ", id)
	if (slot == null): return
	if (mode == "selecting"):
		match (slot.get_parent().name):
			"Reality2":
				match (slot.name):
					"CloseAll":
						print("Closing all connections")
					"ReloadAll":
						print("Reloading all nodes")
					"OpenNew":
						print("Opening a new node")
						mode = "NewNodeEnteringText_1"
						menus.show_child(-1)
						if input_box:
							_setVisibility(input_box, true)
			"Node":
				match (slot.name):
					"Close":
						print("Closing this node")
					"Reload":
						print("Reloading this node")
					"NewSentant":
						print("Creating a new sentant")
					"Info":
						menus.show_child(-1)
						mode = "ShowingDetails"
						if details_box:
							_set_details("", current_details.url if current_details.has("url") else "")
							_setVisibility(details_box, true)
							print(current_details)
							print("Getting node info")
							OS.shell_open(current_details.linkurl)
			"Sentant":
				match (slot.name):
					"Delete":
						print("Deleting this sentant")
					"Message":
						if (current_details.has("events")):
							var events_menu = menus.show_child_by_name("Events")
							set_events_menu(current_details["events"], events_menu)

					"Info":
						menus.show_child(-1)
						mode = "ShowingDetails"
						if details_box:
							_set_details(current_details.name if current_details.has("name") else "", current_details.description if current_details.has("description") else "")
							_setVisibility(details_box, true)
							print(current_details)
							print("Getting sentant info")
							OS.shell_open(current_details.url + "?name=" + current_details.name)
			"Events":
				if (current_details.has("id") and slot.name != "" and slot.name != "__close__" and slot.name != "__event__"):
					print("Sending an event to this sentant ", current_details.id, " : ", slot.name)
					emit_signal("send_event", current_details.nodeName, current_details.id, slot.name)
				menus.show_child_by_name("Sentant")
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func set_events_menu(events, menu):
	clear_events_menu(menu)
	var segments = menu.get_children()
	var event_segment = segments[1]
		
	if (events.size() >= 2):
		print(events)
		print (segments.size())

		for i in range (0, events.size() - 1):
			var new_child = event_segment.duplicate()
			menu.add_child(new_child)
			
		var updated_segments = menu.get_children()
		print(updated_segments.size())
		for i in range (1, updated_segments.size()):
			var child = menu.get_child(i)
			print(events[i-1]["event"])
			child.name = events[i-1]["event"]
			child.text = events[i-1]["event"]
			
	elif (events.size() == 1):
		var new_child = event_segment.duplicate()
		new_child.name = events[0]["event"]
		new_child.text = events[0]["event"]
		event_segment.name = ""
		event_segment.text = ""
		menu.add_child(new_child)
		
	else:
		event_segment.name = "";
		event_segment.text = "";
					
	menu.queue_redraw()
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func clear_events_menu(menu):
	if (menu):
		var the_children = menu.get_children()
		print ("Clearing:", the_children.size())
		var counter = 0
		for child in the_children:
			if (counter > 1):
				print(child.name)
				menu.remove_child(child)
				child.queue_free()
			counter = counter + 1
		menu.queue_redraw()
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# What to do when
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func enterkey_pressed(new_text: String):
	print("Opening: " + new_text)
	emit_signal("add_new_node", new_text)
	set_menu("Reality2")
	mode = "selecting"
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func esckey_pressed():
	if (input_box): # and (mode == "NewNodeEnteringText" or mode == "ShowingDetails")):
		print("Esc Key")
		set_menu(current_name, current_details)
		mode = "selecting"
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func choosing_yes_or_no():
	pass
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _set_details(the_name, description):
	if details_box:
		var details_children = details_box.get_children()
		details_children[0].text = the_name
		details_children[1].text = description
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _setVisibility(node: Node, visible: bool):
	node.visible = visible
	node.set_process(visible)
	for child in node.get_children():
		_setVisibility(child, visible)
# ------------------------------------------------------------------------------------------------------------------------------------------------------
