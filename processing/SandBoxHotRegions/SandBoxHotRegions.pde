import SimpleOpenNI.*;

SimpleOpenNI  openni;

import deadpixel.keystone.*;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;
SandboxCalibrator calibrator;

HotRegion hot1, hot2;

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

    hot1 = new HotRegion("hot 1", 200, 150, 50, 50, 750);

    hot2 = new HotRegion("hot 2", 350, 200, 50, 50, 740);
}

void draw() {
    openni.update();
    calibrator.run(openni);

    // Draw the scene, offscreen
    offscreen.beginDraw();
    offscreen.background(0);



    // Regions are defined in the original image reference (640x480) so we need to scale them
    offscreen.pushMatrix();
    offscreen.scale(width*1.0/calibrator.depthImage.width, height*1.0/calibrator.depthImage.height);
    hot1.run(calibrator.depthImage, calibrator.realWorldMap);
    hot1.draw(offscreen);
    hot2.run(calibrator.depthImage, calibrator.realWorldMap);
    hot2.draw(offscreen);
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


    if (hot1.isStable() && hot1.getState() == HotRegionState.FULLY_VISIBLE) {
        offscreen.text("Hot region 1 is fully visible!", 100, 100);
    }
    
        if (hot2.isStable() && hot2.getState() == HotRegionState.FULLY_VISIBLE) {
        offscreen.text("Hot region 2 is fully visible!", 100, 200);
    }
    
    offscreen.endDraw();

    background(0);
    surface.render(offscreen);
}
