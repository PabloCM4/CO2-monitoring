import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import mqtt.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class main_manager extends PApplet {

//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.


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

public void setup()
{
  
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

public void draw()
{
  background(255);
  now = millis();
  
  if(!password_ok)
  {
    check_password();
  }
  else if (end_program)
  {
    text("Another system manager found", width*0.5f, height*0.515f);
    if ((now - start_program) > (15 * 1000) ) exit();
  }
  else if (!first_manager)
  {
    if ((now - start_program) > (7 * 1000) ) first_manager = true;
    text("Checking for another system manager", width*0.5f, height*0.515f);
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
//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
/*
This function set up the mqtt protocol, preparing to receive new connections from the sensors
*/
public void init_mqtt()
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
public void messageReceived(String topic, byte[] payload) {
  
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
        int value = PApplet.parseInt(msg);
        
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


public void update_users()
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
//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
int vent_color = color(30,240,50);

public void check_password()
{
  if(writing_status == writing_password)
    {
      fill(255);
      strokeWeight(3);
      rect(width*0.4f,height*0.45f,width*0.2f,height*0.1f);
      
      fill(0);
      textAlign(CENTER);
      textSize(height*0.03f);
      text("Insert password:", width*0.5f, height*0.4f);
      text(password_crypted, width*0.5f, height*0.515f);
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
public void check_ventilation()
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
public void check_sensorsNusers()
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
//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.

//CLASS CHART

int max_data = 30;

int[] disp_numb = {400, 650, 900, 1150, 1400, 1650, 1900, 2150, 2400, 2650};

class Chart_CO2
{
  float[] data = new float[max_data];
  int pointer_data;
  String name;
  String unique_address;
  int last_data_sent;
  int CO2;
  int color_vent;
  boolean MHZ19_failing;
  //Constructor
  Chart_CO2(String address_chart)
  {
    unique_address = address_chart;
    name = unique_address;
    pointer_data = 0;
    last_data_sent = millis();
    CO2 = 400;
    MHZ19_failing = false;
    
    for(int i=0;i<max_data;i++)
    {
      data[i] = 0;
    }
  }//Constructor
  //****************
  //Draw the chart
  public void draw_chartCO2()
  {
    float posX=width*0.2f, posY=height*0.2f;
    float sizeX=width*0.4f, sizeY=height*0.5f;
    
    //Background of the chart
    fill(255);
    stroke(0);
    strokeWeight(2);
    rect(posX, posY, sizeX, sizeY);
    
    //Abscissa line
    stroke(0);
    strokeWeight(3);
    line(posX+sizeX*0.1f, posY+sizeY*0.9f, posX+sizeX*0.9f, posY+sizeY*0.9f);
    
    //Ordinate line
    stroke(0);
    strokeWeight(3);
    line(posX+sizeX*0.1f, posY+sizeY*0.1f, posX+sizeX*0.1f, posY+sizeY*0.9f);
    
    //Indicators
    
          //ordinate indicators
    for(int i=0; i<10; i++)
    {
      stroke(0);
      strokeWeight(1);
      line(posX+sizeX*0.07f, posY+sizeY*0.1f+i*sizeY*0.0888f, posX+sizeX*0.13f, posY+sizeY*0.1f+i*sizeY*0.0888f);
    
      textAlign(CENTER);
      textSize(sizeX*0.025f);
      fill(0);
      text(disp_numb[i], posX+sizeX*0.04f,posY+sizeY*0.915f-i*sizeY*0.0888f);
    }
          //abscissa indicators
    for(int i=0; i<max_data; i++)
    {
      float pos_indX = posX+sizeX*(0.1f+(0.8f/(max_data-1)*(i)));
      stroke(0);
      strokeWeight(1);
      line(pos_indX, posY+sizeY*0.87f, pos_indX, posY+sizeY*0.93f);
    
      if(i%5==0 || i==max_data-1)
      {
        textAlign(CENTER);
        textSize(sizeX*0.02f);
        fill(0);
        text(i, pos_indX,posY+sizeY*0.96f);
        
      }
    }//abscissa indicators
   
    //DATA
    int draw_value = pointer_data;
    float act_posY, last_posY=299,act_posX, last_posX=299,act_value,pos=0;
    for(int i=0; i<max_data; i++)
    {
      act_value = data[draw_value];
      if(act_value >= 400)
      {
        if(act_value>2650) act_value=2650;
        //act_posY = posY + sizeY*(1-(0.1+((act_value-400)/1800)*0.8));
         act_posY = posY + sizeY*(1-(0.1f+((act_value-400)/2250)*0.8f));
        act_posX = posX+sizeX*(0.1f+(0.8f/(max_data-1)*(pos)));
        fill(200,50,50);
        strokeWeight(1);
        circle(act_posX,act_posY,sizeY*0.02f);
        
        if(pos>0) line(act_posX, act_posY, last_posX, last_posY);
        
        last_posY = act_posY;
        last_posX = act_posX;
        pos++;
      }
      draw_value++;
      if(draw_value >= max_data) draw_value=0;
    }//DATA
         
    //Chart legend
    fill(0);
    textSize(sizeX*0.018f);
    text("TIME(min)", posX+sizeX*0.95f, posY+sizeY*0.91f);
    text("CO2(PPM)", posX+sizeX*0.1f, posY+sizeY*0.06f);
 
  }//DRAW_CHARTCO2
  //***************
  
  public void new_value(int value)
  {
    data[pointer_data] = value;
    CO2 = value;
    pointer_data++;
    if(pointer_data >= max_data) pointer_data = 0;
    
    last_data_sent = millis();
  }
}//CLASS CHART_CO2
//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
int interface_start = 0;
int change_name =-1;


final int writing_name = 0, writing_green_limit = 1, writing_yellow_limit = 2, writing_password = 3, writing_idle = -1;
int writing_status = writing_idle;

int show_chart=-1;
public void draw_interface()
{
  strokeWeight(3);
  stroke(0);
  line(width*0.75f,0,width*0.75f,height);
  
  if(myCharts.size()<=10) interface_start=0;
  
  for(int i=interface_start; i<myCharts.size();i++)
  {
    if(i-interface_start>=10) break;
    else if(show_chart==i) fill(155);
    else fill(myCharts.get(i).color_vent);
    strokeWeight(3);
    rect(width*0.75f,height*0.1f*(i-interface_start),width*0.25f,height*0.1f);
    
    if(change_name==i)
    {
      fill(255);
      strokeWeight(1);
      rect(width*0.78f,height*0.025f+height*0.1f*(i-interface_start),width*0.19f,height*0.05f);
    }
    
    fill(0);
    textSize(height*0.04f);
    textAlign(CENTER);
    text(myCharts.get(i).name,width*0.875f,height*0.065f+height*0.1f*(i-interface_start));
  }
  
  strokeWeight(2);
  fill(155,255,155);
  rect(width*0.2f, height*0.1f, width*0.07f,height*0.05f,5);
  if(writing_status == writing_green_limit)
  {
    fill(255);
    strokeWeight(1);
    rect(width*0.205f, height*0.105f, width*0.06f,height*0.04f);
  }
  
  strokeWeight(2);
  fill (255,255,0);
  rect(width*0.5f, height*0.1f, width*0.07f,height*0.05f,5);
  if(writing_status == writing_yellow_limit)
  {
    strokeWeight(1);
    fill(255);
    rect(width*0.505f, height*0.105f, width*0.06f,height*0.04f);
  }
  strokeWeight(2);
  fill(0);
  textAlign(CENTER);
  
  textSize(height*0.035f);
  text(green_limit,width*0.237f,height*0.137f);
  textSize(height*0.03f);
  text("GREEN LIMIT",width*0.237f,height*0.09f);

  textSize(height*0.035f);
  text(yellow_limit,width*0.537f,height*0.137f);
  textSize(height*0.03f);
  text("YELLOW LIMIT",width*0.537f,height*0.09f);
}

public void draw_vent()
{
  fill(myCharts.get(show_chart).color_vent);
  strokeWeight(3);
  rect(0.3f*width,0.8f*height,0.2f*width,0.1f*height);
  
  fill(0);
  textSize(width*0.02f);
  if(myCharts.get(show_chart).MHZ19_failing) text("FAILURE",0.4f*width,0.865f*height);
  else text(PApplet.parseInt(myCharts.get(show_chart).CO2)+" PPM",0.4f*width,0.865f*height);
}

public void mousePressed()
{
  if(writing_status == writing_idle)
  {
    //if click in selector menu
    if( (mouseX>=width*0.75f) && (mouseX<=width) &&
        (mouseY>=0)          && (mouseY<=height)  )
    {
      for(int i=0;( (i<myCharts.size()) && (i<10) );i++)
      {
        if((mouseY>=height*0.1f*i) && (mouseY<=0.1f*height+height*0.1f*i))
        {
          if(mouseButton == LEFT)
          {
            show_chart = i+interface_start;
          }
          else if(mouseButton == RIGHT)
          {
            change_name = i+interface_start;
            writing_status = writing_name;
          }
          break;
        }//if correct area clicked
      }//for
    }//if click in selector menu
    //if click in limits
    else if( (mouseX>=width*0.2f) && (mouseX<=width*0.27f) &&
             (mouseY>=0.1f)          && (mouseY<=height*0.15f) &&
             mouseButton == RIGHT )
    {
      green_limit = 0;
      writing_status = writing_green_limit;
    }
    else if( (mouseX>=width*0.5f) && (mouseX<=width*0.57f) &&
             (mouseY>=0.1f)          && (mouseY<=height*0.15f) &&
             mouseButton == RIGHT  )
    {
      yellow_limit = 0;
      writing_status = writing_yellow_limit;
    }//if click in limits
  }//if block while writting
}// mouseClicked




public void mouseWheel(MouseEvent event)
{
  if(    (writing_status == writing_idle) &&
         (mouseX>=width*0.75f) && (mouseX<=width) &&
         (mouseY>=0)          && (mouseY<=height) &&
         (myCharts.size()>10)                )
  {
    float moves = event.getCount();
    interface_start += moves;
    if(interface_start<0) interface_start=0;
    else if(interface_start>(myCharts.size()-10)) interface_start = (myCharts.size()-10);
  }
}




public void keyPressed()
{
  switch(writing_status)
  {
  case writing_name:
    //String text_aux = myCharts.get(change_name).name;
    if(key == BACKSPACE && myCharts.get(change_name).name.length()>0 )
    {
      myCharts.get(change_name).name = myCharts.get(change_name).name.substring(0,myCharts.get(change_name).name.length()-1);
    }
    else if(key>=47 && key<=122 && myCharts.get(change_name).name.length()<9)
    {
      myCharts.get(change_name).name = myCharts.get(change_name).name+key;
    }
    else if(key == ENTER)
    {
      writing_status = writing_idle;
      change_name = -1;
      update_users();
    }
    
  break;
  
  
  case writing_green_limit:
 
    if(key>=48 && key<=57)
    {
      green_limit = green_limit*10 + PApplet.parseInt(key)-48;
    }
    
    if(key<48 || key>57 || green_limit>999)
    {
      if(green_limit >= yellow_limit) green_limit = yellow_limit-1;
      writing_status = writing_idle;
      update_users();
    }
  
  break;
 
  case writing_yellow_limit:
  
    if(key>=48 && key<=57)
    {
      yellow_limit = yellow_limit*10 + PApplet.parseInt(key)-48;
    }
    if(key<48 || key>57 || yellow_limit>999)
    {
      if(yellow_limit <= green_limit) yellow_limit = green_limit+1;
      writing_status = writing_idle;
      update_users();
    }
  
  break;
  
  case writing_password:
  
    if(key == ENTER)
    {
      writing_status = writing_idle;
    }
    else if(key >= 48 && key <=122 && password_attempt.length()<=10)
    {
      password_attempt = password_attempt+key;
      password_crypted = password_crypted+'*';
    }
    
  
  break;
  
  default:
  break;
  }
}
  public void settings() {  size(800,600); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "main_manager" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
