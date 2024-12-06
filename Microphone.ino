void setup() {

  pinMode(35, INPUT);

  Serial.begin(115200);

}



void loop() {

  // put your main code here, to run repeatedly:

  int voice = analogRead(35);

  Serial.println(voice);
  delay(100);
}