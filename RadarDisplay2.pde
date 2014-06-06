import java.util.Iterator;
import java.util.Map;

public class RadarDisplay implements Display {
  PFont font;
  Object lock = new Object();
  PImage overlayImage, indicatorImage;
  int sensorPower = 2;
  int propulsionPower = 2;
  RadarObject targetted;
  float zoomLevel = 0.1f;
  float maxDist = 0.0f;

  //HashMap radarList = new HashMap();

  RadarObject[] radarList = new RadarObject[100];
  RadarObject r = new RadarObject();

  //screen space 2d vector representing the direction the pilot should fly to get to the targetted object
  PVector guideVector = new PVector(0, 0);
  PVector tempVec = new PVector(0, 0);
  boolean useGuides = true;
  PImage guideArrow;

  int sectorX, sectorY, sectorZ;

  public RadarDisplay() {
    font = loadFont("HanzelExtendedNormal-48.vlw");
    overlayImage = loadImage("overlayImage.png");
    indicatorImage = loadImage("indicator.png");
    for (int i = 0; i < 100; i++) {
      radarList[i] = new RadarObject();
      radarList[i].active = false;
    }
    guideArrow = loadImage("guideArrowLeft.png");
    sectorX = sectorY = sectorZ = 0;
  }

  public void setSector(int x, int y, int z) {
    sectorX = x;
    sectorY = y;
    sectorZ = z;
  }


  public void start() {
  }
  public void stop() {
  }

  //FFUUU P2
  public float heading(float x, float y) {
    float angle = (float) Math.atan2(-y, x);
    return -1*angle;
  }

  public void draw() {
    background(0, 0, 0);
    zoomLevel = 0.5f; //map(mouseY, 0, height, 0.01f, 1.0f);
    drawRadar();
  }

  public void serialEvent(String evt) {
  }


  public void drawGuides() {
    pushMatrix();
    translate(934, 645);
    noFill();

    stroke(255);
    strokeWeight(2);
    fill(0);
    rect(-50, -50, 100, 130);
    if (guideVector.mag() < 0.05f ) {
      fill(0, 125, 0);
    } 
    if (!useGuides) {
      fill(0);
    }
    ellipse(0, 0, 80, 80);
    fill(255);
    if (useGuides) {
      line(0, 0, guideVector.x * 100.0f, guideVector.y * 100.0f);
    }
    textFont(font, 12);
    fill(255);
    text(" PILOT\r\nASSIST", -30, 55);
    popMatrix();

    if (useGuides == false) { 
      return ;
    }
    pushMatrix();

    //left is at 28,326
    if (guideVector.x < 0) {
      tint(255, 255, 255, (int)map(abs(guideVector.x), 0, 1, 0, 255));

      image(guideArrow, 28, 326);
    } 
    else {
      tint(255, 255, 255, (int)map(guideVector.x, 0, 1, 0, 255));
      translate(994, 439);
      rotate(radians(180));

      image(guideArrow, 0, 0);
    }
    popMatrix();
    pushMatrix();
    if (guideVector.y < 0) {
      tint(255, 255, 255, (int)map(abs(guideVector.y), 0, 1, 0, 255));
      translate(570, 68);
      rotate(radians(90));

      image(guideArrow, 0, 0);
    } 
    else {
      tint(255, 255, 255, (int)map(guideVector.y, 0, 1, 0, 255));
      translate(455, 742);
      rotate(radians(-90));

      image(guideArrow, 0, 0);
    }


    popMatrix();

    noTint();
  }


  public void drawRadar() {

    pushMatrix();
    // ortho();
    lights();
    ambientLight(255, 255, 255);
    noTint();

    drawAxis((int)((millis() % 1750.0f) / 200));


    strokeWeight(1);
    stroke(0, 0, 0);

    //use this to calculate which target is most distant from the ship, scale the zoom level based on this

    fill(255, 255, 0, 255);
    sphere(1);
    fill(0, 0, 255);
    zoomLevel = map(maxDist, 0, 5000, 0.8, 0.2);
    scale(zoomLevel);
    // println(zoomLevel);
    maxDist = 0;
    float distanceToShip = 0;
    synchronized(lock) {
      for (int i = 0; i < 100; i++) {

        RadarObject rItem = radarList[i];
        if (rItem.active == true) {
          pushMatrix();

          PVector newPos = rItem.lastPosition;

          newPos.x = lerp(rItem.lastPosition.x, rItem.position.x, (millis() - rItem.lastUpdateTime) / 250.0f );
          newPos.y = lerp(rItem.lastPosition.y, rItem.position.y, (millis() - rItem.lastUpdateTime) / 250.0f);
          newPos.z = lerp(rItem.lastPosition.z, rItem.position.z, (millis() - rItem.lastUpdateTime) / 250.0f);

          //check if this is the farthest target from the ship, used to calculate scaling
          rItem.distance = newPos.mag();
          if (rItem.distance > maxDist) {
            maxDist = rItem.distance;
          }

          //add some random jiggle into the target if its too far away
          if (rItem.distance > 1000) {
            newPos.x += random(-20, 20);
            newPos.y += random(-20, 20);
            newPos.z += random(-20, 20);
          }

          stroke(0, 255, 0);
          //line to base
          //line(-r.position.x, 0, r.position.z, -r.position.x, -r.position.y, r.position.z);
          line(-newPos.x, 0, newPos.z, -newPos.x, -newPos.y, newPos.z);
          //circle at base       
          pushMatrix();
          translate(-newPos.x, 0, newPos.z);
          rotateX(radians(-90));
          fill(0, 50, 0);
          strokeWeight(1);

          // ellipse(0, 0, 20, 20);
          rect(-10, 10, 20, 20);
          popMatrix();

          //sphere and text

          // translate(-r.position.x, -r.position.y, r.position.z);
          rItem.screenPos.x = screenX(-newPos.x, -newPos.y, newPos.z);
          rItem.screenPos.y = screenY(-newPos.x, -newPos.y, newPos.z);
          translate(-newPos.x, -newPos.y, newPos.z);    
          noStroke();
          int alpha = (int)lerp(255, 0, (millis() - rItem.lastUpdateTime) / 250.0f);
          color c = rItem.displayColor;
          fill (c);


          //sphere(10);
          if (newPos.y >= 0) {



            image(indicatorImage, -16, -16, 32, 32);
          } 
          else {
            scale(1, -1);
            image(indicatorImage, -16, -16, 32, 32);
          }
          popMatrix();

          //workout what needs cleaning

          if (rItem.lastUpdateTime < millis() - 500.0f) {
            //its dead jim
            //removeList.add(new Integer(i));
            println("removing id: " + rItem.id);
            rItem.active = false;
          }
        }
      }
      popMatrix();


      //now do text and other screen space stuff
      targetted = null;
      for (int i = 0; i < 100; i++) {

        RadarObject rItem = radarList[i];
        if (rItem.active) {

          textFont(font, 13);

          if (rItem.distance > 1000) {
            StringBuilder s = new StringBuilder(rItem.name);
            for (int c = 0; c < (int)random(3,s.length()); c++) {
              s.setCharAt( (int)random(0, s.length()), (char)random(0, 255));
            }

            fill(40);
            text(s.toString(), rItem.screenPos.x + 5, rItem.screenPos.y + 10);
          } 
          else {
            fill(rItem.displayColor);
            text(rItem.name, rItem.screenPos.x + 5, rItem.screenPos.y + 10);
          }
          // textFont(font, 10);
          // text(r.statusText,r.screenPos.x + 5, r.screenPos.y + 20);

          if (rItem.targetted) {

            targetted = radarList[i];
            noFill();
            stroke(255, 255, 0);
            pushMatrix();
            translate(rItem.screenPos.x, rItem.screenPos.y);
            rotateZ(radians( (millis() / 10.0f) % 260));
            rect(-15, - 15, 30, 30);
            popMatrix();

            int midX = (int)( (660 - rItem.screenPos.x) * 0.33f );
            stroke(255, 255, 0);
            line(660, 190, rItem.screenPos.x + midX, 190);
            line(rItem.screenPos.x + midX, 190, rItem.screenPos.x, rItem.screenPos.y);
          }

          //if this target is "pinging" then draw a radiobeacon highlight
          Float f = rItem.getStat("pinging");
          noStroke();
          //strokeWeight(2.0);
          //stroke(255,255,0);
          if (f != null && f > 0.0) {
            int radius = (int)map(millis() % 3000, 0, 3000, 0, 100);
            int alpha = (int)map(millis() % 3000, 0, 3000, 255, 0);
            fill(255, 255, 0, alpha);
            ellipse(rItem.screenPos.x, rItem.screenPos.y, radius, radius);

            radius = (int)map((millis() + 1500) % 3000, 0, 3000, 0, 100);
            alpha = (int)map((millis() + 1500)  % 3000, 0, 3000, 255, 0);
            fill(255, 255, 0, alpha);
            ellipse(rItem.screenPos.x, rItem.screenPos.y, radius, radius);
          }
        }
      }
    }
    //turn on pilot guides if we have a highlighted target
    //turn off if not
    //
    if (targetted != null) {
      useGuides = true;
      tempVec.x = targetted.position.x;
      tempVec.y = targetted.position.z;
      float yRotation = (270 + degrees(heading(tempVec.x, tempVec.y)) )% 360;
      if (yRotation > 0 && yRotation < 180) {  //right hand side of ship
        guideVector.x = -map(yRotation, 0, 180, 0, 1);
      } 
      else {
        guideVector.x = -map(yRotation, 180, 360, -1, 0);
      }
      tempVec.x = targetted.position.z;
      tempVec.y = targetted.position.y;

      float xRotation =  degrees(heading(tempVec.x, tempVec.y));
      if (xRotation > -90 && xRotation < 0) {
        guideVector.y = -map(xRotation, -90, 0, 1, 0);
      } 
      else if (xRotation < 90 && xRotation > 0) {
        guideVector.y = -map(xRotation, 90, 0, -1, 0);
      }
    } 
    else {
      useGuides = false;
    }

    //popMatrix();
    noLights();
    hint(DISABLE_DEPTH_TEST);
    image(overlayImage, 0, 0, width, height);

    textFont(font, 18);
    fill(0, 255, 255);


    text("Sensor" + (sensorPower * 33) + "%", 680, 600);
    text("Prop" + (propulsionPower * 33) + "%", 680, 630);

    text("speed: " + (int)shipState.shipVelocity, 680, 660);

    fill(255, 255, 0);
    if (targetted != null) {
      textFont(font, 20);
      text(targetted.name, 675, 70);
      textFont(font, 15);
      text(targetted.statusText, 675, 100);
    }
    text("Sector (" + sectorX + "," + sectorY + "," + sectorZ + ")", 41, 740);

    drawGuides();
  }

  public int findRadarItemById(int id) {
    for (int i = 0; i < 100; i++) {
      if (radarList[i].id == id) {
        return i;
      }
    } 
    return -1;
  }

  public int getNewRadarItem() {
    for (int i = 0; i < 100; i++) {
      if (radarList[i].active == false) {
        return i;
      }
    }
    return -1;
  }


  public void drawAxis(int highlight) {
    translate(width/2, height/2);
    // pushMatrix();
    //scale(zoomLevel * 2.0);
    rotateX(radians(345)); //326
    // rotateY(radians(225)); //216
    rotateY(radians(180));
    //x axis
    stroke(128, 0, 0);
    strokeWeight(1);
    line(-1000, 0, 0, 1000, 0, 0);
    line(1000, 0, -10, 1000, 0, 10);




    pushMatrix();
    rotateX(radians(-90));
    noFill();
    strokeWeight(1);
    drawRadarCircle(5, 200, highlight);

    for (int delay = 0; delay < 5; delay++) {

      float radius = ((millis()  + (delay*1000 )) / 5.0f) % 1000 ;
      stroke(0, 255, 0, map(radius, 0, 1000, 255, 0));
      ellipse(0, 0, radius, radius);
    }  



    popMatrix();

    //z axis
    stroke(0, 0, 128);
    line(0, 0, -1000, 0, 0, 1000);
    line(-10, 0, 1000, 10, 0, 1000);

    stroke(0, 128, 0);
    //  popMatrix();
  }

  void drawRadarCircle( int num, int sizing, int highlight) {
    int radius = sizing;
    for (int i = 0; i < num; i ++) {
      if (i == highlight) {
        stroke(0, 30, 0);
      } 
      else {
        stroke(0, 30, 0);
      }
      ellipse(0, 0, radius, radius);
      radius += sizing;
    }
    stroke(0, 255, 0);
  }


  /* incoming osc message are forwarded to the oscEvent method. */
  public void oscMessage(OscMessage theOscMessage) {

    /* print the address pattern and the typetag of the received OscMessage */

    if (theOscMessage.checkAddrPattern("/radar/update")) {
      synchronized(lock) {
        //get the id

        int id = theOscMessage.get(0).intValue();
        int rId = findRadarItemById(id);
        boolean newItem = false;
        if (rId == -1) {
          rId = getNewRadarItem();
          println("new item : " + rId + " - " + id);
          if (theOscMessage.get(1).stringValue().equals("INCOMING DEBRIS")) {
            consoleAudio.playClip("collisionAlert");
          } 
          else {

            consoleAudio.playClip("newTarget");
          }

          newItem = true;
        }        

        radarList[rId].id = id;
        radarList[rId].active = true;

        radarList[rId].lastUpdateTime = millis();
        radarList[rId].name = theOscMessage.get(1).stringValue();
        if (newItem) {
          radarList[rId].lastPosition.x = theOscMessage.get(2).floatValue();
          radarList[rId].lastPosition.y = theOscMessage.get(3).floatValue();
          radarList[rId].lastPosition.z = theOscMessage.get(4).floatValue();
          radarList[rId].clearStats();
        } 
        else {
          radarList[rId].lastPosition.x = radarList[rId].position.x;
          radarList[rId].lastPosition.y = radarList[rId].position.y;
          radarList[rId].lastPosition.z = radarList[rId].position.z;
        }

        radarList[rId].position.x = theOscMessage.get(2).floatValue();        
        radarList[rId].position.y = theOscMessage.get(3).floatValue();
        radarList[rId].position.z = theOscMessage.get(4).floatValue();
        // println("1:" + radarList[rId].position);
        //println("2:" + radarList[rId].lastPosition);

        String colour = theOscMessage.get(5).stringValue();
        String[] splitColour = colour.split(":");
        radarList[rId].displayColor = color (  Float.parseFloat(splitColour[0]) * 255, 
        Float.parseFloat(splitColour[1]) * 255, 
        Float.parseFloat(splitColour[2]) * 255);
        // radarList[rId].lastUpdateTime = millis();

        radarList[rId].statusText = theOscMessage.get(6).stringValue();
        radarList[rId].targetted = theOscMessage.get(7).intValue() == 1 ? true : false;

        //now unpack the stat string
        String statString = theOscMessage.get(8).stringValue();
        String[] pairs = statString.split(",");
        for (String p : pairs) {          
          String[] vals = p.split(":");
          radarList[rId].setStat(vals[0], Float.parseFloat(vals[1]));
        }
      }
    } 
    else if (theOscMessage.checkAddrPattern("/control/subsystemstate") == true) {


      sensorPower = theOscMessage.get(2).intValue() ;
      propulsionPower = theOscMessage.get(0).intValue() ;
    }
  }
}

