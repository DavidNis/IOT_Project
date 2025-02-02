# Smart AC Control

Submitters:
David Nisanov, 
Wijdan Eslim, 
Mazal Sinaniev

Project description:
Smart AC Control is an open-source, IoT-based smart remote solution to modernize air conditioner control. This project integrates an ESP32 microcontroller, IR transmitter/receiver, and various sensors to enhance user experience by providing remote control, environmental monitoring, and automation features. we built a custom smart AC app in Flutter and it communicates with a database (firebase) in real time which makes the ESP read the commands and send it to the AC.

With a custom-built Flutter application, users can:
- Remotely turn the AC on/off
- Adjust temperature settings and modes
- Monitor room temperature and humidity
- Automate operations based on motion detection and schedules
- Connect via Wi-Fi for seamless cloud integration
- Use voice commands with Google Assistant and Alexa

This solution improves both convenience and energy efficiency, reducing unnecessary power consumption.

Smart AC Hardware:
- DHT Sensor: Monitors and measures the current room temperature to provide precise control.
- Radar Sensor: Detects motion within its range to enable automated responses, such as turning the AC off when no motion is detected.
- IR Transmitter and Receiver: Controls the AC via infrared signals and can replicate remote commands.
- ESP32 - Controls all sensors, manages Wi-Fi, and processes IR signals.

Features & Functionalities in the menu option:
- Manual AC Control:
  Turn the AC ON/OFF, adjust the temperature, switch modes, and control fan speed through the mobile app.
  Uses IR communication via ESP32 to replicate the original AC remote control signals.
  
- Climate React (Temperature-Based Automation):
  The AC automatically turns ON/OFF based on room temperature.
  Users can set a temperature threshold (e.g., turn AC ON when room temperature exceeds 25°C).
  Helps maintain comfort without wasting energy.

- Motion-Based Automation:
  Uses a radar motion sensor to detect occupancy.
  Automatically turns OFF the AC if no motion is detected for a specified time.
  Saves energy by preventing the AC from running in an empty room.

- Scheduling (Custom Timed Control):
  Users can schedule the AC to turn ON/OFF at specific times and days.
  Provides fully customizable weekly schedules for automated energy savings.

-Timer (Auto-Off Countdown):
  Users can set a countdown timer to automatically turn off the AC after a specified period to save energy and not forget the AC on.

- Favorite Settings:
  Users can save their preferred temperature, mode, and fan settings for quick access.
  Example: Set favorite mode: Cooling | Temperature: 22°C | Fan: Medium and apply instantly with one tap.

- Statistics & Energy Insights:
  The app tracks AC usage data over time. It displays a graph based on the temperature that is being used and shows the logs. It helps users optimize energy savings by identifying patterns. the app calculates the average temperature that is being used and recommends     it to the user.

- Cloud & Remote Access
  Full AC control from anywhere in the world via Wi-Fi & cloud services.

For Heat and Cool modes, users can select the desired AC mode using the Mode button. When Cool mode is activated, the screen displays a blue color, while in Heat mode, the main screen shifts to a red color, providing a clear visual distinction between the two modes.
Every color represents a temperature range and AC mode (cool/heat) as follows:

• Heat:

o 16°C - 20°C: yellow

o 21°C - 25°C: Orange

o 24°C - 28°C: Darker Orange

o 27°C - 30°C: Red

• Cool:

o 16°C - 20°C: Blue

o 21°C - 25°C: Lighter blue

o 24°C - 28°C: Lighter blue

o 27°C - 30°C: White    ??? maybe these temperatures

*Minimum AC temperature: 16°C

*Maximum AC temperature: 30°C

The fan speed is visually represented through the intensity and brightness of the color—when the fan operates at a higher speed, the color appears more vivid and pronounced. Users can adjust the fan speed by pressing the fan button, which offers Low and High settings.

We used a weather service called geolocator so the user can know what temperature is outside and decide what settings he wants based on this data.

This is what the app looks like:




![image_resized_smaller](https://github.com/user-attachments/assets/cb38e2cb-2f2e-4ef5-902d-582c3a782a37)&nbsp; ![image_resized_new_smaller](https://github.com/user-attachments/assets/2c4c3d12-4373-4de7-a004-851d8759f00e)&nbsp;
 ![image_resized_third_smaller](https://github.com/user-attachments/assets/4172dac3-2179-4cdb-b662-549812fbdec9)






  

