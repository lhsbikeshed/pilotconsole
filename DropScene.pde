/* change this scene to show the altitude and predicted death time*/
public interface Display {

  public void draw();
  public void oscMessage(OscMessage theOscMessage);
  public void start();
  public void stop();
  public void serialEvent(String content);
  
}

public class DropDisplay implements Display {

  PImage bg, structFailOverlay, fireballImg, turbulenceImg;
  PFont font;

  Point[] labelPos = new Point[6];
  float[] temps = new float[6];

  float altitude = 10000;
  float lastAltitude = 10000;
  long lastUpdate = 0;
  boolean structFail = false;
  
  PVector fireVec = new PVector(0,0,0);
  long turbulenceTime = 0;
  
  public DropDisplay() {
    bg = loadImage("reentry.png");
    font = loadFont("HanzelExtendedNormal-48.vlw");
    structFailOverlay = loadImage("structuralFailure.png");
    fireballImg = loadImage("fireball.png");
    turbulenceImg = loadImage("turbulence.png");

    labelPos[0] = new Point(217, 307);
    labelPos[1] = new Point(345, 563);
    labelPos[2] = new Point(508, 386);
    labelPos[3] = new Point(819, 384);
    labelPos[4] = new Point(759, 224);
    labelPos[5] = new Point(768, 610);
  }

  public void start() {
    structFail = false;

  }

  public void stop() {
  }

  public void draw() {
    background(0);
    noTint();
    fill(255, 255, 255);
    image(bg, 0, 0,width,height);
    fill(255, 255, 255);
    textFont(font, 60);
    float alt = lerp(lastAltitude, altitude, (millis() - lastUpdate) / 250.0f);
    text((int)alt + "m", 448, 704);
    textFont(font, 30);
    for (int t = 0; t < 6; t++) {
      Point p = labelPos[t];
      if (temps[t] > 200) {
        fill(255, 0, 0);
      } 
      else if ( temps[t] > 100 && temps[t] <=200) {
        fill(255, 255, 0);
      } 
      else {
        fill(0, 255, 0);
      }
      text((int)temps[t] + "c", p.x, p.y);
    }
    
    
    
    if(fireVec.z > 0){
      tint(255, (int)(fireVec.z * 255));
      int randX = (int)random(fireVec.z * 5);
      int randY = (int)random(fireVec.z * 5);
      image(fireballImg, 643 + randX, 231 + randY, fireballImg.width / 2, fireballImg.height / 2);
    }
    if(fireVec.z < 0){
      tint(255, (int)(abs(fireVec.z * 255)));
      int randX = (int)random(abs(fireVec.z * 5));
      int randY = (int)random(abs(fireVec.z * 5));
      pushMatrix();
      translate(643 + randX, 585 + randY);
      scale(1, -1);
      image(fireballImg, 0, 0, fireballImg.width / 2, fireballImg.height / 2);
      popMatrix();
    }
    if(fireVec.x > 0){ //right
      tint(255, (int)(fireVec.x * 255));
      int randX = (int)random(fireVec.x * 5);
      int randY = (int)random(fireVec.x * 5);
      pushMatrix();
      translate(850 + randX, 325 + randY);
      rotate(radians(90));
      image(fireballImg, 0, 0, fireballImg.width / 2, fireballImg.height / 2);
      popMatrix();
    }
    
    if(fireVec.x < 0){ //left
      tint(255, abs((int)(fireVec.x * 255)));
      int randX = abs((int)random(fireVec.x * 5));
      int randY = abs((int)random(fireVec.x * 5));
      pushMatrix();
      translate(587 + randX, 498 + randY);
      rotate(radians(-90));
      image(fireballImg, 0, 0, fireballImg.width / 2, fireballImg.height / 2);
      popMatrix();
    }
     if(fireVec.y > 0){ //top
      tint(255, (int)(fireVec.y * 255));
      int randX = (int)random(fireVec.y * 5);
      int randY = (int)random(fireVec.y * 5);
      pushMatrix();
      translate(204 + randX, 324 + randY);
     // rotate(radians(90));
      image(fireballImg, 0, 0, fireballImg.width / 2, fireballImg.height / 2);
      popMatrix();
    }
    
     if(fireVec.y < 0){ //top
      tint(255, abs((int)(fireVec.y * 255)));
      int randX = abs((int)random(fireVec.y * 5));
      int randY = abs((int)random(fireVec.y * 5));
      pushMatrix();
      translate(362 + randX, 540 + randY);
      rotate(radians(-180));
      image(fireballImg, 0, 0, fireballImg.width / 2, fireballImg.height / 2);
      popMatrix();
    }
    noTint();
    
    if(turbulenceTime < millis() && millis() < turbulenceTime + 1500){
      
        image(turbulenceImg, 155, 410);
      
    }
    
    if (structFail) { //show the "structural failure" warning
     
      image(structFailOverlay, 128, 200);
    }
  }

  public void oscMessage(OscMessage theOscMessage) {
    //println(theOscMessage);
    if (theOscMessage.checkAddrPattern("/scene/drop/statupdate")==true) {
      lastUpdate = millis();
      lastAltitude = altitude;
      altitude = theOscMessage.get(0).floatValue();
      for (int t = 0; t < 6; t++) {
        temps[t] = theOscMessage.get(1+t).floatValue();
      }
      fireVec.x = theOscMessage.get(7).floatValue();
      fireVec.y = theOscMessage.get(8).floatValue();
      fireVec.z = theOscMessage.get(9).floatValue();
      println(fireVec.z);
    } else if (theOscMessage.checkAddrPattern("/scene/drop/structuralFailure")==true) {
      structFail = true;
    } else if (theOscMessage.checkAddrPattern("/scene/drop/turbulenceWarning")){
      turbulenceTime = millis();
      consoleAudio.playClip("bannerPopup");
    }
  }
  
    public void serialEvent(String content){}
}

