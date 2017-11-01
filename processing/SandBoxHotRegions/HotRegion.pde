class HotRegion {

  int FRAMES = 15;

  public static final int MODE_MAX_HEIGHT = 1;
  public static final int MODE_MIN_HEIGHT = 2;
  public static final int MODE_AVG_HEIGHT = 3;


  String name;
  int x, y, w, h;

  float currentMax, currentMin, currentAvg;

  float maxHeight = 1000;
  float minHeight = -1000;
  float minAvgHeight = 0;
  float maxAvgHeight = 0;

  float maxHeights[];
  float minHeights[];
  float minAvgHeights[];
  float maxAvgHeights[];

  boolean isActive = false;
  int mode = 1;


  public HotRegion( String name, int mode, int x, int y, int w, int h) {
 
    this.name = name;
    this.mode = mode;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  public void setMaxHeight(float max) {
    this.maxHeight = max;
  }

  public void setMinHeight(float min) {
    this.minHeight = min;
  }

  public void setAvgHeight(float min, float max) {
    this.minAvgHeight = min;
    this.maxAvgHeight = max;
  }

  public void draw(PGraphics g) {
    println(isActive);
    g.pushStyle();
    if (isActive) {
      g.noStroke();
      g.fill(0, 255, 0);
    } else {
      g.stroke(255, 0, 0);
      g.noFill();
    }
    //g.fill(#231233);
    g.rect(x, y, w, h);
    g.textSize(20);
    g.text(""+currentMin + " " + currentMax + " " + currentAvg, x, y+h);
    g.popStyle();
  }

  public void run(PImage depth, PVector []map3D) {
    float min = 256, max=0, avg=0;
    int sum = 0;
    for (int i = y; i < y+h; i++) {
      for (int j = x; j < x+w; j++) {
        //int v = (int)red(depth.pixels[i*depth.width+j]);
        float v = map3D[i*depth.width+j].z;
        sum += v;
        if ( v < min ) {
          min = v;
        }
        if ( v > max ) {
          max = v;
        }
      }
    }
    avg = sum/(w*h);
    currentMax = max;
    currentMin = min;
    currentAvg = avg;

  //  println(name, currentMin, currentMax, avg); 
    switch (mode) {
    case MODE_MAX_HEIGHT: 
      if ( currentMax >= maxHeight ) {


        if (!isActive) {
          isActive = true;
          // trigger event
          println("max height trigger");
        }
      } else {
        isActive = false;
      }
      break;
    case MODE_MIN_HEIGHT:
      if (currentMin <= minHeight ) {
        if (!isActive) {
          isActive = true;
          // trigger event
          println("min height trigger");
        }
      } else {
        isActive = false;
      }
      break;
    case MODE_AVG_HEIGHT:
      if ( avg <= minAvgHeight || avg >= maxAvgHeight ) {
        if (!isActive) {
          isActive = true;
          // trigger event
          println("avg height trigger");
        }
      } else {
        if (isActive) {
          isActive = false;
        }
      }
      break;
    }
  }


  public float maxHeight(PImage depth) {
    return 0;
  }


  public float avgHeight(PImage depth) {
    return 0;
  }
}