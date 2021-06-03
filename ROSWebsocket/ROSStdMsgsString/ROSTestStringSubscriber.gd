# Subscriber for the '/test_string' topic.
# The message type is 'std_msgs/String'.
extends ROSSubscriber
class_name ROSTestStringSubscriber

var data: String = ""


func _ready():
	_topic = "/test_string"
	_msg_type = "std_msgs/String"
	initiate_connection()


# Receive the message (as Dictionary) with a bool parameter 
# [is_called_from_child] that indicates if this function is 
# called inside a child of [ROSSubscriber] or not.
func receive_msg(msg: Dictionary, is_called_from_child: bool = false):
	data = msg["data"]
	.receive_msg(msg,true)
