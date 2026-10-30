//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.

import mqtt.*;
MQTTClient client_mqtt;

String[] config_lines;

String password, password_attempt = "", password_crypted = "";

boolean password_ok = false;


boolean manager_online = false;
int manager_check;
ArrayList<Chart_CO2> myCharts;

int green_limit = 600, yellow_limit = 800;

int disconnection_time = 10000; //10 seconds. Time to wait for a data from a sensor before disconnecting it

int now, last_check;

String broker_IP;

void setup()
{
  size(800,600);
  surface.setResizable(true);
  myCharts = new ArrayList<Chart_CO2>();
  
  config_lines = loadStrings("config.txt");
  broker_IP = config_lines[1];
  password = config_lines[3];
  
  
  init_mqtt();
  
  client_mqtt.publish("New_user","Hello");
  
  frameRate(10);
  delay(100);
  
}

void draw()
{
  background(255);
  now = millis();
  
  if(!password_ok)
  {
    check_password();
  }
  else
  {
    check_ventilation();
    draw_interface();
    if(show_chart>=0 && show_chart<myCharts.size()) 
    {
      myCharts.get(show_chart).draw_chartCO2(); 
      draw_vent();
    }
    
    if( now-last_check >= 12000 && myCharts.size()>0)
    {
      check_sensorsNmanager();
      last_check = now;
    }
  }
}
