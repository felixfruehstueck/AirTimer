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
int leapDelay;

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

  // init leap
  leap = new LeapMotion(this).allowGestures();
  leapDelay = 30;

  // create simulaton
  lg_diam =  550; // large circle's diameter
  lg_rad  = lg_diam/2; // large circle's radius
  lg_circ =  PI * lg_diam; // large circumference
  sm_diam = (lg_circ / LEDs.length); // small circle's diameter

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

  if (key == 'p') {
    inputActionHandler("punch");
  }

  if (key == 'o') {
    inputActionHandler("increase");
  }

  if (key == 'l') {
    inputActionHandler("decrease");
  }

  if (key == 'f') {
    inputActionHandler("flick");
  }
}

void setMinutes(int minutes) {
  if (minutes <= 0) {
    timerMinutes = 0;
  } else if (minutes >= 60){
    timerMinutes = 60;
  } else {
    timerMinutes = minutes;
  }
}

void setSeconds(int seconds) {
  if (seconds <= 0) {
    timerSeconds = 0;
  } else if (seconds >= 60){
    timerSeconds = 60;
  } else {
    timerSeconds = seconds;
  }
}

void inputActionHandler(String action) {

  if (action == "increase") {
    if (appStateMain == 3) {
      //increase minutes
      timerMinutes = (timerMinutes >= 60) ? 60 : timerMinutes +1;
      println("increased m: " + timerMinutes);
    }
    if (appStateMain == 4) {
      //increase seconds
      timerSeconds = (timerSeconds >= 60) ? 60 : timerSeconds +1;
      println("increased s: " + timerSeconds);
    }
  }

  if (action == "decrease") {
    if (appStateMain == 3) {
      //decrease minutes
      timerMinutes = (timerMinutes <= 0) ? 0 : timerMinutes -1;
      println("decreased m: " + timerMinutes);
    }
    if (appStateMain == 4) {
      //decrease seconds
      timerSeconds = (timerSeconds <= 0) ? 0 : timerSeconds -1;
      println("decreased s: " + timerSeconds);
    }
  }

  if (action == "punch") {

    // usually, punch goes to next higher status (appState Main +1).
    // EXCEPTIONS: 
    // 5 (paused) --> go back to 4 (running)
    // 6 (alarm) --> go back to 2 (startup animation)
    // NOTE:
    // 2 (animation) will end after 1 second and go to 3 (adjust) automatically
    // 4 (running) will end automatically and go to 6 (alam) when counter reaches zero.
    
    if (appStateMain == 5) {
      appStateMain = 4;
    } else if (appStateMain == 6) {
      appStateMain = 2;
    } else {
      appStateMain++;
    }

    if (action == "flick") {

      if (appStateMain == 6 || appStateMain == 7) {
        appStateMain = 2;
      }
    }

    println("- - - appStateMain = " + appStateMain + "- - -");
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

    // device start completed, wait for time adjustment 
  case 3:
    //have a break
    printStatus("time?");
    stepAdjust();
    break;

    // timer is running (counting backwards)
  case 4:
    printStatus(((timerMinutes < 10) ? "0" : "") + timerMinutes + ":" + ((timerSeconds < 10) ? "0" : "") + timerSeconds);
    stepRun();
    break;

    // timer is paused (holding current time)
  case 5:
    printStatus(((timerMinutes < 10) ? "0" : "") + timerMinutes + ":" + ((timerSeconds < 10) ? "0" : "") + timerSeconds + " - paused");
    break;

    // timer reached 0 and plays alarm
  case 6:
    printStatus("Piep!");
    stepAlarm();
    break;
  }

  /*-------------------------
   INTERACTION
   -------------------------*/

  if (leapDelay > 0) {
    leapDelay--;
  }

  for (Hand hand : leap.getHands()) {
    //hand.draw();

    // 0 - 59: 60 LEDs on my NeoPixel Ring
    currentPosition = (int) map(hand.getPosition().x, 10, 990, 0, 59);

    if (previousPosition != currentPosition) {
      previousPosition = currentPosition;
    }
  }
}

void printStatus(String status) {
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
  if (animationCounter == 0) {
    animationCounter = 1;
  }
  // if other then 0, calculate what to display
  else {
    // let this run for 1 second
    if (animationCounter <= 60) {
      animationCounter++;

      // animationHelper increases from 0 to 255 in 60 steps:
      animationHelper = int(lerp(0, 255, (float)animationCounter/60));

      for (int j = 0; j < 60; j++) {
        LEDs[j].setColor(animationHelper, 255, 255);
      }
    }
    // after 1 second, go to appStateMain 3 (adjusting minutes)
    else {
      println("reached end of startup animation");
      animationCounter = 0;
      appStateMain = 3;
    }
  }
}

// feedback for adjustment of minutes and seconds
// this is called every frame as long as appStateMain is 3 (minutes) or 4 (seconds)
void stepAdjust() {

  /*
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
   */
   
  for (Hand hand : leap.getHands ()) {
    hand.draw();
    Finger fingerIndex = hand.getIndexFinger();
    
    if (appStateMain == 3) {
      println(fingerIndex.getPosition().z + " / " + (int)fingerIndex.getPosition().z  + " / " + (int(fingerIndex.getPosition().z / 3)));
      
      //setMinutes((int)(fingerIndex.getPosition().x / 8));
      setSeconds((int)(fingerIndex.getPosition().z / 2));
      
      setMinutes((int) map(fingerIndex.getPosition().x, 10, 990, 0, 59));
    }
  }

  drawTimeOnRing(timerMinutes, timerSeconds);
}

public void listen() {
  // do nothing, wait for hand input
}

// showing the remaining time on the ring
// this is called every frame as long as appStateMain is 4 (running) or 5 (paused)
public void stepRun() {

  if (appStateMain == 4) {
    timerCurrentFrame--;
    if (timerCurrentFrame < 0) {
      timerCurrentFrame = 59;
      timerSeconds--;
      if (timerMinutes == 0 && timerSeconds == 0) {
        appStateMain = 6;
      } 
      if (timerSeconds < 0) {
        timerSeconds = 59;
        timerMinutes--;
      }
    }
  }

  drawTimeOnRing(timerMinutes, timerSeconds);
}

// alarm function to call when countdown reached 0
// this is called every frame as long as appStatemain is 6

public void stepAlarm() {

  // animatonCounter is helper variable
  // if 0, animation was just started
  if (animationCounter == 0) {
    animationCounter = 1;
  }
  // if other then 0, calculate what to display
  else {
    // let this run repeatedly for 1 second
    if (animationCounter <= 60) {
      animationCounter++;

      // animation increases from 0 to 255 in 60 steps:
      animationHelper = int(lerp(0, 255, (float)animationCounter/60));

      //draw full circle
      for (int i = 0; i < 60; i++) {
        LEDs[i].setColor(255, animationHelper, 255);
      }
    }
    //repeat after 1s
    if (animationCounter >= 60) {
      animationCounter = 1;
    }
  }
}



/*
-------
 LEAP
 -------
 */
void leapOnSwipeGesture(SwipeGesture g, int state) {
  int     id               = g.getId();
  Finger  finger           = g.getFinger();
  PVector position         = g.getPosition();
  PVector positionStart    = g.getStartPosition();
  PVector direction        = g.getDirection();
  float   speed            = g.getSpeed();
  long    duration         = g.getDuration();
  float   durationSeconds  = g.getDurationInSeconds();

  switch(state) {
  case 1: // Start
    break;
  case 2: // Update
    break;
  case 3: // Stop
    println("SwipeGesture: " + id);
    //inputActionHandler("punch");
    break;
  }
}

void leapOnKeyTapGesture(KeyTapGesture g) {
  int     id               = g.getId();
  Finger  finger           = g.getFinger();
  PVector position         = g.getPosition();
  PVector direction        = g.getDirection();
  long    duration         = g.getDuration();
  float   durationSeconds  = g.getDurationInSeconds();

  if (leapDelay == 0) {
    println("PUNCH!!! ------------------- " + id);
    inputActionHandler("punch");
    leapDelay = 30;
  }
}

// DISPLAY ONLY
// --> this function does not modify ANY variables
void drawTimeOnRing(int minutes, int seconds){
  
  // at least 1 minute left, for example 6:42 ?
  // --> draw 6 red LEDs for minutes (permanently)
  // --> draw 1 single green LED at position 42 for seconds
  if (minutes > 0) {

    //draw color for minutes 
    for (int i = 0; i < minutes; i++) {
      LEDs[i].setColor(0, 255, 255);
    }

    //draw white for the rest of the circle
    for (int j = minutes; j < 60; j++) {
      LEDs[j].setColor(0, 0, 255);
    }

    //draw color for seconds
    LEDs[seconds].setColor(100, 255, 255);
    
  } 
  
  // only seconds left, for example 00:32 ?
  // --> draw 32 green LEDs for seconds
  else {

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