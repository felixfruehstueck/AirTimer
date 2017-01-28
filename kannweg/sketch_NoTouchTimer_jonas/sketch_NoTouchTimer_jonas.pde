/*-------------------------
 To Dos
 -------------------------
 
// Jonas
Gesten an Processing schicken --> Punch als Test
Processing soll Gesten erkennen, evtl. zusätzl. Library bzw. selbst gestalten
siehe auskommentierte Fkt motionRecognized()

Gesten starten und enden je nach Bewegung bzw. Stillstand der Hand/Finger

(leap motion mit LED ring verheiraten)




// Felix

1) Grundlage: Arduino ansprechen - was kann er managen?
Vor allem, was kriegt der Serielle Port pro Sekunde hin? (Binär-Zerlegung notwendig??!)

Darauf basierend 2 Klassen schreiben:

2a) Bildschirm-Simulation
Gepimpte LED-Klasse, die Kommandos versteht ("Blinke 2 Sekunden!")

2b) Arduino + Ring
Gleiche Funktion wie 2A aber auf Arduino

// Notizen 

Timer wenn abgelaufen rückwärts zählen lassen, um User die ÜBerlaufzeit mitzuteilen.


*/

/*-------------------------
 VARS
 -------------------------*/

// leap + arduino init
import de.voidplus.leapmotion.*;
import processing.serial.*; 
import org.gicentre.utils.move.Ease;

Serial port;
LeapMotion leap;

/*---- status helpers -----

int globalStatus
// 0 = sleep
// 1 = animate
// 2 = listen
// 3 = run
// 4 = pause

globalAnimation
// int globalAnimationDuration = duration of animation sequence, in frames
// int globalAnimationEndAction = action to trigger on end

Auf Arduino SEite:
// int globalAnimationType 
// 0 = fade in + out
// 1 = blink

globalTimer
globalTimerStatus 
// 0 = paused
// 1 = running

---------------------------*/

// virtual ring setup
float lg_diam =  750; // large circle's diameter
float lg_rad  = lg_diam/2; // large circle's radius
float lg_circ =  PI * lg_diam; // large circumference
float LEDs = 60;
float sm_diam = (lg_circ / LEDs); // small circle's diameter

int globalStatus = 0;
int globalAnimationDuration = 0;
String globalAnimationType = "";
int globalAnimationEndAction = 0;

int globalTimer = 0;
int globalTimerStatus = 0;
int globalCurrentFrame = 59;

int minutes;
int seconds;

/*
int currentFrame = 59;
int tempFrame = 0;
int counterStatus = 0; // 0 = off, 1 = wakeup, 2 = waiting for input, 3=running, ...
int animationRunning = 0;
*/

// timer variable <-- !important!
//int runTime = 448; // 108 seconds = 4 minutes, 48 seconds

LED SingleLED;
LED[] allLED = new LED[60];

int previousPosition = 0;
int currentPosition = 0;


/*-------------------------
 SETUP
 -------------------------*/

void setup() {
  size(800, 800, P3D);
  background(255);
  colorMode(HSB, 255);
  frameRate(60);

  leap = new LeapMotion(this);
  println(Serial.list());
  port = new Serial(this, Serial.list()[1], 9600);

  //draw 60 LEDs
  for (int i = 0; i < LEDs; ++i) {
    allLED[i] = new LED(i);
  }
  println("LEDs created successfully.");
}

/*-------------------------
 keyboard / punch listener
 -------------------------*/
 
 void keyPressed() {
   if(key == 'p'){
     inputActionHandler("punch");
   }
 }
 
/* TODO: map gestures to inputActionHandler

void motionRecognized() {
   if(gesture == XYZ){
     inputActionHandler("punch");
   }
 }
 */
 
 void inputActionHandler(String action){
  if (action == "punch") {
    // if sleeping, animate
    if(globalStatus == 0){
      globalAnimationType = "fade";
      globalAnimationDuration = 60;
      globalAnimationEndAction = 2;
      globalStatus = 1;
    }
    
    //if listening, start
    else if(globalStatus == 2){
      println ("punched, globalstatus " + globalStatus);
      globalTimerStatus = 1; // go!
      globalTimer = 448; // while in status 2, the time was set (for now hardcoded)
      globalStatus = 3;
      println ("punched, globalstatus " + globalStatus);
    }
    
    //if running, pause
    else if(globalStatus == 3){
      println ("punched, globalstatus " + globalStatus);
      globalTimerStatus = 0; // wait
      globalStatus = 4;
    }
    
    //if paused, run
    else if(globalStatus == 4){
      println ("punched, globalstatus " + globalStatus);
      globalTimerStatus = 1; // go!
      globalStatus = 3;
    }
    
  }
}

/*-------------------------
 DRAW
 -------------------------*/

void draw() {
  
  //decide what currently needs to be done
  switch (globalStatus) {
  default:
    //waiting
    //println ("waiting...");p
    break;
  case 1:
    //showing an animation
    println("globalStatus = 1 - animating...");
    animateLEDs();
    break;
  case 2:
    //counting down
    print ("2 - listening...");
    listen();
    break;
   case 3:
    //counting down
    println("globalStatus = 3 - counting...");
    runLEDs();
    break;
   case 4:
    //have a break
    println("globalStatus = 4 - paused...");
    runLEDs();
    break;
  }

/*-------------------------
 INTERACTION
 -------------------------*/

  for (Hand hand : leap.getHands()) {
    //hand.draw();
    
    // 0 - 59: 60 LEDs on my NeoPixel Ring
    currentPosition = (int) map(hand.getPosition().x, 10, 990, 0, 59);

    if (previousPosition != currentPosition) {
      previousPosition = currentPosition;
      port.write(previousPosition);
    }
  }
} /* end of draw */



/*-------------------------
 FUNCTIONALITY
 -------------------------*/


boolean animateLEDs() {
  
  /*
  globalAnimationType = "fade";
  globalAnimationDuration = 120;
  globalAnimationEndAction = 2;
  */
  
  // make sure this ends some time
  globalAnimationDuration--;
  
  // if end is reached, check which action should be next
  if (globalAnimationDuration <=0) {
    globalStatus = globalAnimationEndAction;
    println ("end of aimation reached, switching to status " + globalStatus);
  }
  
  int saturation = globalAnimationDuration;
  
  for (int j = 0; j < 60; j++) {
    allLED[j].setColor(0, saturation, 255);
  }
  
  return true;
}

public void listen(){
  // do nothing, wait for hand input
}

public void runLEDs() {
  
  if(globalTimerStatus == 1){
    globalCurrentFrame--;
    if (globalCurrentFrame==0) {
      globalCurrentFrame = 59;
      if (globalCurrentFrame > 0) globalTimer--;
    }
  }

  //get number of full minutes currently left
  minutes = (int) Math.floor(globalTimer /60);
  seconds = globalTimer % 60;

  //draw color for minutes 
  for (int i = 0; i < minutes; i++) {
    allLED[i].setColor(0, 255, 255);
  }

  //draw white for the rest of the circle
  for (int j = minutes; j < 60; j++) {
    allLED[j].setColor(0, 0, 255);
  }

  //draw color for seconds
  allLED[seconds].setColor(100, 255, 255);
  port.write(seconds);
  println(seconds);

  //draw cool pointer for current 1/60 second
  //-->also, this keeps "currentFrame" from jumping/skipping!!!
  allLED[globalCurrentFrame].setColor(120, 255, 255);
}