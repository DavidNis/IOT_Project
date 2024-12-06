
int pirPin = 21; // PIR pin 

int pirStat = 0; // PIR status

void setup() {
   
 Serial.begin(9600);
}
void loop(){
  delay(200);
 pirStat = digitalRead(pirPin); 
 if (pirStat == HIGH) {            // if motion detected
   Serial.println("Motion detected!!!");
 } 
 else {
   Serial.println("No motion!");
 }
} 
