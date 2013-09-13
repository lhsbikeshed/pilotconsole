public class LaunchDisplay implements Display {

  PImage bgImage;
  int beamPower = 2;
  int sensorPower = 2;
  int propulsionPower = 2;

  PImage shipImg, feetImg;
  //22

  boolean landed = false;
  boolean clamped = true;
  boolean bayGravity = true;
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

    public LaunchDisplay() {
    bgImage = loadImage("launchdisplay.png");
    shipImg = loadImage("shipbehind.png");
    feetImg = loadImage("shipfeet.png");
  }


  public void oscMessage(OscMessage theOscMessage) {

    if (theOscMessage.checkAddrPattern("/system/subsystemstate") == true) {
      beamPower = theOscMessage.get(3).intValue() + 1;
      sensorPower = theOscMessage.get(2).intValue() + 1;
      propulsionPower = theOscMessage.get(0).intValue() + 1;
    } 
    else if (theOscMessage.checkAddrPattern("/ship/undercarriage/contact") == true) {
      landed = theOscMessage.get(0).intValue() == 1 ? true : false;
    } 
    else if (theOscMessage.checkAddrPattern("/ship/undercarriage")) {
      undercarriageState = theOscMessage.get(0).intValue();
    } 
    else if (theOscMessage.checkAddrPattern("/system/misc/clampState")) {
      clamped = theOscMessage.get(0).intValue() == 1 ? true : false;
    } else if(theOscMessage.checkAddrPattern("/scene/launchland/bayGravity")){
      bayGravity = theOscMessage.get(0).intValue() == 1 ? true : false;
    }
    else if (theOscMessage.checkAddrPattern("/scene/launchland/dockingPosition")) {
      lastShipPos.x = shipPos.x; 
      lastShipPos.y = shipPos.y; 
      lastShipPos.z = shipPos.z;
      lastPosUpdate = millis();
      
      
      lastRotation = shipRot.z;
      
      
      shipPos.x = theOscMessage.get(0).floatValue();
      shipPos.y = theOscMessage.get(1).floatValue();
      shipPos.z = theOscMessage.get(2).floatValue();
      shipRot.x = theOscMessage.get(3).floatValue();
      shipRot.y = theOscMessage.get(4).floatValue();
      shipRot.z = theOscMessage.get(5).floatValue();
     // println(shipPos.y + " : " + shipPos.z);
    }
  }


  public void start() {
  }
  public void stop()
  {
  }
  public void draw() {

    background(0, 0, 0);


    image(bgImage, 0, 0, width, height);
    textFont(font, 15);
    fill(255, 255, 0);

    text("Docking Clamp: " + (clamped == true ? "Engaged" : "Disengaged"), 60, 110);
    text("Undercarriage: " + undercarriageStrings[undercarriageState], 60, 130);
    text("Bay Gravity: " + (bayGravity == true ? "On" : "Off"), 60, 150);
    if (landed) {
      text("Floor Contact", 60, 170);
    }

    pushMatrix();

    PVector lerpPos = new PVector(0, 0, 0);
    lerpPos.x = lerp(lastShipPos.z, shipPos.z, (millis() - lastPosUpdate) / 200.0f);
    lerpPos.y = lerp(lastShipPos.y, shipPos.y, (millis() - lastPosUpdate) / 200.0f);

    int screenX = (int)map(lerpPos.x, .19, -.225, 210, 790);
    int screenY = (int)map(lerpPos.y, .06, -0.13, 390, 575);
    translate(screenX, screenY);
    //scale(0.5,0.5);

    rotate(-CurveAngle(lastRotation, shipRot.z ,(millis() - lastPosUpdate) / 200.0f));
    translate(-shipImg.width / 4, -shipImg.height/4);
    
    
    if(undercarriageState == 3){
      tint(255,0,0);
      image(feetImg, -12, 140, feetImg.width/2, feetImg.height/2);
    } else if (undercarriageState == 2){
      tint(0,255,0);
      image(feetImg, -12, 140, feetImg.width/2, feetImg.height/2);
      
    } else if (undercarriageState == 1){
      noTint();
      image(feetImg, -12, 140, feetImg.width/2, feetImg.height/2);
    }
   
    noTint();
    image(shipImg, 0, 0, shipImg.width/2, shipImg.height/2);
    
    popMatrix();
  }


  public void serialEvent(String evt) {
  }
  
  public float CurveAngle(float start, float end, float step) 
{ 
  float from = radians(start);
  float to = radians(end);
  // Ensure that 0 <= angle < 2pi for both "from" and "to" 
  while(from < 0) 
    from += TWO_PI; 
  while(from >= TWO_PI) 
    from -= TWO_PI; 
 
  while(to < 0) 
    to += TWO_PI; 
  while(to >= TWO_PI) 
    to -= TWO_PI; 
   
  if(abs(from-to) < PI) 
  { 
    // The simple case - a straight lerp will do. 
    return lerp(from, to, step); 
  } 
 
  // If we get here we have the more complex case. 
  // First, increment the lesser value to be greater. 
  if(from < to) 
    from += TWO_PI; 
  else 
    to += TWO_PI; 
 
  float retVal = lerp(from, to, step); 
   
  // Now ensure the return value is between 0 and 2pi 
  if(retVal >= TWO_PI) 
    retVal -= TWO_PI; 
  return retVal; 
} 
  
  
  
}

