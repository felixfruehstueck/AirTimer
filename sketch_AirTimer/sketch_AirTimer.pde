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

// SDKs + libraries
import de.voidplus.leapmotion.*;
import org.gicentre.utils.move.Ease;

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

// input
LeapMotion leap;

// virtual ring setup
float lg_diam;
float lg_rad;
float lg_circ;
float sm_diam;

// leap helpers
int previousPosition = 0;
int currentPosition = 0;

// overall status of the app
int appStateMain = 0; 

// status of the timer
int timerMinutes = 0;
int timerSeconds = 0;
int timerCurrentFrame = 59;

// animation helpers
int animationCounter = 0;
int animationHelper = 0;
LED[] LEDs;


/*-------------------------
 SETUP
 -------------------------*/

void setup() {
  
  // set the stage
  size(600, 600, P3D);
  background(255);
  colorMode(HSB, 255);
  frameRate(60);
  
  // prepare 60 LEDs
  LEDs = new LED[60];
  
  // create simulaton
  lg_diam =  550; // large circle's diameter
  lg_rad  = lg_diam/2; // large circle's radius
  lg_circ =  PI * lg_diam; // large circumference
  sm_diam = (lg_circ / LEDs.length); // small circle's diameter
  
  for (int i = 0; i < LEDs.length; ++i) {
    LEDs[i] = new LED(i);
  }

  // reference the leap motion device
  leap = new LeapMotion(this);
  
  //draw 60 LEDs
  for (int i = 0; i < LEDs.length; ++i) {
    LEDs[i] = new LED(i);
  }
  
  // set app to "waiting"
  appStateMain = 1;
}

/*-------------------------
 keyboard / punch listener
 -------------------------*/
 
 void keyPressed() {
   
   if(key == 'p'){
     inputActionHandler("punch");
   }
   
   if(key == 'o'){
     inputActionHandler("increase");
   }
   
   if(key == 'l'){
     inputActionHandler("decrease");
   }
 }
 
void inputActionHandler(String action){
  
  if(action == "increase"){
    if(appStateMain == 3){
      //increase minutes
      timerMinutes = (timerMinutes >= 60) ? 60 : timerMinutes +1;
      println("increased m: " + timerMinutes);
    }
    if(appStateMain == 4){
      //increase seconds
      timerSeconds = (timerSeconds >= 60) ? 60 : timerSeconds +1;
      println("increased s: " + timerSeconds);
    }
  }
  
  if(action == "decrease"){
    if(appStateMain == 3){
      //decrease minutes
      timerMinutes = (timerMinutes <= 0) ? 0 : timerMinutes -1;
      println("decreased m: " + timerMinutes);
    }
    if(appStateMain == 4){
      //decrease seconds
      timerSeconds = (timerSeconds <= 0) ? 0 : timerSeconds -1;
      println("decreased s: " + timerSeconds);
    }
  }
  
  if (action == "punch") {
    
    if(appStateMain == 6){
      appStateMain = 5;
    }else if(appStateMain == 7){
      appStateMain = 2;
    }else{
      appStateMain++;
    }
    
    println("punched, switched to appStateMain " + appStateMain);
    
  }
}

/*-------------------------
 DRAW
 -------------------------*/

void draw() {
  
  //decide what currently needs to be done
  switch (appStateMain) {
  default:
    //waiting
    printStatus("waiting");
    break;
  
  // not initialized, do nothing
  case 0:
    printStatus("switched off");
    break;
  
  // app launched, still do nothing
  case 1:
    printStatus("standby");
    break;
    
  // device was activated, show startup animation
  case 2:
    printStatus("starting");
    stepStart();
    break;
    
  // device start completed, wait for minutes adjustment 
   case 3:
    //have a break
    printStatus("minutes?");
    stepAdjust();
    break;

  // setup of minutes completed, wait for seconds adjumstnet
  case 4:
    printStatus("seconds?");
    stepAdjust();
    break;
  
  // timer is running (counting backwards)
  case 5:
    printStatus(((timerMinutes < 10) ? "0" : "") + timerMinutes + ":" + ((timerSeconds < 10) ? "0" : "") + timerSeconds);
    stepRun();
    break;
    
  // timer is paused (holding current time)
  case 6:
    printStatus(((timerMinutes < 10) ? "0" : "") + timerMinutes + ":" + ((timerSeconds < 10) ? "0" : "") + timerSeconds + " - paused");
    break;
  
  // timer reached 0 and plays alarm
  case 7:
    printStatus("Piep!");
    stepAlarm();
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
    }
  }
} /* end of draw */

void printStatus(String status){
  noStroke();
  fill(255);
  rect(0, 0, 120, 20); 
  stroke(153);
  fill(100);
  text(status, 10, 10);
}

/*-------------------------
 FUNCTIONALITY
 -------------------------*/

// wake up animation
// this is called every frame as long as appStateMain == 2
void stepStart() {
  
  // animatonCounter is helper variable
  // if 0, animation was just started
  if(animationCounter == 0){
    animationCounter = 1;
  }
  // if other then 0, calculate what to display
  else{
     // let this run for 1 second
     if(animationCounter <= 60){
       animationCounter++;
       
       // animationHelper increases from 0 to 255 in 60 steps:
       animationHelper = int(lerp(0,255,(float)animationCounter/60));
       
       for (int j = 0; j < 60; j++) {
          LEDs[j].setColor(animationHelper, 255, 255);
        }
     }
     // after 1 second, go to appStateMain 3 (adjusting minutes)
     else{
       println("reached end of startup animation");
       animationCounter = 0;
       appStateMain = 3;
     }
  }
}

// feedback for adjustment of minutes and seconds
// this is called every frame as long as appStateMain is 3 (minutes) or 4 (seconds)
void stepAdjust(){
  
  int currentColor = 0;
  int currentlyAdjusting = timerMinutes;
  
  // make this work for seconds and minutes
  if(appStateMain == 3){
    currentlyAdjusting = timerMinutes;
    currentColor = 255; //(red for minutes)
  }
  
  if(appStateMain == 4){
    currentlyAdjusting = timerSeconds;
    currentColor = 200; //(green for seconds)
  }
  
  // LEDs 0 to x draw colorful
  for (int i = 0; i < currentlyAdjusting; i++) {
    LEDs[i].setColor(currentColor, 255, 255);
  }
  
  // LEDs x to 60, draw white
  for (int j = currentlyAdjusting; j < 60; j++) {
    LEDs[j].setToWhite();
  }
  
}

public void listen(){
  // do nothing, wait for hand input
}

// showing the remaining time on the ring
// this is called every frame as long as appStateMain is 5 (running) or 6 (paused)
public void stepRun() {
  
  if(appStateMain == 5){
    timerCurrentFrame--;
    if (timerCurrentFrame < 0) {
      timerCurrentFrame = 59;
      timerSeconds--;
      if(timerMinutes == 0 && timerSeconds == 0){
        appStateMain = 7;
      } 
      if(timerSeconds < 0){
        timerSeconds = 59;
        timerMinutes--;
      }
    }
  }
  
  if(timerMinutes > 0){
  
    //draw color for minutes 
    for (int i = 0; i < timerMinutes; i++) {
      LEDs[i].setColor(0, 255, 255);
    }
  
    //draw white for the rest of the circle
    for (int j = timerMinutes; j < 60; j++) {
      LEDs[j].setColor(0, 0, 255);
    }
  
    //draw color for seconds
    LEDs[timerSeconds].setColor(100, 255, 255);
  
  }else{
    
    //draw color for seconds 
    for (int i = 0; i < timerSeconds; i++) {
      LEDs[i].setColor(100, 255, 255);
    }
  
    //draw white for the rest of the circle
    for (int j = timerSeconds; j < 60; j++) {
      LEDs[j].setColor(0, 0, 255);
    }
    
  }

  

  //draw cool pointer for current 1/60 second
  LEDs[timerCurrentFrame].setColor(120, 255, 255);
  
}

// alarm function to call when countdown reached 0
// this is called every frame as long as appStatemain is 7

public void stepAlarm(){
  
  // animatonCounter is helper variable
  // if 0, animation was just started
  if(animationCounter == 0){
    animationCounter = 1;
  }
  // if other then 0, calculate what to display
  else{
     // let this run repeatedly for 1 second
     if(animationCounter <= 60){
       animationCounter++;
       
       // animation increases from 0 to 255 in 60 steps:
       animationHelper = int(lerp(0,255,(float)animationCounter/60));
  
      //draw color for minutes 
      for (int i = 0; i < 60; i++) {
        LEDs[i].setColor(255, animationHelper, 255);
      }
    }
    //repeat after 1s
    if(animationCounter >= 60){
      animationCounter = 1;
    }
  }
}