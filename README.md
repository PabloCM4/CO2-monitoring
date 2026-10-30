# CO2 Monitoring

CO2 monitoring software developed for an Electronic Systems degree thesis. The
system measures the carbon-dioxide concentration in a building with an ESP32
development board and an MH-Z19B sensor, then displays the measurements in
desktop applications built with Processing.

The system uses MQTT to connect the sensor nodes with:

- **Manager**: receives sensor data, tracks connected sensors, and distributes
  their status to user clients.
- **Users**: displays the current CO2 level and a short history for each sensor.
- **ESP32 sensor nodes**: read the MH-Z19B and publish measurements once a
  manager has detected them.

## Architecture

```text
MH-Z19B + ESP32 ──MQTT──> Manager ──MQTT──> Users
       (sensor node)       (Processing)     (Processing)
```

The manager and user applications connect to the same MQTT broker. A sensor
publishes on a topic named after its configured device name. The manager
discovers sensors through `New_sensor`, and user clients receive the current
sensor list and ventilation limits through `Users`.

## Repository layout

| Path | Description |
| --- | --- |
| [`ESP32_MHZ19B_MQTT/`](./ESP32_MHZ19B_MQTT) | Arduino sketch for the ESP32 and MH-Z19B sensor |
| [`main_manager/`](./main_manager) | Processing source for the manager application |
| [`main_users/`](./main_users) | Processing source for user/display applications |
| [`manager_app_windows/`](./manager_app_windows) | Prebuilt manager applications for 32-bit and 64-bit Windows |
| [`manager_app_linux/`](./manager_app_linux) | Prebuilt manager applications for Linux x86 and ARM targets |
| [`users_app_windows/`](./users_app_windows) | Prebuilt user applications for 32-bit and 64-bit Windows |
| [`users_app_linux/`](./users_app_linux) | Prebuilt user applications for Linux x86 and ARM targets |
| [`LICENSE`](./LICENSE) | GNU General Public License, version 2 |

The prebuilt application directories contain the executable, its `data`
directory, the Processing libraries, and the generated source used to build
that distribution.

## Requirements

### Hardware

- ESP32 development board
- MH-Z19B CO2 sensor
- Wi-Fi network
- MQTT broker reachable by the ESP32 and the computer running the Processing
  applications

The sketch uses the ESP32 hardware serial port with:

| MH-Z19B | ESP32 |
| --- | --- |
| TX | GPIO 16 (`RX_PIN`) |
| RX | GPIO 17 (`TX_PIN`) |

The sensor communicates at 9600 baud. The sketch waits 60 seconds after startup
for the MH-Z19B warm-up period before sending readings.

### Software

- Arduino IDE or another ESP32-compatible Arduino build environment
- ESP32 board support for Arduino
- The Arduino libraries used by the sketch: `EspMQTTClient` and `MHZ19`
- Processing with the MQTT library used by the source (`import mqtt.*`)
- An MQTT broker, such as Mosquitto

The repository does not include an MQTT broker or dependency installation
configuration.

## Configuration

### Processing applications

Both source applications read `data/config.txt`. The file is positional:

```text
Write in the next line the IP adress of the MQTT broker:
mqtt://localhost
Write in the next line the PASSWORD of the application:
1234
```

The second line is the broker URI and the fourth line is the shared application
password. Update the `config.txt` inside the source directory before running
from Processing. When using a prebuilt application, update the corresponding
file under that application's `data/` directory.

The sample password and broker URI are placeholders. Do not expose a broker
without suitable authentication and network controls.

### ESP32 sketch

Set the Wi-Fi credentials, MQTT broker address, and unique device name near the
top of [`ESP32_MHZ19B_MQTT.ino`](./ESP32_MHZ19B_MQTT/ESP32_MHZ19B_MQTT.ino):

```cpp
const char* myName = "your-sensor-name";
const char* myIP = "192.168.1.10";

EspMQTTClient cliente_mqtt(
  "your-wifi-ssid",
  "your-wifi-password",
  myIP,
  myName
);
```

Every sensor must have a different `myName`, because it is used as that
sensor's MQTT topic. Keep Wi-Fi credentials and other private deployment
values out of public repositories.

## Running the system

1. Start the MQTT broker and note its URI.
2. Update the broker URI and password in the manager and user
   `data/config.txt` files.
3. Configure and upload the ESP32 sketch.
4. Start one manager application and enter the configured password.
5. Start one or more user applications and enter the same password.
6. Wait for the ESP32 to complete its warm-up and connect to MQTT.

Only one manager should run for a broker/system deployment. The manager
detects another manager through the `Manager` topic and exits after reporting
the conflict. Multiple user applications can observe the same manager.

### Using the prebuilt applications

Run the executable inside the directory matching the target platform:

- Windows 64-bit: `manager_app_windows/application.windows64/` or
  `users_app_windows/application.windows64/`
- Windows 32-bit: `manager_app_windows/application.windows32/` or
  `users_app_windows/application.windows32/`
- Linux x86-64: `manager_app_linux/application.linux64/` or
  `users_app_linux/application.linux64/`
- Linux x86 32-bit: `manager_app_linux/application.linux32/` or
  `users_app_linux/application.linux32/`
- Linux ARM64: `manager_app_linux/application.linux-arm64/` or
  `users_app_linux/application.linux-arm64/`
- Linux ARMv6 hard-float: `manager_app_linux/application.linux-armv6hf/` or
  `users_app_linux/application.linux-armv6hf/`

Run each executable from its application directory so that its `data/` folder
and bundled libraries are found.

## Application controls

### Manager

- Left-click a sensor in the right-hand list to show its chart.
- Right-click a sensor name to rename it.
- Right-click the green or yellow limit value and type a new value.
- Use the mouse wheel over the sensor list when more than ten sensors are
  connected.

The default ventilation limits are 600 ppm (green) and 800 ppm (yellow).
Readings are shown as green, yellow, or red according to those limits; a
sensor failure is shown in blue.

### User client

- Left-click a sensor in the right-hand list to show its chart.
- Use the mouse wheel over the sensor list when more than ten sensors are
  connected.

The user client receives sensor names and ventilation limits from the manager.
It does not provide the manager's editing controls.

## MQTT message flow

The implementation uses these application-level topics:

| Topic | Purpose |
| --- | --- |
| `New_sensor` | Sensor announces itself to the manager |
| `<sensor-name>` | Sensor data and control messages for one sensor |
| `New_user` | User client announces itself |
| `Users` | Manager sends the sensor list and limits to users |
| `Manager` | Manager heartbeat/availability notification |
| `Check_Sensors` | Manager checks that known sensors are still active |

Sensor payloads are integer values in ppm. The special values are:

- `-1`: sensor is disconnecting
- `0`: the MH-Z19B reported a sensor failure
- Positive values: CO2 concentration in ppm

## Building from source

### ESP32 firmware

1. Open the `.ino` file in Arduino IDE.
2. Select the ESP32 board and serial port.
3. Install the required ESP32, MQTT client, and MH-Z19B libraries.
4. Set the Wi-Fi, broker, and device-name values.
5. Compile and upload the sketch.

### Processing applications

Open the `.pde` files in `main_manager/` or `main_users/` with Processing,
install the MQTT library, and ensure the matching `data/config.txt` is
available. Use Processing's Run command for development or its Export
Application command to create a platform-specific distribution.

## Limitations and maintenance notes

- Configuration is stored as plain text and the application password is not
  hashed.
- MQTT transport security and broker authentication are not configured by the
  applications; configure these at the broker/network level if required.
- Sensor history is kept in memory by the Processing applications and is not
  persisted to disk.
- The included binaries were generated for the listed legacy platform targets;
  rebuilding from source may be necessary on modern systems.

## License

This project is distributed under the GNU General Public License, version 2.
See [`LICENSE`](./LICENSE) for the full text.
