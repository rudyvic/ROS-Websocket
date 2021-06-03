# Class that provides functions to easily implement Subscriber classes.
extends Node
class_name ROSSubscriber

# Signal emitted when new data is received.
signal data_available

var _msg: Dictionary
var _is_connected: bool = false
var _topic: String = ""
var _msg_type: String = ""
var _message_count: int = 0
var _hz_timer: Timer
var _hz: float = 0

func _ready():
	RosWebsocket.connect("connection_status_changed",self,"initiate_connection")
	_hz_timer = Timer.new()
	_hz_timer.one_shot = false
	_hz_timer.wait_time = 1.0
	_hz_timer.autostart = false
	add_child(_hz_timer)
	_hz_timer.connect("timeout",self,"_on_hz_timer_timeout")
	_hz_timer.start()


# Initiate the connection with the [RosWebsocket].
func initiate_connection() -> int:
	if _topic=="" or _msg_type=="":
		return ERR_UNCONFIGURED
	var res = RosWebsocket.subscribe_to_topic(self,_topic,_msg_type)
	if res == OK:
		_is_connected = true
	else:
		_is_connected = false
	return res


func _exit_tree():
	_is_connected = false
	if RosWebsocket.unsubscribe_to_topic(self,_topic) != OK:
		push_warning(str(str(self)," couldn't unsubscribe ",_topic))


# Receive the message (as Dictionary). It must be overridden by child classes.
func receive_msg(msg: Dictionary, is_called_from_child: bool = false):
	if !is_called_from_child:
		push_error("receive_msg(msg: Dictionary, is_called_from_child: bool = false) NOT IMPLEMENTED in " + str(self.name))
	else:
		_msg = msg
		_message_count += 1
		emit_signal("data_available",_topic)


# Return the message (as Dictionary)
func get_msg() -> Dictionary:
	return _msg


# Called when the timer for counting the rate of the topic emits a timeout.
# It counts how many messages has arrived in the last second.
func _on_hz_timer_timeout():
	_hz = _message_count / _hz_timer.wait_time
	_message_count = 0


# Return the rate of the topic.
func get_hz() -> float:
	return _hz
