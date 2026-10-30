//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.
int interface_start = 0;
int change_name =-1;


final int writing_name = 0, writing_green_limit = 1, writing_yellow_limit = 2, writing_password = 3, writing_idle = -1;
int writing_status = writing_idle;

int show_chart=-1;
void draw_interface()
{
  strokeWeight(3);
  stroke(0);
  line(width*0.75,0,width*0.75,height);
  
  if(myCharts.size()<=10) interface_start=0;
  
  for(int i=interface_start; i<myCharts.size();i++)
  {
    if(i-interface_start>=10) break;
    else if(show_chart==i) fill(155);
    else fill(myCharts.get(i).color_vent);
    strokeWeight(3);
    rect(width*0.75,height*0.1*(i-interface_start),width*0.25,height*0.1);
    
    if(change_name==i)
    {
      fill(255);
      strokeWeight(1);
      rect(width*0.78,height*0.025+height*0.1*(i-interface_start),width*0.19,height*0.05);
    }
    
    fill(0);
    textSize(height*0.04);
    textAlign(CENTER);
    text(myCharts.get(i).name,width*0.875,height*0.065+height*0.1*(i-interface_start));
  }
  
  strokeWeight(2);
  fill(155,255,155);
  rect(width*0.2, height*0.1, width*0.07,height*0.05,5);
  if(writing_status == writing_green_limit)
  {
    fill(255);
    strokeWeight(1);
    rect(width*0.205, height*0.105, width*0.06,height*0.04);
  }
  
  strokeWeight(2);
  fill (255,255,0);
  rect(width*0.5, height*0.1, width*0.07,height*0.05,5);
  if(writing_status == writing_yellow_limit)
  {
    strokeWeight(1);
    fill(255);
    rect(width*0.505, height*0.105, width*0.06,height*0.04);
  }
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
  if(writing_status == writing_idle)
  {
    //if click in selector menu
    if( (mouseX>=width*0.75) && (mouseX<=width) &&
        (mouseY>=0)          && (mouseY<=height)  )
    {
      for(int i=0;( (i<myCharts.size()) && (i<10) );i++)
      {
        if((mouseY>=height*0.1*i) && (mouseY<=0.1*height+height*0.1*i))
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
    else if( (mouseX>=width*0.2) && (mouseX<=width*0.27) &&
             (mouseY>=0.1)          && (mouseY<=height*0.15) &&
             mouseButton == RIGHT )
    {
      green_limit = 0;
      writing_status = writing_green_limit;
    }
    else if( (mouseX>=width*0.5) && (mouseX<=width*0.57) &&
             (mouseY>=0.1)          && (mouseY<=height*0.15) &&
             mouseButton == RIGHT  )
    {
      yellow_limit = 0;
      writing_status = writing_yellow_limit;
    }//if click in limits
  }//if block while writting
}// mouseClicked




void mouseWheel(MouseEvent event)
{
  if(    (writing_status == writing_idle) &&
         (mouseX>=width*0.75) && (mouseX<=width) &&
         (mouseY>=0)          && (mouseY<=height) &&
         (myCharts.size()>10)                )
  {
    float moves = event.getCount();
    interface_start += moves;
    if(interface_start<0) interface_start=0;
    else if(interface_start>(myCharts.size()-10)) interface_start = (myCharts.size()-10);
  }
}




void keyPressed()
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
      green_limit = green_limit*10 + int(key)-48;
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
      yellow_limit = yellow_limit*10 + int(key)-48;
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
