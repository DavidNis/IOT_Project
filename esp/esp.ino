#include <WiFi.h>
#include <FirebaseESP32.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ld2410.h>
#include <Adafruit_NeoPixel.h>

#include "DHT.h"
#include "secrets.h"  // Include your secret file with API_KEY, DATABASE_URL, USER_EMAIL, and USER_PASSWORD

// Firebase
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;


#define NEOPIXEL_PIN 12    // Pin connected to the NeoPixel data line
#define NUMPIXELS 2        // Number of NeoPixels on your strip/ring

Adafruit_NeoPixel strip(NUMPIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);


// Led Errors
#define LED_PIN 23 

// IR Transmitter
#define IR_LED_PIN 19
IRsend irsend(IR_LED_PIN);
//  the last IR codes in local arrays:
String lastHexValues[4] = {"", "", "", ""}; // for onOff, mode, fanSpeed, temp

// LD2410 Radar
#if defined(ESP32)
  #ifdef ESP_IDF_VERSION_MAJOR // IDF 4+
    #if CONFIG_IDF_TARGET_ESP32 // ESP32/PICO-D4
      #define MONITOR_SERIAL Serial
      #define RADAR_SERIAL Serial1
      #define RADAR_RX_PIN 32
      #define RADAR_TX_PIN 33
    #elif CONFIG_IDF_TARGET_ESP32S2
      #define MONITOR_SERIAL Serial
      #define RADAR_SERIAL Serial1
      #define RADAR_RX_PIN 9
      #define RADAR_TX_PIN 8
    #elif CONFIG_IDF_TARGET_ESP32C3
      #define MONITOR_SERIAL Serial
      #define RADAR_SERIAL Serial1
      #define RADAR_RX_PIN 4
      #define RADAR_TX_PIN 5
    #else 
      #error Target CONFIG_IDF_TARGET is not supported
    #endif
  #else // ESP32 Before IDF 4.0
    #define MONITOR_SERIAL Serial
    #define RADAR_SERIAL Serial1
    #define RADAR_RX_PIN 32
    #define RADAR_TX_PIN 33
  #endif
#elif defined(__AVR_ATmega32U4__)
  #define MONITOR_SERIAL Serial
  #define RADAR_SERIAL Serial1
  #define RADAR_RX_PIN 0
  #define RADAR_TX_PIN 1
#endif


ld2410 radar;

uint32_t lastReadingRadar = 0;
uint32_t lastReadingDht = 0;
uint32_t lastTimestamp = 0;

bool radarConnected = false;	

// DHT Sensor
#define DHTPIN 18  // GPIO pin for DHT sensor (change if necessary)
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);
  // Variables to store previous DHT readings
float previousHumidity = NAN;
float previousTempCelsius = NAN;
String modeValue;






void setup() {
  Serial.begin(115200);

  // Initialize the LED pin
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);  // Turn off the LED initially

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi!");

  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (Firebase.ready()) {
    Serial.println("Firebase is ready!");
  } else {
    Serial.println("Firebase initialization failed.");
  }

  // IR Transmitter
  irsend.begin();
  Serial.println("IR Transmitter ready.");

  // LD2410 Radar
  #if defined(ESP32)
    RADAR_SERIAL.begin(256000, SERIAL_8N1, RADAR_RX_PIN, RADAR_TX_PIN); // UART for monitoring the radar
  #elif defined(__AVR_ATmega32U4__)
    RADAR_SERIAL.begin(256000); // UART for monitoring the radar
  #endif
  delay(500);
  MONITOR_SERIAL.print(F("\nConnect LD2410 radar TX to GPIO:"));
  MONITOR_SERIAL.println(RADAR_RX_PIN);
  MONITOR_SERIAL.print(F("Connect LD2410 radar RX to GPIO:"));
  MONITOR_SERIAL.println(RADAR_TX_PIN);
  MONITOR_SERIAL.print(F("LD2410 radar sensor initialising: "));
  if (radar.begin(RADAR_SERIAL)) {
    MONITOR_SERIAL.println(F("OK"));
    MONITOR_SERIAL.print(F("LD2410 firmware version: "));
    MONITOR_SERIAL.print(radar.firmware_major_version);
    MONITOR_SERIAL.print('.');
    MONITOR_SERIAL.print(radar.firmware_minor_version);
    MONITOR_SERIAL.print('.');
    MONITOR_SERIAL.println(radar.firmware_bugfix_version, HEX);
  } else {
    MONITOR_SERIAL.println(F("LD2410 radar not connected"));
  }

  // Initialize DHT sensor
  dht.begin();
  Serial.println(F("DHT sensor initialized."));


  // Initialize NeoPixel strip
  strip.begin();
  strip.show();       // Turn OFF all pixels at start
  strip.setBrightness(50);  // Optional: dim brightness, 0-255
}











void loop() {


if (Serial.available()) {
    String command = Serial.readStringUntil('\n'); // Read the input
    command.trim(); // Remove any trailing whitespace or newline characters

    if (command == "AC") {
      Serial.println("Executing AC function...");
      AC(); // Call the function when the command is "AC"
    } else {
      Serial.println("Unknown command: " + command);
    }
  }


// Check Wi-Fi and Firebase connection status
bool wifiConnected = (WiFi.status() == WL_CONNECTED);
bool firebaseConnected = Firebase.ready();

// Reconnect if Wi-Fi is disconnected
if (!wifiConnected) {
  Serial.println("Wi-Fi disconnected. Attempting to reconnect...");
  digitalWrite(LED_PIN, HIGH);  // Turn on the LED to indicate disconnection

  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long startAttemptTime = millis();

  // Attempt to reconnect for 10 seconds
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 10000) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWi-Fi reconnected successfully!");
    digitalWrite(LED_PIN, LOW);  // Turn off the LED when reconnected
  } else {
    Serial.println("\nWi-Fi reconnection failed.");
  }
}

// Reconnect Firebase if disconnected
if (!firebaseConnected) {
  Serial.println("Firebase disconnected. Attempting to reconnect...");
  Firebase.reconnectWiFi(true);  // Attempt to reconnect Firebase Wi-Fi

  // Check if Firebase is reconnected
  if (Firebase.ready()) {
    Serial.println("Firebase reconnected successfully!");
  } else {
    Serial.println("Firebase reconnection failed.");
  }
}

// Control the LED based on connection status
if (!wifiConnected || !firebaseConnected) {
  digitalWrite(LED_PIN, HIGH);  // Keep LED on if still disconnected
} else {
  digitalWrite(LED_PIN, LOW);   // Turn off the LED if both connections are active
}



//timestamp

if (millis() - lastTimestamp < 20000){
  Firebase.setFloat(firebaseData, "/random", millis());
  lastTimestamp = millis();
}

//transmitter

String fields[] = {"onOff","mode", "fanSpeed", "temp"};
for (int i = 0; i < 4; i++) {
    String field = fields[i];
    String codePath = "/transmitter/" + field + "/code";
    String valuePath = "/transmitter/" + field + "/value";

    // Attempt to get the 'code' from Firebase
    if (Firebase.getString(firebaseData, codePath)) {
      if (firebaseData.dataType() == "string") {
        String newHexValue = firebaseData.stringData(); // e.g. "F7C03F"
        
        // Compare with the last known code for this field
        if (newHexValue != lastHexValues[i]) {
          // It's changed => send IR once
          long intValue = strtol(newHexValue.c_str(), nullptr, 16);
          irsend.sendNEC(intValue, 32);

          Serial.print("NEW code for ");
          Serial.print(field);
          Serial.print(": ");
          Serial.print(newHexValue);
          Serial.println(" => IR sent");

          // Update local memory with this new code
          lastHexValues[i] = newHexValue;

          //if the code is different then also print the value
          if (Firebase.getString(firebaseData, valuePath)) {
            if (firebaseData.dataType() == "string") {
              Serial.print("Value of ");
              Serial.print(field);
              Serial.print(" is: ");
              Serial.println(firebaseData.stringData());
            }
          }




String modeValuePath = "/transmitter/mode/value";
String onOffValuePath = "/transmitter/onOff/value";

if (Firebase.getString(firebaseData, modeValuePath)) {
  if (firebaseData.dataType() == "string") {
    modeValue = firebaseData.stringData();
  }
}

// Read the "mode/leds"
int ledsValue = 0;
String ledsPath = "/transmitter/mode/leds";
if (Firebase.getInt(firebaseData, ledsPath)) {
  if (firebaseData.dataType() == "int") {
    ledsValue = firebaseData.intData();
  }
}
  String onOffValue;

if (Firebase.getInt(firebaseData, onOffValuePath)) {
  if (firebaseData.dataType() == "string") {
    onOffValue = firebaseData.stringData();
  }
}  

// Check if LEDs should be ON or OFF
if (ledsValue == 1 && onOffValue == "On") {
  uint32_t color;

  if (modeValue == "Cool") {
    color = strip.Color(0, 0, 255); // Blue for Cool mode
    Serial.println("NeoPixel: Blue (Cool)");
  } else if (modeValue == "Heat") {
    color = strip.Color(255, 0, 0); // Red for Heat mode
    Serial.println("NeoPixel: Red (Heat)");
  } else {
    color = strip.Color(0, 0, 0); // OFF for unknown mode
    Serial.println("NeoPixel: Off (Unknown Mode)");
  }

  // Apply color to all pixels
  for (int i = 0; i < NUMPIXELS; i++) {
    strip.setPixelColor(i, color);
  }
} else {
  // Turn off if ledsValue == 0 or onOffValue != "On"
  for (int i = 0; i < NUMPIXELS; i++) {
    strip.setPixelColor(i, strip.Color(0, 0, 0));
  }
  Serial.println("NeoPixel: Off");
}

strip.show();



        }
        // else do nothing; code hasn't changed
      }
    } 


    // else: failed to retrieve code from Firebase, skip
  }


  // LD2410 Radar
  radar.read();
  if (radar.isConnected() && millis() - lastReadingRadar > 1000) {  // Report every 1000ms
    lastReadingRadar = millis();
    if (radar.presenceDetected()) {
      Firebase.setFloat(firebaseData, "/motionSensor/value", 1);
      if (radar.stationaryTargetDetected()) {
        Serial.print(F("Stationary target: "));
        Serial.print(radar.stationaryTargetDistance());
        Serial.print(F("cm energy:"));
        Firebase.setFloat(firebaseData, "/motionSensor/stationary", radar.stationaryTargetDistance());
        Serial.print(radar.stationaryTargetEnergy());
        Serial.print(' ');
      }
      if (radar.movingTargetDetected()) {
        Serial.print(F("Moving target: "));
        Serial.print(radar.movingTargetDistance());
        Firebase.setFloat(firebaseData, "/motionSensor/moving", radar.movingTargetDistance());
        Serial.print(F("cm energy:"));
        Serial.print(radar.movingTargetEnergy());
      }
      Serial.println();
    } else {
      Serial.println(F("No target"));
      Firebase.setFloat(firebaseData, "/motionSensor/value", 0);
      Firebase.setFloat(firebaseData, "/motionSensor/stationary", 0);
      Firebase.setFloat(firebaseData, "/motionSensor/moving", 0);
    }
  }



// DHT Sensor Readings (every 10 seconds)
if (millis() - lastReadingDht > 10000) {
  lastReadingDht = millis();
  float humidity = dht.readHumidity();
  float tempCelsius = dht.readTemperature();

  // Check if the readings are valid
  if (isnan(humidity) || isnan(tempCelsius)) {
    Serial.println(F("Failed to read from DHT sensor!"));
  } else {
    // Only proceed if the values have changed
    if (humidity != previousHumidity || tempCelsius != previousTempCelsius) {
      // Update previous readings
      previousHumidity = humidity;
      previousTempCelsius = tempCelsius;

      // Print DHT sensor values
      Serial.println("Humidity: " + String(humidity) + "%  Temperature: " + String(tempCelsius) + "°C");

      // Update Firebase paths for DHT readings
      if (Firebase.ready()) {
        if (Firebase.setFloat(firebaseData, "/DHT/humidity", humidity)) {
          Serial.println("Humidity: " + String(humidity) + "%");
        } else {
          Serial.println("Failed to update humidity: " + firebaseData.errorReason());
        }

        if (Firebase.setFloat(firebaseData, "/DHT/temperature", tempCelsius)) {
          Serial.println("Temperature: " + String(tempCelsius) + "°C");
        } else {
          Serial.println("Failed to update temperature: " + firebaseData.errorReason());
        }
      }
    }
  }
  Serial.println();

}

}





void AC() {
  String fields[] = {"onOff", "mode", "fanSpeed", "temp"};
  for (String field : fields) {
    // Retrieve and print the 'code' for the field
    String codePath = "/transmitter/" + field + "/code"; // Path to the 'code'

    if (Firebase.getString(firebaseData, codePath)) {
      if (firebaseData.dataType() == "string") {
        String hexValue = firebaseData.stringData();  // Get hex as string
        long intValue = strtol(hexValue.c_str(), nullptr, 16);  // Convert to int
        Serial.println(field + " code is: " + hexValue);
        irsend.sendNEC(intValue, 32);
      } else {
        Serial.println("Failed to get code for field: " + field);
      }
    } else {
      Serial.println("Failed to retrieve 'code' for field: " + field);
      Serial.println(firebaseData.errorReason());
    }

    // Retrieve and print the 'value' for the field
    String valuePath = "/transmitter/" + field + "/value"; // Path to the 'value'
    if (Firebase.getString(firebaseData, valuePath)) {
      if (firebaseData.dataType() == "string") {
        Serial.println(field + " value is: " + firebaseData.stringData());
      } else {
        Serial.println("Invalid data type for value in field: " + field);
      }
    } else {
      Serial.println("Failed to retrieve 'value' for field: " + field);
      Serial.println(firebaseData.errorReason());
    }
  }
  Serial.println();
}
