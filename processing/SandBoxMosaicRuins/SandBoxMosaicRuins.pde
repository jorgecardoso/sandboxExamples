import SimpleOpenNI.*;
import deadpixel.keystone.*;

SimpleOpenNI  openni;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;
PImage background;

SandboxCalibrator calibrator;

SandboxImageLayer imageLayer, imageLayer2;

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
    imageLayer = new SandboxImageLayer(loadImage("mosaic1.jpg"), 450, 310, 100, 100, 775);
    imageLayer2 = new SandboxImageLayer(loadImage("mosaic2.png"), 200, 260, 70, 140, 775);

    
    background = loadImage("aereal-sandbox1.png");
}

void draw() {
    openni.update();
    calibrator.run(openni);

    // Draw the scene, offscreen
    offscreen.beginDraw();
    offscreen.background(0);

    // draw background
    offscreen.image(background, 0, 0, width, height);
    

    // Regions are defined in the original image reference (640x480) so we need to scale them
    offscreen.pushMatrix();
    offscreen.scale(width*1.0/calibrator.depthImage.width, height*1.0/calibrator.depthImage.height);
    imageLayer.run(calibrator.depthImage, calibrator.realWorldMap);
    imageLayer.draw(offscreen);
    
    imageLayer2.run(calibrator.depthImage, calibrator.realWorldMap);
    imageLayer2.draw(offscreen);
    
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
