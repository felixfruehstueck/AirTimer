import de.voidplus.leapmotion.*;
import processing.serial.*; 
import org.gicentre.utils.move.Ease;

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

// ports
Serial port;
LeapMotion leap;

// virtual ring setup
RingManager ringManager;

// current program status
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

int previousPosition = 0;
int currentPosition = 0;


/*
 * -------------------------
 *  SETUP
 * -------------------------
 */

void setup() {
  size(500, 500, P3D);
  background(255);
  colorMode(HSB, 255);
  frameRate(60);
  
  //printArray(Serial.list());

  //leap = new LeapMotion(this);
  //port = new Serial(this, Serial.list()[0], 9600);
  
  
  // initialize the RingManager
  ringManager = new RingManager();

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
      ringManager.setAnimation("fade", 2);
    }
    
    /*
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
    */
    
  }
}



/*-------------------------
 INTERACTION
 -------------------------

  for (Hand hand : leap.getHands()) {
    //hand.draw();
    
    // 0 - 59: 60 LEDs on my NeoPixel Ring
    currentPosition = (int) map(hand.getPosition().x, 10, 990, 0, 59);

    if (previousPosition != currentPosition) {
      previousPosition = currentPosition;
      port.write(previousPosition);
    }
  }
}



-------------------------
 FUNCTIONALITY
 -------------------------*/


public void listen(){
  // do nothing, wait for hand input
}