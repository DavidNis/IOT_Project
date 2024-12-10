#include <IRremoteESP8266.h>
#include <IRsend.h>

#define IR_LED_PIN 19 // Pin connected to the IR transmitter (IR LED)

IRsend irsend(IR_LED_PIN);

void setup() {
  irsend.begin(); // Initialize the IR transmitter
  Serial.begin(115200);
  Serial.println("IR Transmitter ready. Use the buttons to send commands.");
}

void loop() {
  commands to change LED strip colors
  
  delay(2000); // Delay between commands
  Serial.println("Sending Red color command...");
  irsend.sendNEC(0xF3A48769, 32); //  command for "Red"

  delay(2000);
  Serial.println("Sending Green color command...");
  irsend.sendNEC(0xFF629D, 32); //  command for "Green"

  delay(2000);
  Serial.println("Sending Blue color command...");
  irsend.sendNEC(0xFFE21D, 32); //  command for "Blue"
}
