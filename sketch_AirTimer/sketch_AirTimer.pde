import de.voidplus.leapmotion.*;
import org.gicentre.utils.move.Ease;

// input
LeapMotion leap;
int leapPunchDetectorDelay;
int leapPunchDelay;
float[] leapHandTracker;
float leapHandHeight;
float leapHandPinch;
float leapHandXPos;
float leapPinchXPosNull;
float leapHandZPos;
float leapPinchZPosNull;
boolean leapHandIsPinched;

// virtual ring setup
float lg_diam;
float lg_rad;
float lg_circ;
float sm_diam;

// leap helpers
int previousPosition = 0;
int currentPosition = 0;
int currentBrightness = 51;

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
  size(600, 600);
  background(25);
  colorMode(HSB, 255);
  frameRate(60);
  smooth();

  // prepare 60 LEDs
  LEDs = new LED[60];

  // init leap
  leap = new LeapMotion(this).allowGestures();
  leapHandTracker = new float[5];
  leapPunchDelay = leapPunchDetectorDelay = millis();
  leapHandIsPinched = false;

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
 TIME CALC
 -------------------------*/

void setMinutes(int minutes) {
  
  //positive minute input
  if (minutes >= 0) {
    if (minutes > 60) {
      timerMinutes = 60;
    }else {
      timerMinutes = minutes;
    }
  }
  //negative minute input
  else {
    if (minutes > -59){
      timerMinutes = 61 - Math.abs(minutes);
    } else {
      timerMinutes = 0;
    }
  }
  println(minutes + " = " + timerMinutes);

}


void setSeconds(int seconds) {
  
  //positive second input
  if (seconds >= 0) {
    if (seconds > 59) {
      timerSeconds = 59;
    }else {
      timerSeconds = seconds;
    }
  }
  //negative second input
  else {
    if (seconds > -59){
      timerSeconds = 59 + seconds;
    } else {
      timerSeconds = 0;
    }
  }
}

/*-------------------------
INPUT
 -------------------------*/

void inputActionHandler(String action) {

  if (action == "increase") {
    if (appStateMain == 3) {
      //increase minutes
      timerMinutes = (timerMinutes >= 60) ? 60 : timerMinutes +1;
    }
    if (appStateMain == 4) {
      //increase seconds
      timerSeconds = (timerSeconds >= 60) ? 60 : timerSeconds +1;
    }
  }

  if (action == "decrease") {
    if (appStateMain == 3) {
      //decrease minutes
      timerMinutes = (timerMinutes <= 0) ? 0 : timerMinutes -1;
    }
    if (appStateMain == 4) {
      //decrease seconds
      timerSeconds = (timerSeconds <= 0) ? 0 : timerSeconds -1;
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
  }

  if (action == "flick") {

    if (appStateMain == 5 || appStateMain == 6) {
      appStateMain = 3;
    }
  }

  println(">> appStateMain = " + appStateMain);
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
    printStatus("TIMER FINISHED!");
    stepAlarm();
    break;
  }

  for (Hand hand : leap.getHands()) {
    leapHandHeight = hand.getPosition().y;
    leapHandXPos = hand.getPosition().x;
    leapHandZPos = hand.getPosition().z;
    leapHandPinch = hand.getPinchStrength();
  }

  punchDetector();
}

/*-------------------------
 DETECT GESTURES
 -------------------------*/

// permanently check leap motion input for punch gesture
// it saves the height of the stabilizedHand to an array
// in that array, the last 5 positions are kept
// if there is a difference in height >60, this is considered a punch gesture
void punchDetector() {

  // this should not be checked every frame
  // but only every 0.2 seconds
  if (leapPunchDetectorDelay < millis() - 200) {

    leapPunchDetectorDelay = millis();

    for (int i = 4; i >= 0; i--) {
      if (i == 0) {
        leapHandTracker[i] = leapHandHeight;
        //println(i + " " + leapHandHeight);
      }
      // on position 1-4, store positions of last 4 frames
      else {
        leapHandTracker[i] = leapHandTracker[i-1];
        //println(i + " " + leapHandTracker[i]);
      }
    }

    //compare values in the array
    //only if array is fully set
    if (leapHandTracker[4] !=0) {
      for (int i=0; i<5; i++) { 
        //der jüngste muss kleiner sein als einer der vorherigen 4
        if (leapHandTracker[0] - 150 > leapHandTracker[i]) {
          println("PUNCH!!!!Punch!!!!PUNCH!!!!");
          for (int j=0; j<5; j++) {
            leapHandTracker[j] = 0f;
          }
          inputActionHandler("punch");
        }
      }
    }
  }
}

/*-------------------------
 GRAPHICAL OUTPUT
 -------------------------*/

void printStatus(String status) {
  noStroke();
  fill(25);
  rect(0, 0, 120, 45); 
  //stroke(153);
  fill(255);
  text(status, 25, 25);
}

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

  // if hand is in pinched gesture
  if (leapHandPinch >= 0.9) {

    // if reference coordinates were set already
    if (leapHandIsPinched) {
      setSeconds((int)((leapHandZPos - leapPinchZPosNull)/0.5));
      setMinutes((int)((leapHandXPos - leapPinchXPosNull)/3.5));
    }

    // if pinch just happened, set coordinates
    else {
      leapHandIsPinched = true;
      leapPinchZPosNull = leapHandZPos;
      leapPinchXPosNull = leapHandXPos;
    }
  } else {
    leapHandIsPinched = false;
  }

  drawTimeOnRing();
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

  drawTimeOnRing();
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



/*-------
 LEAP
-------*/

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
    inputActionHandler("flick");
    break;
  }
}

// DISPLAY ONLY
// --> this function does not modify ANY variables
void drawTimeOnRing() {

  //draw color for minutes 
  for (int i = 0; i < timerMinutes; i++) {
    LEDs[i].setColor(0, 255, 255);
  }

  // if adjusting, for rest of ring, adjust according to dropzone accuracy
  currentBrightness = 51;

  if (appStateMain == 3) {

    if (leapHandHeight < 400 && leapHandHeight > 200) {
      if (leapHandHeight > 300) {
        currentBrightness = (int)map(leapHandHeight, 301, 400, 255, 51);
      } else {
        currentBrightness = (int)map(leapHandHeight, 200, 301, 51, 255);
      }
    }
  }

  for (int j = timerMinutes; j < 60; j++) {
    LEDs[j].setColor(0, 0, currentBrightness);
  }

  // timerSeconds
  // when running, at least 1 minute left, for example 6:42 ?
  // --> draw 6 red LEDs for minutes (permanently)
  // --> draw 1 single green LED at position 42 for seconds
  if (timerMinutes <= 0 && (appStateMain == 4 || appStateMain == 5)) {

    for (int j = 0; j < timerSeconds; j++) {
      LEDs[j].setColor(100, 255, 255);
    }

    for (int j = timerSeconds; j < 60; j++) {
      LEDs[j].setColor(0, 0, currentBrightness);
    }
  } else {
    LEDs[timerSeconds].setColor(100, 255, 255);
  }

  // when running, draw cool pointer for current 1/60 second
  if (appStateMain == 4) {
    LEDs[timerCurrentFrame].setColor(120, 255, 255);
  }
}