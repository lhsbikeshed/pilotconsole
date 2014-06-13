

public class CablePuzzleDisplay implements Display {
  
  PImage bannerImg;
  int time;
  
  PFont font;
  
  int blinkTime = 0;
  boolean blinker = false;
  
  public CablePuzzleDisplay(){
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bannerImg = loadImage("cablepuzzle/banner.png");
    
  }
  
  
  public void start(){
    joy.setEnabled(false);
    
  }
  public void stop(){
    
  }
  
  public void draw(){
    if(blinkTime + 1000 < millis()){
      blinker = !blinker;
      blinkTime = millis();
    }
    background(0,0,0);
    if(blinker){
      image(bannerImg, 247, 315);
    }
  }
  
  public void oscMessage(OscMessage msg){
    if(msg.checkAddrPattern("/system/cablePuzzle/puzzleComplete")){
      joy.setEnabled(true);
    }
    
  }

  public void serialEvent(String evt){}

  public void keyPressed(){}
  public void keyReleased(){}
}
