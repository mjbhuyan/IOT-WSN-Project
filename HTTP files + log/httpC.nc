#include "http.h"
#include "Timer.h"

module httpC {

//interface that we use
  uses {
	interface Boot; //always here and it's the starting point
    	//interfaces for communications
	interface AMPacket; 
	interface Packet;
	interface PacketAcknowledgements;
    	interface AMSend;
	//for turn on the radio
    	interface SplitControl;
    	interface Receive;
    	interface Timer<TMilli> as MilliTimer;
	//used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;
 
 

  task void sendReq();
  task void getResp();
  
  
    //Declaration of the different variables used
 
  uint8_t messageID = 1;
  uint8_t index = 0;
  //my_msg_t;
  
  
  //***************** Task send request ********************//
  task void sendReq() {
        
        int i;
	//prepare a msg
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = REQ;
	mess->address_id = TOS_NODE_ID;
	mess->msg_id = counter++;
	    
	{
	dbg("radio_send", "Try to send a request at time %s \n", sim_time_string());
	call PacketAcknowledgements.requestAck( &packet );
	
	if(TOS_NODE_ID ==1) {
	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){		
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	 // dbg_clear("radio_pack", "\t\t Topic: %hhu \n", mess->topic);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	  if ( mess->topic == 1 ){
	  dbg_clear("radio_pack", "\t\t topic: temperature \n ", mess->topic);
	  }
	   if ( mess->topic == 2 ){
	  dbg_clear("radio_pack", "\t\t topic: humidity \n ", mess->topic);
	  }
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");
      
      }
      		
   }
 }        
 }

  //****************** Task send response *****************//
  
  task void getResp() {
	call Read.read();
  }
  

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start(); //turn on the radio
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
      
    if(err == SUCCESS) {

	dbg("radio","Radio on!\n");
	//node 1 transmit a request to node 2 n 3
	if ( TOS_NODE_ID == 1 ) {
	  dbg("role","I'm node 1: start sending periodical request\n");
	  call MilliTimer.startPeriodic( 1800 );
	}
      
    }
    else{
	//dbg for error
	call SplitControl.start();
    }

  }
  
  event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	post sendReq();
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	dbg("radio_send", "Packet sent...");

	//check if ack is received
	
	if ( call PacketAcknowledgements.wasAcked( buf ) ) {
	  dbg_clear("radio_ack", "and ack received");
	  call MilliTimer.stop();
	}
	 else {
	  dbg_clear("radio_ack", "but ack was not received");
	  post sendReq();
	} 
	 }
	dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
       

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

	my_msg_t* mess=(my_msg_t*)payload;
	rec_id = mess->msg_id;
	
	dbg("radio_rec","Message received at time %s \n", sim_time_string());
	dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ) );
	dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
	dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
	dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type( buf ) );
	dbg_clear("radio_pack","\t\t Payload \n" );
	dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
	//dbg_clear("radio_pack", "\t\t Topic: %hhu \n", mess->topic);
	dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	if ( mess->topic == 1 ){
	  dbg_clear("radio_pack", "\t\t topic: temperature \n ", mess->topic);
	  }
	   if ( mess->topic == 2 ){
	  dbg_clear("radio_pack", "\t\t topic: humidity \n ", mess->topic);
	  }
	dbg_clear("radio_rec", "\n ");
	dbg_clear("radio_pack","\n");
	

	if (( mess->msg_type == REQ )) {
		post getResp();
	}
            
    return buf;

  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = RESP;
	mess->msg_id = rec_id;
	mess->value = data;
	mess->address_id = TOS_NODE_ID;
	
	if(TOS_NODE_ID == 2){mess->topic = TEMPERATURE; } 
	else {if(TOS_NODE_ID == 3){mess->topic = HUMIDITY;}} 
	
	
	  
	dbg("radio_send", "Try to send a response to node 1 at time %s \n", sim_time_string());
	call PacketAcknowledgements.requestAck( &packet );
	if(call AMSend.send(1,&packet,sizeof(my_msg_t)) == SUCCESS){
		
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  //dbg_clear("radio_pack", "\t\t topic: %hhu \n ", mess->topic);
	  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	  if ( mess->topic == 1 ){
	  dbg_clear("radio_pack", "\t\t topic: temperature \n ", mess->topic);
	  }
	   if ( mess->topic == 2 ){
	  dbg_clear("radio_pack", "\t\t topic: humidity \n ", mess->topic);
	  }
	  
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");

        }

  }

}

