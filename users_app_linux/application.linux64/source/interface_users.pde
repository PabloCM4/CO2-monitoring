//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
int interface_start = 0;
final int writing_password = 3, writing_idle = -1;
int writing_status = writing_idle;

int show_chart=-1;

//DRAW THE INTERFACE
void draw_interface()
{
  strokeWeight(3);
  stroke(0);
  line(width*0.75,0,width*0.75,height);
  
  if(myCharts.size()<=10) interface_start=0;
  
  //drawing selector menu
  for(int i=interface_start; ( (i<myCharts.size()) && (i-interface_start<10) );i++)
  {
    if(show_chart==i) fill(155); //if sensor displayed, color is grey
    else fill(myCharts.get(i).color_vent); //if not displayed, color is the green, yellow or red, depending the CO2
    strokeWeight(3);
    rect(width*0.75,height*0.1*(i-interface_start),width*0.25,height*0.1);
    
    fill(0);
    textSize(height*0.04);
    textAlign(CENTER);
    text(myCharts.get(i).name,width*0.875,height*0.065+height*0.1*(i-interface_start));
  }
  
  //drawing green limit rectangle
  strokeWeight(2);
  fill(155,255,155);
  rect(width*0.2, height*0.1, width*0.07,height*0.05,5);
  
  //drawing yellow limit rectanglee
  strokeWeight(2);
  fill (255,255,0);
  rect(width*0.5, height*0.1, width*0.07,height*0.05,5);

  //writing limits text
  strokeWeight(2);
  fill(0);
  textAlign(CENTER);
  
  textSize(height*0.035);
  text(green_limit,width*0.237,height*0.137);
  textSize(height*0.03);
  text("GREEN LIMIT",width*0.237,height*0.09);

  textSize(height*0.035);
  text(yellow_limit,width*0.537,height*0.137);
  textSize(height*0.03);
  text("YELLOW LIMIT",width*0.537,height*0.09);
}


//DRAW THE WINDOW WITH THE LAST DATA OF THE DRAWN CHART
void draw_vent()
{
  fill(myCharts.get(show_chart).color_vent);
  strokeWeight(3);
  rect(0.3*width,0.8*height,0.2*width,0.1*height);
  
  fill(0);
  textSize(width*0.02);
  if(myCharts.get(show_chart).MHZ19_failing) text("FAILURE",0.4*width,0.865*height);
  else text(int(myCharts.get(show_chart).CO2)+" PPM",0.4*width,0.865*height);
}


void mousePressed()
{
  if( (mouseX>=width*0.75) && (mouseX<=width)   &&
      (mouseY>=0)          && (mouseY<=height)  &&
       mouseButton == LEFT                        )
  {
    for(int i=0;( (i<myCharts.size()) && (i<10) );i++)
    {
      if((mouseY>=height*0.1*i) && (mouseY<=0.1*height+height*0.1*i))
      {
        show_chart = i+interface_start;
        break;
      }//if specific
    }//for
  }//if right part
}// mouseClicked

void mouseWheel(MouseEvent event)
{
  if(writing_status != writing_password)
  {
    if( (mouseX>=width*0.75) && (mouseX<=width) &&
        (mouseY>=0)          && (mouseY<=height) &&
        (myCharts.size()>10)                          )
    {
      float moves = event.getCount();
      interface_start += moves;
      if(interface_start<0) interface_start=0;
      else if(interface_start>(myCharts.size()-10)) interface_start = (myCharts.size()-10);
    }//if general
  }
}

void keyPressed()
{
  switch(writing_status)
  {
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
