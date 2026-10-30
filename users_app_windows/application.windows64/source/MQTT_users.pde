  //BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
/*
This function set up the mqtt protocol, preparing to receive new connections from the sensors
*/
final int NOTHING = 0, CHARTS = 1, LIMITS = 2;
int expecting_update = NOTHING, updating_chart = -1, updating_data = 0;

void init_mqtt()
{
  client_mqtt = new MQTTClient(this);
  client_mqtt.connect(broker_IP);
  
  client_mqtt.subscribe("New_sensor");
  client_mqtt.subscribe("Users");
  client_mqtt.subscribe("Manager");
}
/*
Called when the program receive a mqtt message
Check the topic to see if it is a new connection. If so, subscribe to a topic with the name of the sensor to listen to data from him
In case it is a value from a sensor it is listening: if it is a '0' it means the sensor is going offline, so we stop listening to it,
else it is CO2 data so we store it.
*/
void messageReceived(String topic, byte[] payload) {
  
  String msg = new String(payload);
  if( topic.equals("Manager") )
  {
    manager_online = true;
    manager_check = millis();
  }
  else if ( topic.equals("New_sensor") && manager_online )
  {
    boolean not_repeated = true;
    for(int i = 0; i < myCharts.size(); i++)
    {
      if(myCharts.get(i).unique_address.equals(msg)) not_repeated = false;
    }
    if(not_repeated)
    {
      myCharts.add(new Chart_CO2(msg));
      client_mqtt.subscribe(msg);
      if(myCharts.size() == 1)
      {
        show_chart = 0;
        last_check = millis();
      }
    }
  }
  else if ( topic.equals("Users") )
  {
    //CHECK IF WE ARE CHANGING THE EXPECTING UPDATE
    if( msg.equals("*") ) 
    { 
      expecting_update = CHARTS;
      updating_chart = -1; 
      updating_data = 0;
    }
    else if( msg.equals("**")) 
    {
      expecting_update = LIMITS;
      updating_data = 0;
    }
    else if( msg.equals("***")) expecting_update = NOTHING;
    
    //IF WE ARE EXPECTING AN UPDATE OF THE CHARTS
    else if(expecting_update==CHARTS)
    {
      if( msg.equals("!") ) {updating_chart++; updating_data = 0;}
      else
      {
        switch (updating_data)
        {
          case 0: //UPDATING UNIQUE ADDRESS
            if(updating_data >= myCharts.size())
            {
              myCharts.add(new Chart_CO2(msg));
              client_mqtt.subscribe(msg);
              if(myCharts.size() == 1)
              {
                show_chart = 0;
                last_check = millis();
              }
            }
            else if(!msg.equals(myCharts.get(updating_chart).unique_address)) //IF NOT THE SAME, CHANGE SUBSCRIPTION AND CHANGE UNIQUE ADDRESS
            {
               client_mqtt.unsubscribe(myCharts.get(updating_chart).unique_address);
               client_mqtt.subscribe(msg);
               myCharts.get(updating_chart).unique_address = msg;
            }
            updating_data = 1;
            break;
            
          case 1://UPDATING NAME
            myCharts.get(updating_chart).name = msg;
            updating_data = 2;
            break;
          default: break;
              
        }
      }
    }//EXPECTING UPDATE CHARTS
    
    else if(expecting_update==LIMITS)
    {
      if(updating_data == 0) {green_limit = int(msg); updating_data = 1;}
      else if(updating_data == 1) {yellow_limit = int(msg); updating_data = 2;}
    }
    
  }//TOPIC USERS
  
  else //if not a new sensor or updating users
  {
    for(int i=0;i<myCharts.size();i++) //check if it was data from a sensor
    {
      if(myCharts.get(i).unique_address.equals(topic))
      {
        int value = int(msg);
        
        if(value==-1)  //if the data is a -1, it means the sensor want to disconnect
        {
          client_mqtt.unsubscribe(topic);
          myCharts.remove(i);
          if( show_chart >= myCharts.size()) show_chart = myCharts.size() -1; 
        }
        else if(value==0) //if the data is a 0, it means the MHZ19 CO2 sensor is failing
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
