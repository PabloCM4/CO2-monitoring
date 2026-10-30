//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.

import mqtt.*;
MQTTClient client_mqtt;

String[] config_lines;

String password, password_attempt = "", password_crypted = "";

boolean password_ok = false;

boolean first_manager = false, end_program = false;

ArrayList<Chart_CO2> myCharts;

int green_limit = 600, yellow_limit = 800;

int disconnection_time = 10000; //10 seconds. Time to wait for a data from a sensor before disconnecting it

int now, last_check, start_program;

String broker_IP;

void setup()
{
  size(800,600);
  surface.setResizable(true);
  myCharts = new ArrayList<Chart_CO2>();
  
  config_lines = loadStrings("config.txt");
  broker_IP = config_lines[1];
  password = config_lines[3];
  
   
  client_mqtt = new MQTTClient(this);
  client_mqtt.connect(broker_IP);
  
  client_mqtt.subscribe("Manager");
   
  frameRate(10);
  now = millis();
  
  start_program = now;
  last_check = now;
  
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
  else if (end_program)
  {
    text("Another system manager found", width*0.5, height*0.515);
    if ((now - start_program) > (15 * 1000) ) exit();
  }
  else if (!first_manager)
  {
    if ((now - start_program) > (7 * 1000) ) first_manager = true;
    text("Checking for another system manager", width*0.5, height*0.515);
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
    
    if( now - last_check >= 5 * 1000 )
    {
      check_sensorsNusers();
      last_check = now;
    }
  }
} 
