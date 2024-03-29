#ifndef MQTT_H
#define MQTT_H

//Definition of the maximum number of nodes
//allows to have a flexible behaviour
#define MAX_NB_NODES 6

//Definition of the message type identifiers
#define CONNECT 1
#define SUBSCRIBE 2
#define PUBLISH 3
#define FORWARD 4

//Definition of the topic identifiers
#define TEMPERATURE 1
#define HUMIDITY 2


//Definition of the QOS identifiers
#define QOS_LOW 0
#define QOS_HIGH 1

//Connect message structure
typedef nx_struct my_msg_connect {
	nx_uint8_t type;
} my_msg_connect_t;

//Subscribe message structure
typedef nx_struct my_msg_subscribe {
	nx_uint8_t type;
	nx_uint8_t topic[3];
	nx_int8_t qos[3];
} my_msg_subscribe_t;

//Publish message structure
typedef nx_struct my_msg_publish {
	nx_uint8_t type;
	nx_uint16_t value;
	nx_uint8_t msgId;
	nx_uint8_t topic;
	nx_uint8_t qos;
} my_msg_publish_t;

//Forward message structure
typedef nx_struct my_msg_forward {
	nx_uint8_t type; 
	nx_uint16_t value;
	nx_uint8_t topic;
	nx_uint8_t source;
	nx_uint8_t qos;
} my_msg_forward_t;



//Array used by the MQTT broker indicating the connected nodes
uint8_t connectedNodes[MAX_NB_NODES];

//Array used by the MQTT broker to store the subscriptions (One row per topic, One column per node)
int8_t subscriptions[MAX_NB_NODES][2];

//Array used by the MQTT broker to store the last ID of the message published,
//it is useful to avoid forwarding several times the same measurement
int8_t publishedMsgID[MAX_NB_NODES];

//Array used by the MQTT broker when receiving a publish message to know to 
//which node it has to forward packet, basically a copy of a row of subscriptions
//that is updated along the forwarding procedure
int8_t nodesToForward[MAX_NB_NODES];


enum{
AM_MY_MSG = 6,
};

#endif
