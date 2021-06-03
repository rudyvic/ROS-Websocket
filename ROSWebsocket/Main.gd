extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$ROSTestStringSubscriber.connect("data_available",self,"_on_data_available")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$lblConnected.text = "Connection status to '%s': " % RosWebsocket.websocket_url
	$lblConnected.text += str(RosWebsocket.ConnectionStatus.keys()[RosWebsocket.connection_status()])
	
	$btnConnect.disabled = !(RosWebsocket.connection_status() != RosWebsocket.ConnectionStatus.CONNECTED)


func _on_data_available(topic: String):
	if topic == "/test_string":
		var data_field = $ROSTestStringSubscriber.get_msg()["data"]
		$lblTestSub.text = "Read from ROS (topic /test_topic):\n\n'%s'" % str(data_field)


func _on_btnPublish_pressed():
	var field_string = $linFieldString.text
	$ROSTestStringPublisher.set_data(field_string)
	$ROSTestStringPublisher.send_msg()


func _on_btnConnect_pressed():
	if RosWebsocket.connection_status() != RosWebsocket.ConnectionStatus.CONNECTED:
		RosWebsocket.websocket_url = $linWebsocketURL.text
		RosWebsocket.connect_with_attempts(1)
