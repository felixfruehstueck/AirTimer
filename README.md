# AirTimer
###a gesture-operated, visual alarm device

## Important Variables

### `int appStateMain`
stores the current state ID of the app
* `0` - off - when the app is not initialized
* `1` - standby - when the app is running without further input
* `2` - starting - interim state during startup (animation)
* `3` - while adjusting minutes and seconds
* `4` - timer running / counting down
* `5` - timer paused / count down on hold
* `6` - timer reached 0 / alarm

### `timer*`
```
// status of the timer
int timerMinutes = 0;
int timerSeconds = 0;
int timerCurrentFrame = 59;
```
These variables are used to store the time setting.
Once the countdown is launched, timerCurrentFrame is decreased by 1 per frame.
Important: None of the above may ever have negative values (set to 60 instead).

### `animation*`
```
// animation helpers
int animationCounter = 0;
int animationHelper = 0;
LED[] LEDs;
```

`LED[] LEDs` - an array, containing 60 instances of the class LED
* this array is instantiated and filled in `setup()`
* it helps to access / manipulate the simulation of the LED ring

`animationCounter` is used for the timing of animations.
Example: Counts up to 60 frames = one second, value is used for `lerp()` calculations occasionally.

`animationHelper` is set to store values that are animated during animation.
Example: For blinking LEDs, brightness value is `lerp`ed, saved in animationHelper and then applied to all LEDs.

## Usage

### Key "P"
currently simulates the *P*UNC gesture.
In most cases, hitting "P" will increase appStateMain by 1 to go to the next step of the app.

### Key "O"
currently simulates *increasing the desired time*.
Depending in which mode the app currently is (appStateMain), increases minutes or seconds.

### Key "L"
currently simulates *decreasing the desired time*.
Depending in which mode the app currently is (appStateMain), decreases minutes or seconds.
