# Publisher for the '/test_topic' topic.
# The message type is 'test_msgs/Test'.
extends ROSPublisher
class_name ROSTestTopicPublisher


func _ready():
	_topic = "/test_topic"
	_msg_type = "test_msgs/Test"
	_init_msg()
	initiate_connection()


func _init_msg():
	_msg["field_int"] = 0
	_msg["field_array"] = []
	_msg["field_string"] = ""


# Set the data.
func set_data(field_int: int, field_array: Array, field_string: String):
	_msg["field_int"] = field_int
	_msg["field_array"] = field_array
	_msg["field_string"] = field_string
