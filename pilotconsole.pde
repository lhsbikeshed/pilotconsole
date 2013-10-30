import processing.serial.*;

import java.awt.Point;
import oscP5.*;
import netP5.*;

import java.util.Hashtable;

//CHANGE ME
boolean testMode = true;





//leave this alone
String serverIP = "127.0.0.1";    
boolean joystickTestMode = true;




//--------------------------
OscP5 oscP5;

DropDisplay dropDisplay;
WarpDisplay warpDisplay;
RadarDisplay2 radarDisplay;
BootDisplay bootDisplay;
LaunchDisplay launchDisplay;

Joystick joy;

long deathTime = 0;

ShipState shipState = new ShipState();

PFont font;



//serial stuff
Serial serialPort;
String serialBuffer = "";
String lastSerial = "";
NetAddress myRemoteLocation;
String[] messageMapping = {  
  "/system/jump/state", 
  "/system/propulsion/state", 
  "/system/misc/blastShield", 
  "/system/misc/extlight", 
  "/system/undercarriage/state", 
  "/system/jump/doJump"
};


//display handling
Hashtable<String, Display> displayMap = new Hashtable<String, Display>();
Display currentScreen;
BannerOverlay bannerSystem = new BannerOverlay();



int systemPower = 2;
long heartBeatTimer = -1;


int damageTimer = -1000;
PImage noiseImage;

float lastOscTime = 0;


/* scene to display mapping
 * 0 -> launch -> launchdisplay
 * 1 -> warp -> warpDisplay
 * 2 -> drop -> DropScene
 * 3 -> debriswar -> radardisplay
 */
void setup() {

  if (testMode) {
    serverIP = "127.0.0.1";    
    joystickTestMode = true;
    shipState.poweredOn = true;
  } 
  else {
    serverIP = "10.0.0.100";
    joystickTestMode = false;
    shipState.poweredOn = false;
    frame.setLocation(0,0);
  }


  size(1024, 768, P3D);
  frameRate(25);
  serialPort = new Serial(this, "COM4", 115200);
  oscP5 = new OscP5(this, 12002);
  myRemoteLocation = new NetAddress(serverIP, 12000);
  dropDisplay = new DropDisplay();
  radarDisplay = new RadarDisplay2();
  warpDisplay = new WarpDisplay();
  launchDisplay = new LaunchDisplay();

  joy = new Joystick(oscP5, this, joystickTestMode);

  /* displayList[0] = launchDisplay;
   displayList[1] = warpDisplay;
   displayList[2] = dropDisplay;
   displayList[3] = radarDisplay;*/

  //TEST
  displayMap.put("radar", radarDisplay);
  displayMap.put("drop", dropDisplay);
  displayMap.put("docking", launchDisplay);
  displayMap.put("hyperspace", warpDisplay);
  displayMap.put("selfdestruct", new DestructDisplay());
  displayMap.put("pwned", new PwnedDisplay());
  currentScreen = radarDisplay;
  ;

  bootDisplay = new BootDisplay();
  displayMap.put("boot", bootDisplay);

  font = loadFont("HanzelExtendedNormal-48.vlw");


  noiseImage = loadImage("noise.png");
  setJumpLightState(false);

  /*sync to current game screen*/
  OscMessage myMessage = new OscMessage("/game/Hello/PilotStation");  
  oscP5.send(myMessage, myRemoteLocation);
}


void changeDisplay(Display d) {
  currentScreen.stop();
  currentScreen = d;
  currentScreen.start();
}


void draw() {
  noSmooth();
  float s = shipState.shipVel.mag();
  shipState.shipVelocity = lerp(shipState.lastShipVel, s, (millis() - lastOscTime) / 250.0f);
  while (serialPort.available () > 0) {
    char val = serialPort.readChar();
    if (val == ',') {
      //get first char
      dealWithSerial(serialBuffer);
      serialBuffer = "";
    } 
    else {
      serialBuffer += val;
    }
  }



  background(0, 0, 0);

  if (shipState.areWeDead) {
    fill(255, 255, 255);
    if (deathTime + 2000 < millis()) {
      textFont(font, 60);
      text("YOU ARE DEAD", 50, 300);
      textFont(font, 20);
      int pos = (int)textWidth(shipState.deathText);
      text(shipState.deathText, (width/2) - pos/2, 340);
    }
  }   
  else {
    //run joystick->osc updates
    joy.update();
    if (shipState.poweredOn) {
      //displayList[currentDisplay].draw();

      currentScreen.draw();
      
    } 
    else {
      if (shipState.poweringOn) {
        bootDisplay.draw();
        if (bootDisplay.isReady()) {
          shipState.poweredOn = true;
          shipState.poweringOn = false;
          /* sync current display to server */
          OscMessage myMessage = new OscMessage("/game/Hello/PilotStation");  
          oscP5.send(myMessage, new NetAddress(serverIP, 12000));
        }
      }
    }
    bannerSystem.draw();
  }

  if (heartBeatTimer > 0) {
    if (heartBeatTimer + 400 > millis()) {
      int a = (int)map(millis() - heartBeatTimer, 0, 400, 255, 0);
      fill(0, 0, 0, a);
      rect(0, 0, width, height);
    } 
    else {
      heartBeatTimer = -1;
    }
  }


  if ( damageTimer + 1000 > millis()) {
    if (random(10) > 3) {
      image(noiseImage, 0, 0, width, height);
    }
  }
}

void setJumpLightState(boolean state) {
  if (state == true && shipState.jumpState == false) {
    serialPort.write('B');
    shipState.jumpState = true;
  } 
  else if (state == false && shipState.jumpState == true) {
    serialPort.write('b');
    shipState.jumpState = false;
  }
}

void oscEvent(OscMessage theOscMessage) {
  lastOscTime = millis();
  // println(theOscMessage);
  if (theOscMessage.checkAddrPattern("/scene/change")==true) {
    setJumpLightState(false);
  }
  else if (theOscMessage.checkAddrPattern("/system/reactor/stateUpdate")==true) {
    int state = theOscMessage.get(0).intValue();
    String flags = theOscMessage.get(1).stringValue();
    String[] fList = flags.split(";");
     //reset flags
    bootDisplay.brokenBoot = false;
    for (String f : fList){
      if(f.equals("BROKENBOOT")){
        println("BROKEN BOOT");
        bootDisplay.brokenBoot = true;
      }
    }
    
    if (state == 0) {
      shipState.poweredOn = false;
      shipState.poweringOn = false;
      bootDisplay.stop();
      bannerSystem.cancel();
      
    } 
    else {


      if (!shipState.poweredOn ) {
        shipState.poweringOn = true;
        changeDisplay(bootDisplay);
        
      }
    }
  } 
  else if (theOscMessage.checkAddrPattern("/scene/youaredead") == true) {
    //oh noes we died
    shipState.areWeDead = true;
    shipState.deathText = theOscMessage.get(0).stringValue();
    deathTime = millis();
  } 
  else if (theOscMessage.checkAddrPattern("/game/reset") == true) {

    currentScreen.stop();
    currentScreen = launchDisplay;
    currentScreen.start();
    shipState.areWeDead = false;
    setJumpLightState(false);
    shipState.poweredOn = false;
    shipState.poweringOn = false;
  } 
  else if (theOscMessage.checkAddrPattern("/ship/jumpStatus") == true) {
    int v = theOscMessage.get(0).intValue();
    if (v == 0) {
      setJumpLightState(false);
    } 
    else if (v == 1) {
      setJumpLightState(true);
    }
  } 
  else if (theOscMessage.checkAddrPattern("/control/subsystemstate") == true) {
    systemPower = theOscMessage.get(1).intValue() + 1;
    // displayList[currentDisplay].oscMessage(theOscMessage);
    currentScreen.oscMessage(theOscMessage);
    setJumpLightState(false);
  } 
  else if (theOscMessage.checkAddrPattern("/system/control/controlState") == true) {
    boolean state = theOscMessage.get(0).intValue() == 0 ? true : false;
    joy.setEnabled (state);
    println("Set control state : " + state);
    if(state == false){
      bannerSystem.setSize(700, 200);
      bannerSystem.setTitle("NOTICE");
      bannerSystem.setText("AUTOPILOT ENGAGED\r\n CONTROLS DISABLED");
      bannerSystem.displayFor(36000000);
    } else {
      bannerSystem.cancel();
    }
  }
  else if (theOscMessage.checkAddrPattern("/pilot/powerState") == true) {

    if (theOscMessage.get(0).intValue() == 1) {
      shipState.poweredOn = true;
      shipState.poweringOn = false;
      bootDisplay.stop();
    } 
    else {
      shipState.poweredOn = false;
      shipState.poweringOn = false;
      setJumpLightState(false);
    }
  }
  else if (theOscMessage.checkAddrPattern("/ship/effect/heartbeat") == true) {
    heartBeatTimer = millis();
  } 
  else if (theOscMessage.checkAddrPattern("/ship/damage")==true) {

    damageTimer = millis();
  } 
  else if (theOscMessage.checkAddrPattern("/ship/transform") == true) {
    shipState.shipPos.x = theOscMessage.get(0).floatValue();
    shipState.shipPos.y = theOscMessage.get(1).floatValue();
    shipState.shipPos.z = theOscMessage.get(2).floatValue();

    shipState.shipRot.x = theOscMessage.get(3).floatValue();
    shipState.shipRot.y = theOscMessage.get(4).floatValue();
    shipState.shipRot.z = theOscMessage.get(5).floatValue();

    shipState.shipVel.x = theOscMessage.get(6).floatValue();
    shipState.shipVel.y = theOscMessage.get(7).floatValue();
    shipState.shipVel.z = theOscMessage.get(8).floatValue();

    shipState.lastShipVel = shipState.shipVelocity;
  } 
  else if ( theOscMessage.checkAddrPattern("/clientscreen/PilotStation/changeTo") ) {
    String changeTo = theOscMessage.get(0).stringValue();
    try {
      Display d = displayMap.get(changeTo);
      println("found display for : " + changeTo);
      changeDisplay(d);
    } 
    catch(Exception e) {
      println("no display found for " + changeTo);
      changeDisplay(radarDisplay);
    }
  } 
  else if (theOscMessage.checkAddrPattern("/clientscreen/showBanner") ) {
    String title = theOscMessage.get(0).stringValue();
    String text = theOscMessage.get(1).stringValue();
    int duration = theOscMessage.get(2).intValue();

    bannerSystem.setSize(700, 300);
    bannerSystem.setTitle(title);
    bannerSystem.setText(text);
    bannerSystem.displayFor(duration);
  } else if (theOscMessage.checkAddrPattern("/system/boot/diskNumbers") ){
    
    int[] disks = { theOscMessage.get(0).intValue(), theOscMessage.get(1).intValue(), theOscMessage.get(2).intValue() };
    println(disks);
    bootDisplay.setDisks(disks);
  } else if (theOscMessage.checkAddrPattern("/ship/sectorChanged") ){
    radarDisplay.setSector(   theOscMessage.get(0).intValue(), 
                              theOscMessage.get(1).intValue(), 
                              theOscMessage.get(2).intValue());
  } else {
    //displayList[currentDisplay].oscMessage(theOscMessage);
    currentScreen.oscMessage(theOscMessage);
  }
}

void dealWithSerial(String vals) {




  char p = vals.charAt(0);

  if (p == 't') {
    int th = Integer.parseInt(vals.substring(1));
    float t = map(th, 0, 255, 0, 1.0);
    if (t < 0.1) { 
      t = 0;
    }
    //map throttle to 0-1 float, set throttle
    joy.throttle = t;
  } 
  else {

    int sw = Integer.parseInt("" + p);
    int val = Integer.parseInt("" + vals.charAt(1));
    println("sw : " + sw + "  " + val);
    if (shipState.poweredOn == false) { 
      return;
    }
    OscMessage myMessage = new OscMessage(messageMapping[sw]);
    myMessage.add(val);
    oscP5.send(myMessage, myRemoteLocation);
  }
}

void mouseClicked() {
  println (":" + mouseX + "," + mouseY);
}


public class ShipState {

  public boolean poweredOn = true;
  public boolean poweringOn = false ;
  public boolean areWeDead = false;
  public String deathText = "";
  public boolean jumpState = false;

  public PVector shipPos = new PVector(0, 0, 0);
  public PVector shipRot = new PVector(0, 0, 0);
  public PVector shipVel = new PVector(0, 0, 0);

  public float shipVelocity = 0;
  public float lastShipVel = 0;

  public ShipState() {
  };

  public void resetState() {
  }
}




