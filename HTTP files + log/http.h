
#ifndef HTTP_H
#define HTTP_H

//Definition of the maximum number of nodes
//allows to have a flexible behaviour
#define MAX_TOS_NODE 3

//Definition of the message type identifiers
#define REQ 1
#define RESP 2

//Definition of the topic identifiers
#define TEMPERATURE 1
#define HUMIDITY 2


//Response message structure
typedef nx_struct my_msg_response {
	nx_uint8_t msg_type; 
	nx_uint16_t value;
	nx_uint16_t address_id;
	nx_uint8_t msg_id;
	nx_uint8_t topic;
} my_msg_t;


//int8_t responseMsgID[TOS_NODES];


enum{
AM_MY_MSG = 6,
};

#endif

