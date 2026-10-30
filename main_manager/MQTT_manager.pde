//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
/*
This function set up the mqtt protocol, preparing to receive new connections from the sensors
*/
void init_mqtt()
{ 
  client_mqtt.unsubscribe("Manager");
  client_mqtt.subscribe("New_sensor");
  client_mqtt.subscribe("New_user");
}
/*
Called when the program receive a mqtt message
Check the topic to see if it is a new connection. If so, subscribe to a topic with the name of the sensor to listen to data from him
In case it is a value from a sensor it is listening: if it is a '0' it means the sensor is going offline, so we stop listening to it,
else it is CO2 data so we store it.
*/
void messageReceived(String topic, byte[] payload) {
  
  String msg = new String(payload);
  
  if ( topic.equals("Manager") )
  {
    end_program = true;
  }
  if ( topic.equals("New_sensor") )
  {
    boolean not_repeated = true;
    for(int i = 0; i < myCharts.size(); i++)
    {
      if(myCharts.get(i).unique_address.equals(msg)) not_repeated = false;
    }
    if(not_repeated)
    {
      myCharts.add(new Chart_CO2(msg));
      client_mqtt.publish(msg,"Listening");
      client_mqtt.subscribe(msg);
      if(myCharts.size() == 1)
      {
        show_chart = 0;
        last_check = millis();
      }
    }
  }
  else if(topic.equals("New_user"))
  {
    client_mqtt.publish("Manager","ON");
    update_users();
  }
  else //if not a new sensor or user
  {
    for(int i=0;i<myCharts.size();i++) //check if it was data from a sensor
    {
      if(myCharts.get(i).unique_address.equals(topic))
      {
        int value = int(msg);
        
        if(value==-1)  //if the data is a -1, it means the sensor want to disconnect
        {
          client_mqtt.unsubscribe(topic);
          client_mqtt.publish(topic,"Disconnected");
          myCharts.remove(i);
          if( show_chart >= myCharts.size()) show_chart = myCharts.size() - 1; 
          if(change_name >= i && writing_status==writing_name) 
          {
            change_name = -1;
            writing_status = writing_idle;
          }
        }
        else if(value==0) //if the data is a 0, the MH-Z19B sensor is failing
        {
          myCharts.get(i).MHZ19_failing = true;
        }
        else
        {
          myCharts.get(i).MHZ19_failing = false;
          myCharts.get(i).new_value(value);
          myCharts.get(i).last_data_sent = millis();
        }
        break;
      }
    }//for
  }//else of not new connection
  
}// void messageReceived()


void update_users()
{
  
  client_mqtt.publish("Users","*");
  for(int i=0;i<myCharts.size();i++)
  {
    client_mqtt.publish("Users","!");
    client_mqtt.publish("Users",myCharts.get(i).unique_address);
    client_mqtt.publish("Users",myCharts.get(i).name);
  }
  
  client_mqtt.publish("Users","**");
   
  client_mqtt.publish("Users",str(green_limit));
  
  client_mqtt.publish("Users",str(yellow_limit));
  
  client_mqtt.publish("Users","***");
  
}
