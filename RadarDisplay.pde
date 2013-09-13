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
 
  //HashMap radarList = new HashMap();
  ArrayList<RadarObject> radarList = new ArrayList(0);

  public RadarDisplay() {
    font = loadFont("HanzelExtendedNormal-48.vlw");
    overlayImage = loadImage("overlayImage.png");
    indicatorImage = loadImage("indicator.png");
  }


  public void start() {
  }
  public void stop() {
  }


  public void draw() {
    background(0,0,0);
   zoomLevel = 0.5f; //map(mouseY, 0, height, 0.01f, 1.0f);
      drawRadar();
      
  }

public void serialEvent(String evt){
  }

  

  public void drawRadar() {

    pushMatrix();
    // ortho();
    lights();
    ambientLight(255, 255, 255);

    drawAxis((int)((millis() % 1750.0f) / 200));


    strokeWeight(1);
    stroke(0, 0, 0);


    fill(255, 255, 0, 255);
    sphere(1);
    fill(0, 0, 255);
    scale(zoomLevel);
    synchronized(lock) {
      for (Iterator<RadarObject> it = radarList.iterator(); it.hasNext();) {

        RadarObject r = it.next();
        pushMatrix();

        PVector newPos = r.lastPosition;
        
        newPos.x = lerp(r.lastPosition.x, r.position.x, (millis() - r.lastUpdateTime) / 250.0f );
        newPos.y = lerp(r.lastPosition.y, r.position.y, (millis() - r.lastUpdateTime) / 250.0f);
        newPos.z = lerp(r.lastPosition.z, r.position.z, (millis() - r.lastUpdateTime) / 250.0f);
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

        ellipse(0, 0, 20, 20);
        popMatrix();
        
        //sphere and text
        
       // translate(-r.position.x, -r.position.y, r.position.z);
        r.screenPos.x = screenX(-newPos.x,-newPos.y,newPos.z);
        r.screenPos.y = screenY(-newPos.x,-newPos.y,newPos.z);
        translate(-newPos.x,-newPos.y,newPos.z);    
        noStroke();
        int alpha = (int)lerp(255, 0, (millis() - r.lastUpdateTime) / 250.0f);
        color c = r.displayColor;
        fill (c);

        //sphere(10);
        if(newPos.y >= 0){
          
         
          scale(1,-1);
          image(indicatorImage,-16, -16,32,32);
        } else {
          image(indicatorImage,-16,-16,32,32);
        }
        popMatrix();

        //workout what needs cleaning

        if (r.lastUpdateTime < millis() - 500.0f) {
          //its dead jim
          //removeList.add(new Integer(i));
          println("removing id: " + r.id);
          it.remove();
        }
      }
      popMatrix();
      targetted = null;
      for (Iterator<RadarObject> it = radarList.iterator(); it.hasNext();) {
        
        RadarObject r = it.next();
        fill(r.displayColor);
        textFont(font, 13);
        text(r.name, r.screenPos.x + 5, r.screenPos.y + 10);
       // textFont(font, 10);
       // text(r.statusText,r.screenPos.x + 5, r.screenPos.y + 20);
        
        if(r.targetted){
          targetted = r;
          noFill();
          stroke(255,255,0);
          pushMatrix();
          translate(r.screenPos.x, r.screenPos.y);
          rotateZ(radians( (millis() / 10.0f) % 260));
          rect(-15,- 15, 30,30);
          popMatrix();
          
          int midX = (int)( (660 - r.screenPos.x) * 0.33f );
          stroke(255,255,0);
          line(660,190, r.screenPos.x + midX, 190);
          line(r.screenPos.x + midX, 190, r.screenPos.x, r.screenPos.y);
          
          
        }
      }
    }
    
    //popMatrix();
    noLights();
    hint(DISABLE_DEPTH_TEST);
    image(overlayImage,0,0,width,height);
    
    textFont(font, 18);
    fill(0,255,255);
    text("Sensor Power:" + (sensorPower * 33) + "%", 680, 600);
    text("Propulsion Power:" + (propulsionPower * 33) + "%", 680, 630);
  
    text("speed: " + (int)shipState.shipVelocity, 680, 660);
    
    fill(255,255,0);
    if(targetted != null){
      textFont(font, 20);
      text(targetted.name, 675,70);
      textFont(font, 15);
      text(targetted.statusText, 675,100);
    }
    
    
  }
  public void drawAxis(int highlight) {
    translate(width/2, height/2);
    rotateX(radians(345)); //326
   // rotateY(radians(225)); //216
   rotateY(radians(180));
    //x axis
    stroke(128, 0, 0);
    strokeWeight(1);
    line(-1000, 0, 0, 1000, 0, 0);
    line(1000, 0, -10, 1000, 0, 10);
    pushMatrix();
    translate(-440,0,0);
    rotateY(radians(180));
    text("R", 0,0);
    popMatrix();
    pushMatrix();
    translate(440,0,0);
    rotateY(radians(180));
    text("L", 0,0);
    popMatrix();
    
    
    
    pushMatrix();
    rotateX(radians(-90));
    noFill();
    strokeWeight(1);
    drawRadarCircle(5, 200, highlight);
    
    for(int delay = 0; delay < 5; delay++){
      
      float radius = ((millis()  + (delay*1000 )) / 5.0f) % 1000 ;
      stroke(0,255,0, map(radius, 0, 1000, 255,0));
      ellipse(0,0, radius, radius);
    }  

    

    popMatrix();

    //z axis
    stroke(0, 0, 128);
    line(0, 0, -1000, 0, 0, 1000);
    line(-10, 0, 1000, 10, 0, 1000);
    pushMatrix();
    translate(0,0,440);
    rotateY(radians(180));
    text("F", 0,0);
    popMatrix();
    pushMatrix();
    translate(0,0,-440);
    rotateY(radians(180));
    text("B", 0,0);
    popMatrix();
    stroke(0, 128, 0);
    
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
        boolean updated = false;
        int id = theOscMessage.get(0).intValue();
        RadarObject r = null;
        RadarObject temp;
        int updateId = -1;
        for (int b = 0; b < radarList.size(); b++) {

          temp = (RadarObject)radarList.get(b);

          if (temp.id == id) {
            r = temp;
            updated = true;
            updateId = b;
          }
        }
        if (r == null) {
          r = new RadarObject();
          
        }

        r.id = id;
       // println(r.id);
        r.lastUpdateTime = millis();
        r.name = theOscMessage.get(1).stringValue();
        r.lastPosition.x = r.position.x;
        r.lastPosition.y = r.position.y;
        r.lastPosition.z = r.position.z;
        
        r.position.x = theOscMessage.get(2).floatValue();
        
        r.position.y = theOscMessage.get(3).floatValue();
        r.position.z = theOscMessage.get(4).floatValue();
       // println("1:" + r.position);
        //println("2:" + r.lastPosition);

        String colour = theOscMessage.get(5).stringValue();
        String[] splitColour = colour.split(":");
        r.displayColor = color (  Float.parseFloat(splitColour[0]) * 255, 
        Float.parseFloat(splitColour[1]) * 255, 
        Float.parseFloat(splitColour[2]) * 255);
       // r.lastUpdateTime = millis();
        
        r.statusText = theOscMessage.get(6).stringValue();
        r.targetted = theOscMessage.get(7).intValue() == 1 ? true : false;
        if (updated) {
          radarList.set(updateId, r);
        } 
        else {
          radarList.add(r);
        }
      }
    } else if (theOscMessage.checkAddrPattern("/control/subsystemstate") == true){
      

      sensorPower = theOscMessage.get(2).intValue() ;
      propulsionPower = theOscMessage.get(0).intValue() ;
    }
    
  }
}

