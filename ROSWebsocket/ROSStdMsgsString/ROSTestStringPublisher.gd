# Publisher for the '/test_string' topic.
# The message type is 'std_msgs/String'.
extends ROSPublisher
class_name ROSTestStringPublisher


func _ready():
	_topic = "/test_string"
	_msg_type = "std_msgs/String"
	_init_msg()
	initiate_connection()


func _init_msg():
	_msg["data"] = ""


# Set the data.
func set_data(data: String):
	_msg["data"] = data
