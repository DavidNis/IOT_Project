int radarPin = 21; // Radar sensor pin (GPIO 21)
int radarStatus = 0; // Radar sensor status

void setup() {
  pinMode(radarPin, INPUT);  // Set radar pin as input
  Serial.begin(9600);       // Start Serial Monitor
}

void loop() {
  delay(200);  // Short delay for stability
  radarStatus = digitalRead(radarPin); // Read radar sensor signal

  if (radarStatus == HIGH) {  // If motion or presence is detected
    Serial.println("Motion/Presence detected!!!");
  } else {
    Serial.println("No motion or presence detected.");
  }
}