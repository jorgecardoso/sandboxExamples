import SimpleOpenNI.*;
import deadpixel.keystone.*;

SimpleOpenNI  openni;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;

SandboxCalibrator calibrator;

SandboxImageLayer imageLayer, catImageLayer, catShitImageLayer;

void setup() {
    fullScreen(P3D, 2); // 2 - second screen (projector) must be in extend mode
    //size(640, 480, P3D);
    openni = new SimpleOpenNI(this);
    if (openni.isInit() == false)
    {
        println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
        exit();
        return;
    }

    // enable depthMap generation 
    openni.enableDepth();

    ks = new Keystone(this);
    surface = ks.createCornerPinSurface(width, height, 20);
    ks.load();

    offscreen = createGraphics(width, height, P3D);

    calibrator = new SandboxCalibrator();
    imageLayer = new SandboxImageLayer(loadImage("girlwithbunny-closeup.jpg"), 100, 100, 100, 100, 790);

    catImageLayer = new SandboxImageLayer(loadImage("cat.jpg"), 300, 100, 100, 100, 750);

    catShitImageLayer = new SandboxImageLayer(loadImage("cat-shit.png"), 100, 100, 300, 250, 770);
}

void draw() {
    openni.update();
    calibrator.run(openni);

    // Draw the scene, offscreen
    offscreen.beginDraw();
    offscreen.background(0);

    // Draw depth data as color green to red
    /*
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
     */
    // Draw depth image
    /*  
     offscreen.pushMatrix();
     offscreen.scale(width*1.0/depthImage.width, height*1.0/depthImage.height);
     offscreen.image(depthImage, 0, 0);//, width, height);
     offscreen.popMatrix();
     */


    // Regions are defined in the original image reference (640x480) so we need to scale them
    offscreen.pushMatrix();
    offscreen.scale(width*1.0/calibrator.depthImage.width, height*1.0/calibrator.depthImage.height);
    imageLayer.run(calibrator.depthImage, calibrator.realWorldMap);
    imageLayer.draw(offscreen);
    catImageLayer.run(calibrator.depthImage, calibrator.realWorldMap);
    catImageLayer.draw(offscreen);

    catShitImageLayer.run(calibrator.depthImage, calibrator.realWorldMap);
    catShitImageLayer.draw(offscreen);
    offscreen.popMatrix();


    // Show depth of the cursor point
    PVector surfaceMouse = surface.getTransformedMouse();
    int mX = (int)map(surfaceMouse.x, 0, width-1, 0, calibrator.croppedWidth-1);
    mX = constrain(mX, 0, calibrator.croppedWidth-1);
    int mY = (int)map(surfaceMouse.y, 0, height-1, 0, calibrator.croppedHeight-1);
    mY = constrain(mY, 0, calibrator.croppedHeight-1);
    // println(mX, mY, red(depthImage.pixels[mY*depthImage.width+mX]));
    offscreen.stroke(0, 0, 255);
    offscreen.strokeWeight(5);
    offscreen.noFill();
    offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
    offscreen.fill(255, 0, 0);
    offscreen.textSize(63);
    offscreen.text(""+calibrator.realWorldMap[mY*calibrator.croppedWidth+mX].z, surfaceMouse.x, surfaceMouse.y);


    offscreen.endDraw();

    background(0);
    surface.render(offscreen);
}
