# ======================================================================================================================================================
# GraphQL
# -------
#
# A very simple GraphQL set of functions designed for the Reality2 Node, but could be adapted for other GraphQL scenarios.
# To use it, create a Node object and add this as its script.  If you need multiple GraphQL connections, create one for each.
#
# Dr. Roy C. Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

extends Node
class_name GraphQL

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Public parameters
# ------------------------------------------------------------------------------------------------------------------------------------------------------
## Domain name of Node, without the https:// or http://
@export var domain_name: String = "localhost"
## Port of the Node.  Usually 4005 (https) or 4006 (http).
@export var port: String = "4005"
## Whether to use secure connection or not.  Is is recommended to set this to true.
@export var secure: bool = true
## Time to wait before concluding websocket connection is not working (seconds)
@export var websocket_connection_timeout = 10
## How often to check the websocket connection to keep it open (seconds)
@export var websocket_heartbeat = 30
# ------------------------------------------------------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Private variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
var _socket = WebSocketPeer.new()
var _socket_heartbeat_time
var _socket_connected = false
var _callbacks = {}
var _callbacks_counter = 0

var _graphql_URL: String = ""
var _websocket_URL: String = ""
var _link_URL: String = ""
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func url():
	return _graphql_URL
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func socket_url():
	return _websocket_URL
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func link_url():
	return _link_URL
# ------------------------------------------------------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Is connected to the websocket
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func connected():
	return _socket_connected
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func set_domain(_secure: bool, _domain_name: String, _port: int):
	domain_name = _domain_name
	secure = _secure
	port = str(_port)
	
	if (secure):
		_graphql_URL = "https://" + domain_name + ":" + port + "/reality2"
		_websocket_URL = "wss://" + domain_name + ":" + port + "/reality2/websocket"
		_link_URL = "https://" + domain_name + ":" + port
	else:
		_graphql_URL = "http://" + domain_name + ":" + port + "/reality2"
		_websocket_URL = "ws://" + domain_name + ":" + port + "/reality2/websocket"
		_link_URL = "http://" + domain_name + ":" + port
		
	_SOCKET_connect()
	_socket_heartbeat_time = Time.get_ticks_msec() + websocket_heartbeat * 1000
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Do a GraphQL Query POST call
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func query(the_query, callback, variables={}, headers_dict={}, passthrough={}):
	# Queries and Mutations are sent the same way if using POST.
	mutation(the_query, callback, variables, headers_dict, passthrough)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Do a GraphQL Mutation POST call
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func mutation(the_query, callback, variables={}, headers_dict={}, passthrough={}):
	# Add the standard headers (or overwrite)
	headers_dict["Content-Type"] = "application/json"
	headers_dict["Accept"] = "*/*"
	
	# Convert the headers to the required format
	var headers = []
	for key in headers_dict.keys():
		headers.append(key + ":" + str(headers_dict[key]))
	
	# Create the body and POST it.
	var body = JSON.stringify({ "query": the_query, "variables": variables })
	_POST(body, callback, headers, passthrough)
# ------------------------------------------------------------------------------------------------------------------------------------------------------




# ------------------------------------------------------------------------------------------------------------------------------------------------------
# GraphQL subscription via Websocket
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func subscription(the_query, callback, variables={}, headers_dict={}, passthrough={}):
	if (_socket_connected):
		# Create a reference to save the callback for later
		var reference = str(_callbacks_counter)
		print (reference)
		
		# The subscription message (with the reference that is returned later)
		var subscribe = {
			"topic": "__absinthe__:control",
			"headers": headers_dict,
			"event": "doc",
			"payload": {
				"query": the_query,
				"variables": variables
			},
			"ref": reference
		}
		
		# Save the callback reference
		_callbacks[reference] = {"callback": callback, "passthrough": passthrough}
		_callbacks_counter = _callbacks_counter + 1
		# Send to the websocket
		_socket.send_text(JSON.stringify(subscribe))
	else:
		callback.call({"errors": [{"message": "Websocket not connected"}]}, passthrough)
# ------------------------------------------------------------------------------------------------------------------------------------------------------




# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Set things up
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _ready():
	if (secure):
		_graphql_URL = "https://" + domain_name + ":" + port + "/reality2"
		_websocket_URL = "wss://" + domain_name + ":" + port + "/reality2/websocket"
	else:
		_graphql_URL = "http://" + domain_name + ":" + port + "/reality2"
		_websocket_URL = "ws://" + domain_name + ":" + port + "/reality2/websocket"
		
	#_SOCKET_connect()
	#_socket_heartbeat_time = Time.get_ticks_msec() + websocket_heartbeat * 1000
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Poll the Websocket and keep it open
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _process(_delta):
	_socket.poll()
	while _socket.get_available_packet_count() > 0:
		# TODO: what happens if there is more than 1 packet?
		var data = _socket.get_packet().get_string_from_utf8()
		var data_dict = JSON.parse_string(data)
		
		if data_dict.has("payload"):
			if (data_dict.payload.has("status") and data_dict.payload.has("response")):
				if data_dict.payload.response.has("subscriptionId"):
					# Move the reference to the callback from the 'ref' position in the callbacks dict to the subscriptionId position
					_callbacks[data_dict.payload.response.subscriptionId] = _callbacks[data_dict.ref]
					_callbacks.erase(data_dict.ref)
				elif (data_dict.payload.status == "error"):
					if (data_dict.has("ref")):
						_callbacks[data_dict.ref].callback.call({"errors": [{"message": data_dict.payload.response.reason}]}, _callbacks[data_dict.ref].passthrough)
					
			elif (data_dict.payload.has("result") and data_dict.payload.has("subscriptionId")):
				# Using the subscriptionId, call the callback routine with the result
				var subscriptionID = data_dict.payload.subscriptionId
				if (_callbacks.has(subscriptionID)):
					_callbacks[subscriptionID].callback.call(data_dict.payload.result, _callbacks[subscriptionID].passthrough)
	
	# Check if it is time for a hearbeat.
	if (Time.get_ticks_msec() > _socket_heartbeat_time):
		_SOCKET_heartbeat()
		_socket_heartbeat_time = Time.get_ticks_msec() + websocket_heartbeat * 1000
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Connect to the websocket in preparation for a subscription call
# Note that this particular configuration is specfic for Absinthe in Phoenix Server.  You may need to tweak it for other graphql implementations.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _SOCKET_connect():
	# Open the connection
	_socket.connect_to_url(_websocket_URL, TLSOptions.client_unsafe())

	var timeout = Time.get_ticks_msec() + websocket_connection_timeout * 500
	_socket.poll()
	while (_socket.get_ready_state() != WebSocketPeer.State.STATE_OPEN) and (Time.get_ticks_msec() < timeout):
		_socket.poll()

	if (Time.get_ticks_msec() < timeout):
		var join_message = {
			"topic": "__absinthe__:control",
			"event": "phx_join",
			"payload": {},
			"ref": 0
		}
		_socket.send_text(JSON.stringify(join_message))

		timeout = Time.get_ticks_msec() + websocket_connection_timeout * 500
		_socket.poll()
		while (_socket.get_ready_state() != WebSocketPeer.State.STATE_OPEN) and (Time.get_ticks_msec() < timeout):
			_socket.poll()

		if (Time.get_ticks_msec() < timeout):		
			_socket_connected = true
			print ("Websocket Connected")
		else:
			_socket_connected = false
			print ("Websocket Timed out")
	else:
		_socket_connected = false
		print ("Websocket Timed out")
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Called regularly to keep the websocket alive
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _SOCKET_heartbeat():
	if (_socket_connected):
		var heartbeat = {
			"topic": "phoenix",
			"event": "heartbeat",
			"payload": {},
			"ref": 0
		}
		_socket.send_text(JSON.stringify(heartbeat))
		print("heartbeat")
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Post data in the body to a URL, with headers, and return the result to the callback function, or an appropriate error
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _POST(body, callback, headers, passthrough):
	var uri = _URL(_graphql_URL)	
	var err = 0
	var http = HTTPClient.new() # Create the Client.

	if (uri.scheme == "http"):
		err = http.connect_to_host(uri.domain, uri.port.to_int())
	else:
		err = http.connect_to_host(uri.domain, uri.port.to_int(), TLSOptions.client_unsafe())
		
	if (err == OK):
		# Wait until resolved and connected.
		while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
			http.poll()
			
		# Check if the connection was made successfully.
		if (http.get_status() == HTTPClient.STATUS_CONNECTED):
			err = http.request(HTTPClient.METHOD_POST, uri.path, headers, body)
			if (err == OK):
				# Wait until the requesting is done
				while http.get_status() == HTTPClient.STATUS_REQUESTING:
					http.poll()
				
				if (http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED):
					if http.has_response():
						# Read the response
						var response = PackedByteArray()
						while http.get_status() == HTTPClient.STATUS_BODY:
							http.poll()
							var chunk = http.read_response_body_chunk()
							if chunk.size() != 0:
								response += chunk
						callback.call(JSON.parse_string(response.get_string_from_ascii()), passthrough)
					else:
						callback.call({"errors": [{"message": "response error"}]}, passthrough)
				else:
					callback.call({"errors": [{"message": "request error"}]}, passthrough)
			else:
				callback.call({"errors": [{"message": "request error"}]}, passthrough)
		else:
			callback.call({"errors": [{"message": "connection error"}]}, passthrough)
	else:
		callback.call({"errors": [{"message": "connection error"}]}, passthrough)
# ------------------------------------------------------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Split a URL into component parts
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _URL(the_url: String):
	var pieces = the_url.split("/")
	var scheme = pieces[0].get_slice(":", 0)
	var domain_and_port = pieces[2]
	var domain = domain_and_port.get_slice(":", 0)
	var the_port = domain_and_port.get_slice(":", 1)
	var path = "/"
	if (pieces.size() > 2):
		path = path + pieces[3]
	
	return({"scheme": scheme, "domain": domain, "port": the_port, "path": path})
# ------------------------------------------------------------------------------------------------------------------------------------------------------
