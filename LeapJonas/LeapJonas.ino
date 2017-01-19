#include <Adafruit_NeoPixel.h>
#define PIN 6

Adafruit_NeoPixel strip = Adafruit_NeoPixel(60, PIN, NEO_GRB + NEO_KHZ800);


/*
int minute = 0;
int second = 0;
int hour = 0;*/

int previousPosition;
int currentPosition;
int serialInput;

int minutes;
int seconds;

void setup() {
  strip.begin();
  strip.setBrightness(50); 
  strip.show(); // Initialize all pixels to 'off'

  Serial.begin(9600); // Listen for input
}

void loop() {
  if (Serial.available()) {
    //serialInput = Serial.read();
/*
    strip.setPixelColor(5, strip.Color(0,255,0));
    strip.setPixelColor(3, strip.Color(0,255,0));
    strip.setPixelColor(1, strip.Color(0,255,0));
    strip.show();
*/
/*
    strip.setPixelColor(minutes, strip.Color(255,255,255));
    strip.show();
*/
    minutes = Serial.read();
    for (int i = 0; i < minutes; i++){
    strip.setPixelColor(i, strip.Color(0,255,0));
    }
    for (int i = minutes; i < 60; i++){
    strip.setPixelColor(i, strip.Color(0,0,0));
    }
    strip.show();
    delay(50);

    /*
    // if our position has changed
    if(serialInput != currentPosition) {  
      // take note of where we were    
      previousPosition = currentPosition;  
      // take note of where we are now 
      currentPosition = serialInput;  
      
      // make the current LED a pretty rainbow colour
      strip.setPixelColor(currentPosition, Wheel(currentPosition * 10)); 
      strip.show();
      
      // make the previous LED turn off
      strip.setPixelColor(previousPosition, strip.Color(0, 0, 0));
      strip.show();
    }
    */
  }
}
