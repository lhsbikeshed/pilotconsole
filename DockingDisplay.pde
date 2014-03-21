public class DockingDisplay implements Display {

  PImage bgImage;

  PImage shipImg, feetImg;
  //22

  boolean landed = false;
  boolean clamped = true;
  boolean bayGravity = true;


  public static final int NO_SIGNAL = 0;
  public static final int BEACON_LOCKING = 1;
  public static final int BEACON_LOCKED = 2;
  int lockingState = NO_SIGNAL;

  boolean speedWarning = false;
  long lastSpeedWarning = 0;


  int undercarriageState = 1;
  private String[] undercarriageStrings = {
    "up", "down", "Lowering..", "Raising.."
  };

  PVector shipPos = new PVector(0, 0, 0);
  PVector shipRot = new PVector(0, 0, 0);

  PVector lastShipPos = new PVector(0, 0, 0);
  long lastPosUpdate = 0;
  float lastRotation = 0;
  //bay img is 600x300, 95,370

    float iconScale = 0.3f;
  float distance = 100.0f;

  public DockingDisplay() {
    bgImage = loadImage("launchdisplay.png");
    shipImg = loadImage("shipbehind.png");
    feetImg = loadImage("shipfeet.png");
  }


  public void oscMessage(OscMessage theOscMessage) {

    if (theOscMessage.checkAddrPattern("/ship/undercarriage/contact") == true) {
      landed = theOscMessage.get(0).intValue() == 1 ? true : false;
    } 
    else if (theOscMessage.checkAddrPattern("/ship/undercarriage")) {
      undercarriageState = theOscMessage.get(0).intValue();
    } 
    else if (theOscMessage.checkAddrPattern("/system/misc/clampState")) {
      clamped = theOscMessage.get(0).intValue() == 1 ? true : false;
    } 
    else if (theOscMessage.checkAddrPattern("/scene/launchland/bayGravity")) {
      bayGravity = theOscMessage.get(0).intValue() == 1 ? true : false;
    }
    else if (theOscMessage.checkAddrPattern("/system/dockingComputer/dockingPosition")) {
      lastShipPos.x = shipPos.x; 
      lastShipPos.y = shipPos.y; 
      lastShipPos.z = shipPos.z;

      distance = theOscMessage.get(4).floatValue(); 


      lastPosUpdate = millis();

      shipPos.x = theOscMessage.get(0).floatValue();
      shipPos.y = theOscMessage.get(1).floatValue();
      shipPos.z = theOscMessage.get(2).floatValue();
      println(shipPos);

      //signal locking events
      int newLockingState = theOscMessage.get(5).intValue() ;
      if (lockingState != newLockingState) {
        if (newLockingState == NO_SIGNAL) {
          consoleAudio.playClip("signalLost");
        } 
        else if (newLockingState == BEACON_LOCKING) {
          consoleAudio.playClip("searchingBeacon");
        } 
        else if ( newLockingState == BEACON_LOCKED) {
          consoleAudio.playClip("signalAcquire");
        }
      }

      lockingState = newLockingState;
    }
  }


  public void start() {
    lockingState = NO_SIGNAL;
  }
  public void stop()
  {
  }
  public void draw() {

    background(0, 0, 0);
    stroke(255);
    strokeWeight(1);
    line(width/2, 0, width/2, height);
    line(0, height/2, width, height/2);


    //  image(bgImage, 0, 0, width, height);
    textFont(font, 15);
    fill(255, 255, 0);

    text("Docking Clamp: " + (clamped == true ? "Engaged" : "Disengaged"), 60, 110);
    text("Undercarriage: " + undercarriageStrings[undercarriageState], 60, 130);
    text("Bay Gravity: " + (bayGravity == true ? "On" : "Off"), 60, 150);
    if (landed) {
      text("Floor Contact", 60, 170);
    }

    noFill();
    for (int i = 1; i < 4; i++) {
      ellipse(width/2, height/2, i * 150, i * 150);
    }

    if (lockingState != NO_SIGNAL) {
      pushMatrix();

      PVector lerpPos = new PVector(0, 0, 0);
      lerpPos.x = lerp(lastShipPos.x, shipPos.x, (millis() - lastPosUpdate) / 200.0f);
      lerpPos.y = lerp(lastShipPos.y, shipPos.y, (millis() - lastPosUpdate) / 200.0f);

      int screenX = (int)map(lerpPos.x, 45.0, -45.0, 0, width);
      int screenY = (int)map(lerpPos.y, 45.0, -45.0, 0, height);


      translate(screenX, screenY);
      //ship
      strokeWeight(5);
      noFill();

      //calc colour
      float d = abs(lerpPos.mag());
      if ( d < 0.5) {
        stroke(0, 255, 0);
      } 
      else if (d < 1.5) {
        stroke(255, 255, 0);
      } 
      else {
        stroke(255, 0, 0);
      }
      ellipse(0, 0, 100, 100);
      strokeWeight(2);
      line(-50, -50, 50, 50);
      line(-50, 50, 50, -50);


      popMatrix();
    } 
    else {
      textFont(font, 48);
      text("NO SIGNAL", 322, 401);
    }
    textFont(font, 30);
    text(distance, 46, 740);
    text("Speed: " + (int)shipState.shipVelocity, 58, 183);

    String s = "" ;
    ;
    if (lockingState == NO_SIGNAL) {
      s = "No Docking Beacon Detected";
    } 
    else if (lockingState == BEACON_LOCKING) {
      s = "locking onto beacon..";
    } 
    else if (lockingState == BEACON_LOCKED) {

      s = "LOCKED to beacon";
    }

    text(s, 46, 710);

    if(lockingState != NO_SIGNAL){
      //speed calcs
      speedWarning = false;
      if (distance < 250 && shipState.shipVelocity > 35) {
        speedWarning = true;
      } 
      else if (distance < 150 && shipState.shipVelocity > 20) {
        speedWarning = true;
      }
      else if (distance < 80 && shipState.shipVelocity > 10) {
        speedWarning = true;
      }
  
      if (speedWarning && lastSpeedWarning + 2000 < millis()) {
        lastSpeedWarning = millis();
        consoleAudio.playClip("reduceSpeed");
      }
    } else {
      if (speedWarning && lastSpeedWarning + 2000 < millis()) {
        lastSpeedWarning = millis();
        consoleAudio.playClip("searchingBeacon");
      }
    }
  }


  public void serialEvent(String evt) {
  }

  public float CurveAngle(float start, float end, float step) 
  { 
    float from = radians(start);
    float to = radians(end);
    // Ensure that 0 <= angle < 2pi for both "from" and "to" 
    while (from < 0) 
      from += TWO_PI; 
    while (from >= TWO_PI) 
      from -= TWO_PI; 

    while (to < 0) 
      to += TWO_PI; 
    while (to >= TWO_PI) 
      to -= TWO_PI; 

    if (abs(from-to) < PI) 
    { 
      // The simple case - a straight lerp will do. 
      return lerp(from, to, step);
    } 

    // If we get here we have the more complex case. 
    // First, increment the lesser value to be greater. 
    if (from < to) 
      from += TWO_PI; 
    else 
      to += TWO_PI; 

    float retVal = lerp(from, to, step); 

    // Now ensure the return value is between 0 and 2pi 
    if (retVal >= TWO_PI) 
      retVal -= TWO_PI; 
    return retVal;
  }
}

