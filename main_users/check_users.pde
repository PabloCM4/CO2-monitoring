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
    if (myCharts.get(i).MHZ19_failing) myCharts.get(i).color_vent = color(155,155,255); //if sensor failing, blue
    else if( myCharts.get(i).CO2 <= green_limit )       myCharts.get(i).color_vent = color(155,255,155); //if inside green limit, green
    else if( myCharts.get(i).CO2 <= yellow_limit ) myCharts.get(i).color_vent = color(255,255,0); // if inside yellow limit, yellow
    else                                          myCharts.get(i).color_vent = color(255,100,100);//else red
  }
  
  
}



void check_sensorsNmanager()
{
  //int current_millis = millis();
  for(int i=0;i<myCharts.size();i++)
  {
    if(now - myCharts.get(i).last_data_sent >= disconnection_time)
    {
      
      client_mqtt.unsubscribe(myCharts.get(i).unique_address);
      myCharts.remove(i);
      
      /*if(myCharts.size() <= 0) show_chart = -1;
      else */if( show_chart >= myCharts.size()) show_chart = myCharts.size() -1; 
    }
  }
  
  if(manager_online)
  {
    if(now - manager_check >= disconnection_time) manager_online = false;
  }
}
