import SimpleOpenNI.*;

SimpleOpenNI  context;

import deadpixel.keystone.*;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;

int cropLeft = 10; 
int cropRight = 10;
int cropTop = 10;
int cropBottom = 90;
boolean cropping = false;

HotRegion hot, hotOne;

boolean showDepth = true;

void setup() {
  fullScreen(P3D, 2); // 2 - second screen (projector) must be in extend mode
  //size(640, 480, P3D);
  context = new SimpleOpenNI(this);
  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  // enable depthMap generation 
  context.enableDepth();

  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(width, height, 20);
  ks.load();

  offscreen = createGraphics(width, height, P3D);


  hot = new HotRegion("hotarea", HotRegion.MODE_MAX_HEIGHT, 259, 150, 50, 50);
  hot.setMaxHeight(800);

  hotOne = new HotRegion("hotOne", HotRegion.MODE_AVG_HEIGHT, 100, 0, 50, 50);
  hotOne.setAvgHeight(700, 740);
}

void draw() {
  context.update();
  int croppedWidth = (640-cropLeft-cropRight);
  int croppedHeight = (480-cropBottom-cropTop);


  /* Crop the depth map*/
  int depthMap[] = new int[croppedWidth * croppedHeight]; 
  for (int i = cropTop; i < 480-cropBottom; i++) {
    arrayCopy(context.depthMap(), i*640+cropLeft, depthMap, (i-cropTop)*croppedWidth, croppedWidth);
  }

  /* Crop the 3D map*/
  PVector[] realWorldMap = new PVector[croppedWidth * croppedHeight]; 
  for (int i = cropTop; i < 480-cropBottom; i++) {
    arrayCopy(context.depthMapRealWorld(), i*640+cropLeft, realWorldMap, (i-cropTop)*croppedWidth, croppedWidth);
  }

  /* Crop the depth image*/
  PImage depthImage = context.depthImage().get(cropLeft, cropTop, 640-cropRight-cropLeft, 480-cropBottom-cropTop);

  // Draw the scene, offscreen
  offscreen.beginDraw();
  offscreen.background(0);

  // Draw depth data as color green to red
  if (showDepth) {
    int steps = 10;
    offscreen.noStroke();
    color fromColor = color(0, 255, 0);
    color toColor = color(255, 0, 0);
    for (int y=0; y < croppedHeight; y+=steps) {
      for (int x=0; x < croppedWidth; x+=steps) {

        int index = x + y * croppedWidth;
        offscreen.fill (lerpColor(fromColor, toColor, map(depthMap[index], 720, 800, 0, 1)));
        offscreen.rect(map(x, 0, croppedWidth, 0, width), map(y, 0, croppedHeight, 0, height), 20, 20);
        // println(x, y, depthMap[index]);
      }
    }
  }

  // Draw depth image
  /*  
   offscreen.pushMatrix();
   offscreen.scale(width*1.0/depthImage.width, height*1.0/depthImage.height);
   offscreen.image(depthImage, 0, 0);//, width, height);
   offscreen.popMatrix();
   */


  if (cropping) {
    offscreen.stroke(#ff0000);
    offscreen.line(0, cropTop, width, cropTop);
    offscreen.line(0, height-cropBottom, width, height-cropBottom);
    offscreen.line(cropLeft, 0, cropLeft, height);
    offscreen.line(width-cropRight, 0, width-cropRight, height);
  } 


  // Regions are defined in the original image reference (640x480) so we need to scale them
  offscreen.pushMatrix();
  offscreen.scale(width*1.0/depthImage.width, height*1.0/depthImage.height);
  hot.run(depthImage, realWorldMap);
  hot.draw(offscreen);
  hotOne.run(depthImage, realWorldMap);
  hotOne.draw(offscreen);
  offscreen.popMatrix();


  // Show depth of the cursor point
  PVector surfaceMouse = surface.getTransformedMouse();
  int mX = (int)map(surfaceMouse.x, 0, width-1, 0, croppedWidth-1);
  mX = constrain(mX, 0, croppedWidth-1);
  int mY = (int)map(surfaceMouse.y, 0, height-1, 0, croppedHeight-1);
  mY = constrain(mY, 0, croppedHeight-1);
  // println(mX, mY, red(depthImage.pixels[mY*depthImage.width+mX]));
  offscreen.stroke(0, 0, 255);
  offscreen.strokeWeight(5);
  offscreen.noFill();
  offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
  offscreen.fill(255, 0, 0);
  offscreen.textSize(63);
  offscreen.text(""+realWorldMap[mY*croppedWidth+mX].z, surfaceMouse.x, surfaceMouse.y);


  if (hotOne.isActive) {
    offscreen.text("HotOne active", 1000, 200);
  }
  if (hot.isActive) {
    offscreen.text("Hot active", 1000, 200);
  }

  offscreen.endDraw();

  background(0);
  surface.render(offscreen);
}


void sandBoxEvent(String hotRegionName, boolean on) {
  if ( hotRegionName.equals("hotOne") ) {
  }
}
void keyPressed() {
  switch(key) {
  case 'd':
    showDepth = !showDepth;
    break;
  case 'c':
    // enter/leave calibration mode, where surfaces can be warped 
    // and moved
    ks.toggleCalibration();
    break;

  case 'l':
    // loads the saved layout
    ks.load();
    break;

  case 's':
    // saves the layout
    ks.save();
    break;
  }
}