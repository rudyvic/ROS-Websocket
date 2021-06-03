# Subscriber for the '/test_topic' topic.
# The message type is 'test_msgs/Test'.
extends ROSSubscriber
class_name ROSTestTopicSubscriber

var field_int: int = 0
var field_array: Array = []
var field_string: String = ""


func _ready():
	_topic = "/test_topic"
	_msg_type = "test_msgs/Test"
	initiate_connection()


# Receive the message (as Dictionary) with a bool parameter 
# [is_called_from_child] that indicates if this function is 
# called inside a child of [ROSSubscriber] or not.
func receive_msg(msg: Dictionary, is_called_from_child: bool = false):
	field_int = msg["field_int"]
	field_array = msg["field_array"]
	field_string = msg["field_string"]
	.receive_msg(msg,true)
