# Class that provides functions to easily implement ROS publisher classes.
extends Node
class_name ROSPublisher

var _msg = Dictionary()
var _is_connected = false
var _topic = ""
var _msg_type = ""


func _ready():
	RosWebsocket.connect("connection_status_changed",self,"initiate_connection")


# Initiate the connection with the [RosWebsocket].
func initiate_connection() -> int:
	if _topic=="" or _msg_type=="":
		return ERR_UNCONFIGURED
	var res = RosWebsocket.advertise_topic(_topic,_msg_type)
	if res == OK:
		_is_connected = true
	else:
		_is_connected = false
	return res


func _exit_tree():
	_is_connected = false
	if RosWebsocket.unadvertise_topic(_topic) != OK:
		push_warning(str(str(self)," couldn't unadvertise ",_topic))


# Publish the message.
func send_msg() -> int:
	if _is_connected:
		return RosWebsocket.puslish_topic(_topic,_msg)
	return ERR_UNCONFIGURED

