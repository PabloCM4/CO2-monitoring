//BY: PABLO CASTILLO MORALEDA, MALAGA, SPAIN.

//CLASS CHART

int max_data = 30;

int[] disp_numb = {400, 650, 900, 1150, 1400, 1650, 1900, 2150, 2400, 2650};
//int[] disp_numb = {400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2200};

class Chart_CO2
{
  float[] data = new float[max_data];
  int pointer_data;
  String name;
  String unique_address;
  int last_data_sent;
  int CO2;
  color color_vent;
  boolean MHZ19_failing;
  //Constructor
  Chart_CO2(String address_chart)
  {
    unique_address = address_chart;
    name = unique_address;
    pointer_data = 0;
    last_data_sent = millis();
    MHZ19_failing = false;
    
    CO2 = 400;
    
    for(int i=0;i<max_data;i++)
    {
      data[i] = 0;
    }
  }//Constructor
  //****************
  //Draw the chart
  void draw_chartCO2()
  {
    float posX=width*0.2, posY=height*0.2;
    float sizeX=width*0.4, sizeY=height*0.5;
    
    //Background of the chart
    fill(255);
    stroke(0);
    strokeWeight(2);
    rect(posX, posY, sizeX, sizeY);
    
    //Abscissa line
    stroke(0);
    strokeWeight(3);
    line(posX+sizeX*0.1, posY+sizeY*0.9, posX+sizeX*0.9, posY+sizeY*0.9);
    
    //Ordinate line
    stroke(0);
    strokeWeight(3);
    line(posX+sizeX*0.1, posY+sizeY*0.1, posX+sizeX*0.1, posY+sizeY*0.9);
    
    //Indicators
    
          //ordinate indicators
    for(int i=0; i<10; i++)
    {
      stroke(0);
      strokeWeight(1);
      line(posX+sizeX*0.07, posY+sizeY*0.1+i*sizeY*0.0888, posX+sizeX*0.13, posY+sizeY*0.1+i*sizeY*0.0888);
    
      textAlign(CENTER);
      textSize(sizeX*0.025);
      fill(0);
      text(disp_numb[i], posX+sizeX*0.04,posY+sizeY*0.915-i*sizeY*0.0888);
    }
          //abscissa indicators
    for(int i=0; i<max_data; i++)
    {
      float pos_indX = posX+sizeX*(0.1+(0.8/(max_data-1)*(i)));
      stroke(0);
      strokeWeight(1);
      line(pos_indX, posY+sizeY*0.87, pos_indX, posY+sizeY*0.93);
    
      if(i%5==0 || i==max_data-1)
      {
        textAlign(CENTER);
        textSize(sizeX*0.02);
        fill(0);
        text(i, pos_indX,posY+sizeY*0.96);
        
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
         act_posY = posY + sizeY*(1-(0.1+((act_value-400)/2250)*0.8));
        act_posX = posX+sizeX*(0.1+(0.8/(max_data-1)*(pos)));
        fill(200,50,50);
        strokeWeight(1);
        circle(act_posX,act_posY,sizeY*0.02);
        
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
    textSize(sizeX*0.018);
    text("TIME(min)", posX+sizeX*0.95, posY+sizeY*0.91);
    text("CO2(PPM)", posX+sizeX*0.1, posY+sizeY*0.06);
 
  }//DRAW_CHARTCO2
  //***************
  
  void new_value(int value)
  {
    data[pointer_data] = value;
    CO2 = value;
    pointer_data++;
    if(pointer_data >= max_data) pointer_data = 0;
    
    last_data_sent = millis();
  }
}//CLASS CHART_CO2
