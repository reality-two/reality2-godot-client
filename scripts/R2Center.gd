# ======================================================================================================================================================
# R2 Center
# ---------
#
# The central sphere in the 3D world, from which all the Reality2 Nodes come out.  Each Reality2 Node gets its own GQL connection.
#
# Dr. Roy C.Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

extends RigidBody3D

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Public Variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
@export_group("Reality2 Node")
@export var startingNode = "localhost"
@export var NodeNames = []
@export var r2class = "reality2"
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Private Variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
var _node_scene = preload("res://scenes/R2Node.tscn")
var _angularVelocity = Vector3(0,0,0)
var _reality2_nodes = {}
var R2GQL

# A Sentant to give us information about the internal goings on of the node.
var monitoringSentant = {
	"sentant": {
		"name": "monitor",
		"automations": [
			{
				"name": "Monitor",
				"transitions": [
					{
						"from": "start",
						"to": "idle",
						"event": "init"
					},
					{
						"from": "idle",
						"to": "idle",
						"event": "__internal",
						"actions": [
							{
								"command": "signal",
								"parameters": {
									"public": true,
									"event": "internal"
								}
							}
						]
					}
				]
			}
		]
	}
}
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Called when the node enters the scene tree for the first time.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _ready():
	add_node(startingNode)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Monitor changes to the Node coming from the Monitor node created above.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _monitor(data = {}, passthrough = {}):
	print ("_MONITOR", data, passthrough)
	if (data.has("event")):
		if (data.parameters.has("activity")):
			if (data.parameters.activity == "created"):
				_reality2_nodes[passthrough.name].r2gql.sentantGet(data.parameters.id, _create_sentant, "description id name signals events { event parameters }", { "node_name": passthrough.name })
			elif (data.parameters.activity == "deleted"):
				_reality2_nodes[passthrough.name].node_visual.remove_sentant(data.parameters.name)
				
func _create_sentant(response, passthrough):
	print("Creating: ", response, "\n", passthrough)
	if (response.has("id")):
		_reality2_nodes[passthrough.node_name].node_visual.add_sentant(passthrough.node_name, "", response.name, response)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Called every frame. 'delta' is the elapsed time since the previous frame.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _process(delta):
	# Add a bit of gentle motion
	_angularVelocity = Useful.gentle_twist(delta, _angularVelocity)
	rotation = rotation + _angularVelocity
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Add a graphical representation of a Node.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func add_node(nodeName: String):
	if not nodeName in NodeNames:
		NodeNames.append(nodeName)
		_reality2_nodes[nodeName] = {"r2gql": Reality2.GQL.new(true, nodeName, 4005), "node_visual": null}
		self.add_child(_reality2_nodes[nodeName].r2gql.GQL())	
		_reality2_nodes[nodeName].r2gql.byName( "monitor", func (id):
			if (id == null):
				_reality2_nodes[nodeName].r2gql.sentantLoad( JSON.stringify(monitoringSentant) )				
		)
		_reality2_nodes[nodeName].r2gql.sentantAll(func(sentants, passthrough): _add_sentants(passthrough.name, sentants), "description id name signals events { event parameters }", {"name": nodeName})
		_reality2_nodes[nodeName].r2gql.byName( "monitor", func(id): _reality2_nodes[nodeName].r2gql.awaitSignal(id, "internal", _monitor, "sentant { name id events { event parameters } signals } event parameters passthrough", {"name": nodeName}) )
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Send an event to a sentant on a given node
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func send_event(nodeName: String, id: String, event: String, parameters = {}):
	_reality2_nodes[nodeName].r2gql.sentantSend(id, event, parameters, func(_result, _passthrough): pass)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Add a Node
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _add_sentants(nodeName: String, sentants = []):
	if (_reality2_nodes[nodeName].r2gql.connected()):
		_reality2_nodes[nodeName].node_visual = _node_scene.instantiate()
		_reality2_nodes[nodeName].node_visual.load_sentants(nodeName, _reality2_nodes[nodeName].r2gql.GQL().link_url(), sentants)
			
		_reality2_nodes[nodeName].node_visual.name = nodeName
		_reality2_nodes[nodeName].node_visual.details = {"url": _reality2_nodes[nodeName].r2gql.GQL().url(), "websocket": _reality2_nodes[nodeName].r2gql.GQL().socket_url(), "linkurl": _reality2_nodes[nodeName].r2gql.GQL().link_url()}
		_reality2_nodes[nodeName].node_visual.r2class = "node"
		add_child(_reality2_nodes[nodeName].node_visual)
# ------------------------------------------------------------------------------------------------------------------------------------------------------
