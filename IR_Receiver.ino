#include "IRrecv.h"

//uint16_t RECV_PIN = D4; // for ESP8266 micrcontroller
uint16_t RECV_PIN = 15; // for ESP32 micrcontroller

IRrecv irrecv(RECV_PIN);
decode_results results;

void setup() {
  Serial.begin(9600);
  irrecv.enableIRIn();
}

void loop() {
  if (irrecv.decode(&results)) {
    if (results.value >> 32)  // print() & println() can't handle printing long longs. (uint64_t)
      Serial.print((uint32_t) (results.value >> 32), HEX);  // print the first part of the message
    Serial.println((uint32_t) (results.value & 0xFFFFFFFF), HEX); // print the second part of the message
    irrecv.resume();  // Receive the next value
  }
  delay(100);
}
