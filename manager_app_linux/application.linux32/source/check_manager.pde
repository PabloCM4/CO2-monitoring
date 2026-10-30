//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
color vent_color = color(30,240,50);

void check_password()
{
  if(writing_status == writing_password)
    {
      fill(255);
      strokeWeight(3);
      rect(width*0.4,height*0.45,width*0.2,height*0.1);
      
      fill(0);
      textAlign(CENTER);
      textSize(height*0.03);
      text("Insert password:", width*0.5, height*0.4);
      text(password_crypted, width*0.5, height*0.515);
    }
    else
    {
      if(password.equals(password_attempt))
      {
        password_ok = true;
        init_mqtt();
      }
      else
      {
        password_crypted = "";
        password_attempt = "";
        writing_status = writing_password;
      }
    }
}

/*
Check if the ventilation of all sensor connected is ok and change the color depending on it.
*/
void check_ventilation()
{
  for(int i=0;i<myCharts.size();i++)
  {
    if(myCharts.get(i).MHZ19_failing)              myCharts.get(i).color_vent = color(155,155,255);
    else if( myCharts.get(i).CO2 <= green_limit )   myCharts.get(i).color_vent = color(155,255,155);
    else if( myCharts.get(i).CO2 <= yellow_limit )  myCharts.get(i).color_vent = color(255,255,0);
    else                                           myCharts.get(i).color_vent = color(255,100,100);
  }
}

/*
This function checks if every sensor is properly connected.
First check if the sensor is sending data, ifnot disconnect it.
Then send to a topic the name of every sensor which this program is listening so they know it.
Moreover, it send a message to the topic "Manager" to let the Users know that the Manager is online.
*/
void check_sensorsNusers()
{
  for(int i=0;i<myCharts.size();i++)
  {
    if(now - myCharts.get(i).last_data_sent >= disconnection_time)
    {
      client_mqtt.unsubscribe(myCharts.get(i).unique_address);
      myCharts.remove(i);
      if( show_chart >= myCharts.size()) show_chart = myCharts.size() -1; 
      if(change_name >= i && writing_status==writing_name) 
      {
        change_name = -1;
        writing_status = writing_idle;
      }
    }
    else
    {
      client_mqtt.publish("Check_Sensors",myCharts.get(i).unique_address);
    } 
  } 
  client_mqtt.publish("Manager","ON");
}
