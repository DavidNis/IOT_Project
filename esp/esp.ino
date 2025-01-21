#include <WiFi.h>
#include <FirebaseESP32.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ld2410.h>
#include "DHT.h"
#include "secrets.h"  // Include your secret file with API_KEY, DATABASE_URL, USER_EMAIL, and USER_PASSWORD

// Firebase
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// Led Errors
#define LED_PIN 23 

// IR Transmitter
#define IR_LED_PIN 19
IRsend irsend(IR_LED_PIN);

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

#include <ld2410.h>

ld2410 radar;

uint32_t lastReadingRadar = 0;
uint32_t lastReadingDht = 0;

bool radarConnected = false;	

// DHT Sensor
#define DHTPIN 18  // GPIO pin for DHT sensor (change if necessary)
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

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
    MONITOR_SERIAL.println(F("not connected"));
  }

  // Initialize DHT sensor
  dht.begin();
  Serial.println(F("DHT sensor initialized."));
}

void loop() {
  // Check Wi-Fi and Firebase connection status
  bool wifiConnected = (WiFi.status() == WL_CONNECTED);
  bool firebaseConnected = Firebase.ready();

  // Control the LED based on connection status
  if (!wifiConnected || !firebaseConnected) {
    digitalWrite(LED_PIN, HIGH);  // Turn on the LED if disconnected
  } else {
    digitalWrite(LED_PIN, LOW);  // Turn off the LED if connected
  }

  // Firebase IR Transmitter Command
  if (Firebase.getString(firebaseData, "/transmitter/value")) {
    if (firebaseData.dataType() == "string") {
      String hexValue = firebaseData.stringData();  // Get hex as string
      long intValue = strtol(hexValue.c_str(), nullptr, 16);  // Convert to int
      Serial.print("Hexadecimal Value from Firebase: ");
      Serial.println(hexValue);
      Serial.print("Converted Decimal Value: ");
      Serial.println(intValue);
      irsend.sendNEC(intValue, 32);
    } else {
      Serial.print("Failed to get value: ");
      Serial.println(firebaseData.errorReason());
    }
  }

  // LD2410 Radar Reading
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

  // DHT Sensor Readings (every 15 seconds)
  if (millis() - lastReadingDht > 15000) {
    lastReadingDht = millis();
    float humidity = dht.readHumidity();
    float tempCelsius = dht.readTemperature();

    // Check if the readings are valid
    if (isnan(humidity) || isnan(tempCelsius)) {
      Serial.println(F("Failed to read from DHT sensor!"));
    } else {
      // Print DHT sensor values
      Serial.print(F("Humidity: "));
      Serial.print(humidity);
      Serial.print(F("%  Temperature: "));
      Serial.print(tempCelsius);
      Serial.print(F("°C  "));

      // Update Firebase paths for DHT readings
      if (Firebase.ready()) {
        if (Firebase.setFloat(firebaseData, "/DHT/humidity", humidity)) {
          // Serial.println("Updated /DHT/humidity in Firebase");
        } else {
          Serial.print("Failed to update humidity: ");
          Serial.println(firebaseData.errorReason());
        }

        if (Firebase.setFloat(firebaseData, "/DHT/temperature", tempCelsius)) {
          // Serial.println("Updated /DHT/temperature in Firebase");
        } else {
          Serial.print("Failed to update temperature: ");
          Serial.println(firebaseData.errorReason());
        }
      }
    }
  }
}