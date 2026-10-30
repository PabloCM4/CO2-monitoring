#include "EspMQTTClient.h"
#include "MHZ19.h"

#define MSG_BUFFER_SIZE 3
#define RX_PIN 16
#define TX_PIN 17
#define WARM_UP_TIME 60000 // MH-Z19B needs 60 seconds to warm up

const char *myName = "XXX";         // Client name that uniquely identify your device
const char *myIP = "XXX.XXX.XXX.X"; // MQTT Broker server ip

EspMQTTClient cliente_mqtt(
    "your-wifi-ssid",
    "your-wifi-password",
    myIP,
    myName);

char last_will_msg[MSG_BUFFER_SIZE];
unsigned long now = 0, start_program = 0, last_msg = 0, last_check = 0, last_try = 0;
bool first_attempt = true, PC_Listening = false;
int CO2 = 999;

MHZ19 myMHZ19;

void mqtt_send_data(int &CO2)
{
  String msg = String(CO2);
  cliente_mqtt.publish(myName, msg);
}

void setup()
{
  Serial.begin(115200);
  Serial2.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN); // BEGIN COMMUNICATION WITH CO2 SENSOR
  cliente_mqtt.enableDebuggingMessages();          // Enable debugging messages sent to serial output

  //***__MHZ19 init__***
  myMHZ19.begin(Serial2); // TELL THE CO2 SENSOR WE ARE USING THE SERIAL2 TO COMMUNICATE

  myMHZ19.autoCalibration();

  int aux_lw = -1;
  snprintf(last_will_msg, MSG_BUFFER_SIZE, "%d", aux_lw);
  cliente_mqtt.enableLastWillMessage(myName, last_will_msg);

  start_program = millis();
}

void onConnectionEstablished()
{
  Serial.println("We are online");
  PC_Listening = false;
}

void loop()
{
  cliente_mqtt.loop();
  now = millis();

  if (cliente_mqtt.isConnected() && (now - start_program > WARM_UP_TIME))
  {

    if (PC_Listening)
    {
      if (now - last_msg >= (60 * 1000)) // Send data every 60 seconds
      {
        CO2 = myMHZ19.getCO2();
        Serial.print("CO2 (ppm): ");
        Serial.println(CO2);

        mqtt_send_data(CO2);

        last_msg = now;
      }

      if ((now - last_check) > (25 * 1000))
      {
        int aux = -1;
        mqtt_send_data(aux);
        PC_Listening = false;
        first_attempt = true;
      }
    }
    else if ((now - last_try) >= (5 * 1000))
    {
      if (first_attempt)
      {
        cliente_mqtt.unsubscribe("Check_Sensors");
        cliente_mqtt.subscribe(myName, [](const String &msg)
                               {
          if(msg.equals("Listening"))
          {
            cliente_mqtt.unsubscribe(myName);
            PC_Listening = true;
            last_check = now;
            cliente_mqtt.subscribe( "Check_Sensors", [](const String& msg) 
            {
              if(msg.equals(myName)) last_check = now;
            });
          } });

        first_attempt = false;
      }

      cliente_mqtt.publish("New_sensor", myName);
      last_try = now;
    }
  }
}
