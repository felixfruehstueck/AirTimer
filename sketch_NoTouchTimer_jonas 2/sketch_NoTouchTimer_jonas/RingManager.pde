import java.util.*;

// helper variables for virtual ring (on screen)
float lg_diam =  450; // large circle's diameter
float lg_rad  = lg_diam/2; // large circle's radius
float lg_circ =  PI * lg_diam; // large circumference
float sm_diam = (lg_circ / 60); // small circle's diameter

class RingManager {
  
  private int ringStatus = 0;
  
  
  
  
  // helper variables for animations
  private int animationDuration;
  private int animationType;
  private long animationStartedAt;
  
  private LED[] LEDs;
  
  private Date d;
  
  //constructor
  //create 60 LEDs
  public RingManager () {
    
    // create 60 LEDs
    LED[] LEDs = new LED[60];
    
    for (int i = 0; i < LEDs.length; ++i) {
      LEDs[i] = new LED(i);
    }
    
    println("ringmanager initialized...");

  }

  // start an animation
  // 
  public void setAnimation (String type, int duration) {
    animationStartedAt = d.getTime();
  }
  
  // show a number of LEDs (minutes / seconds)
  public void setDuration(int seconds){
    
  }
  
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
    LEDs[j].setColor(0, saturation, 255);
  }
  
  return true;
}
  
  /*-------------------------
 DRAW
 -------------------------*/

void draw() {
  
  //decide what currently needs to be done
  /*switch (globalStatus) {
  default:
    //waiting
    //println ("waiting...");
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
  }*/
}
  
  
void runLEDs() {
  
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
    LEDs[i].setColor(0, 255, 255);
  }

  //draw white for the rest of the circle
  for (int j = minutes; j < 60; j++) {
    LEDs[j].setColor(0, 0, 255);
  }

  //draw color for seconds
  LEDs[seconds].setColor(100, 255, 255);
  port.write(seconds);
  println(seconds);

  //draw cool pointer for current 1/60 second
  //-->also, this keeps "currentFrame" from jumping/skipping!!!
  LEDs[globalCurrentFrame].setColor(120, 255, 255);
}

}