public class RadarObject { 
  public boolean active = false;
  public PVector position = new PVector();
  public PVector lastPosition = new PVector();
  public PVector screenPos = new PVector();
  public String name = "";
  public String statusText = "";
  public int id = 0;
  public boolean targetted = false;
  
  public float bearing = 0.0f;
  public float elevation = 0.0f;
  public float distance = 0.0f;
  
  public color displayColor = color(0,255,0);
  
  public long lastUpdateTime = 0;

  public RadarObject(){}
}

