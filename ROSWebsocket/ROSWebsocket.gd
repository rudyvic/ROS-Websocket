# Class that handles the communication with the Websocket and provides
# all the necessary functions to interact with ROS topics and services.
extends Node
class_name ROSWebsocket

# Signal emitted everytime that the connection_status changes.
signal connection_status_changed

# Signal emitted everytime a status message is received.
signal service_response_received

# The URL to connect to, composed by the server IP and port.
var websocket_url

# Enum containing the possible status of the connection.
enum ConnectionStatus {
	NOT_CONNECTED, 
	CONNECTED, 
	CONNECTING,
}

# Actual status of the connection.
var _connection_status = ConnectionStatus.NOT_CONNECTED

# Remaining number of attempts to connect.
var _attempts = 1

# List of the topics with subscribed nodes.
var _subscribed_nodes = Dictionary()

# WebSocketClient instance.
var _client = WebSocketClient.new()


func _ready():
	websocket_url = "ws://localhost:9090"
	
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_connection_error")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")
	
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_BINARY)
	_try_to_connect()


# Try to connect to the server if there are attempts left.
func _try_to_connect():
	_change_connection_status(ConnectionStatus.CONNECTING)
	if(_attempts<=0):
		_change_connection_status(ConnectionStatus.NOT_CONNECTED)
		return
	_attempts -= 1
	# Initiate connection to the given URL.
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print_debug("ROSWebsocket ",str(self)," unable to connect")
		_change_connection_status(ConnectionStatus.NOT_CONNECTED)


# Function called when the connection is closed. The parameter indicates if the
# disconnection was correctly notified by the remote peer before closing
# the socket.
func _closed(was_clean: bool = false):
	print_debug("ROSWebsocket ",str(self)," closed, clean: ", was_clean)
	_change_connection_status(ConnectionStatus.NOT_CONNECTED)
	
	# clear the subscribed nodes list
	_subscribed_nodes.clear()


# Function called when there is a connection error.
func _connection_error():
	print_debug("ROSWebsocket ",str(self)," connection error... trying again")
	_try_to_connect()


# Function called when the connection is estabilished. The parameter indicates
# the selected WebSocket sub-protocol (which is optional).
func _connected(proto: String = ""):
	print_debug("ROSWebsocket ",str(self)," connected with protocol: ",proto)
	_change_connection_status(ConnectionStatus.CONNECTED)


# Function called when a packet is received.
func _on_data():
	# You MUST always use get_peer(1).get_packet to receive data from server, 
	# and not get_packet directly when not using the MultiplayerAPI.
	var m = parse_json(_client.get_peer(1).get_packet().get_string_from_utf8())
	
	if m["op"]=="publish":
		if _subscribed_nodes.has(m["topic"]):
			for node in _subscribed_nodes[m["topic"]]:
				node.receive_msg(m["msg"])
		else:
			push_warning("Received a message on the topic [" + m["topic"] + "] " +
					" that it hasn't active subscribers. " +
					"Maybe a subscriber node didn't unsubscribe to the topic [" + 
					m["topic"] + "]. " + str(m))
	elif m["op"]=="service_response":
		emit_signal("service_response_received",m)
	else:
		push_error("Received a [" + m["op"] + "]. Implement the code to handle it.\n" + str(m))


func _process(_delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()


func _exit_tree():
	_closed()
	_client.disconnect_from_host()


# Function called when there is a change in the connection status.
# Emit the signal "connection_status_changed".
func _change_connection_status(status: int):
	_connection_status = status
	emit_signal("connection_status_changed")


# Try to connect with the given number of attempts.
func connect_with_attempts(attempts: int):
	_attempts = attempts
	_try_to_connect()


# Return the connection status [ConnectionStatus].
func connection_status() -> int:
	return _connection_status


# Send a JSON packet. Return an [Error].
func _send_json_packet(packet: String):
	if(_connection_status==ConnectionStatus.CONNECTED):
		var v = validate_json(packet)
		if not v:
			# You MUST always use get_peer(1).put_packet to send data to server,
			# and not put_packet directly when not using the MultiplayerAPI.
			_client.get_peer(1).put_packet(packet.to_utf8())
			return OK
		else:
			push_error(str("ROSWebsocket: JSON parse error in _send_json_packet(): "+v))
			return ERR_PARSE_ERROR
	return FAILED


# Add a node to the subscribed list. Return an [Error].
func _add_subscribed_node(node,topic: String) -> int:
	if !_subscribed_nodes.has(topic):
		_subscribed_nodes[topic] = []
	
	if _subscribed_nodes[topic].find(node) == -1:
		_subscribed_nodes[topic].append(node)
		return OK
	else:
		_subscribed_nodes[topic].append(node)
		return ERR_ALREADY_EXISTS


# Subscribe the [target] node to the [topic] of [type]. Return an [Error].
func subscribe_to_topic(target: Node, topic: String, type: String) -> int:
	if(_connection_status==ConnectionStatus.CONNECTED):
		var packet = to_json({"op":"subscribe","topic":topic,"type":type})
		var r = _send_json_packet(packet)
		if r==OK:
			return _add_subscribed_node(target,topic)
		else:
			return r
	return FAILED


# Unsubscribe the [target] node from the [topic]. Return an [Error].
func unsubscribe_to_topic(target: Node, topic: String) -> int:
	if !_subscribed_nodes.has(topic):
		return ERR_DOES_NOT_EXIST
	
	if _subscribed_nodes[topic].find(target) == -1:
		return ERR_DOES_NOT_EXIST
	else:
		_subscribed_nodes[topic].erase(target)
		if _subscribed_nodes[topic].size() == 0:
			_subscribed_nodes.erase(topic)
			if(_connection_status==ConnectionStatus.CONNECTED):
				var packet = to_json({"op":"unsubscribe","topic":topic})
				return _send_json_packet(packet)
			return FAILED
		return OK


# Unadvertise the [topic]. Return an [Error].
func unadvertise_topic(topic: String) -> int:
	if(_connection_status==ConnectionStatus.CONNECTED):
		var packet = to_json({"op":"unadvertise","topic":topic})
		return _send_json_packet(packet)
	return FAILED


# Advertise the [topic] of [type]. Return an [Error].
func advertise_topic(topic: String, type: String) -> int:
	if(_connection_status==ConnectionStatus.CONNECTED):
		var packet = to_json({"op":"advertise","topic":topic,"type":type})
		return _send_json_packet(packet)
	return FAILED


# Publish the [msg] to the [topic]. Return an [Error].
func puslish_topic(topic: String, msg: Dictionary) -> int:
	if(_connection_status==ConnectionStatus.CONNECTED):
		var packet = to_json({"op":"publish","topic":topic,"msg":msg})
		return _send_json_packet(packet)
	return FAILED


# Unadvertise with an [id] the [service]. Return an [Error].
func unadvertise_service(id: String, service: String) -> int:
	if(_connection_status==ConnectionStatus.CONNECTED):
		var packet = to_json({"op":"unadvertise_service","id":id,"service":service})
		return _send_json_packet(packet)
	return FAILED


# Advertise with an [id] the [service] of [type]. Return an [Error].
func advertise_service(id: String, service: String, type: String) -> int:
	if(_connection_status==ConnectionStatus.CONNECTED):
		var packet = to_json({"op":"advertise_service","id":id,"service":service,"type":type})
		return _send_json_packet(packet)
	return FAILED


# Call with an [id] and [args] the [service]. Return an [Error].
func call_service(id: String, service: String, args: Dictionary) -> int:
	if(_connection_status==ConnectionStatus.CONNECTED):
		var packet = to_json({"op":"call_service","id":id,"service":service,"args":args})
		return _send_json_packet(packet)
	return FAILED
