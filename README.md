# ROS Websocket interface for Godot

This repository contains some Godot nodes to interact with a ROS Websocket. It is possible to publish messages on topics, subscribe to topics, call services and read the services responses.

> :warning: This works with Godot 3.x (no with Godot 4.x).


## INSTALLATION

In order to use it, you must install ROS:
```
sudo apt-get install ros-<rosdistro>-rosbridge-server
```

## USAGE
To launch the websocket:
```
roslaunch rosbridge_server rosbridge_websocket.launch
```
The websocket can be launched at anytime, it is not mandatory to launch it before Godot.

List and explanation of the Godot files:
- <b>ROSWebsocket:</b> the node that handles the connection with the websocket. It provides usefull signals and methods to know the state of the connection, the list of the subscribed nodes and more. It must be set as an <b>Autoload</b> node in your project.
- <b>ROSPublisher:</b> you can extend this node to build custom publishers (see <i>ROSTestTopicPublisher</i> for an example).
- <b>ROSSubscriber:</b> you can extend this node to build custom Subscribers (see <i>ROSTestTopicSubscriber</i> for an example).
- <b>Main:</b> example node to test if the setup is working. You can set the websocket url, and then you can publish and receive <i>std_msgs/String</i> messages on the <i>/test_string</i> topic.
- <b>ROSStdMsgsString:</b> it is composed by <i>ROSTestStringSubscriber</i> and <i>ROSTestStringPublisher</i>. The topic is <i>/test_string</i> with the message <i>std_msgs/String</i>. It is a simple example on how to implement basic publishers and subscribers.
- <b>ROSTestTopic:</b> it is composed by <i>ROSTestTopicSubscriber</i> and <i>ROSTestTopicPublisher</i>. The topic is <i>/test_topic</i> with a fake example message <i>test_msgs/Test</i>. It is a more complex example on how to implement publishers and subscribers on complex messages. Remember that it doesn't work if you don't have the <i>test_msgs/Test</i> message installed in ROS, but this nodes are meant for example-purpose only.
