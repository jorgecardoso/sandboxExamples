import SimpleOpenNI.*;

int NUM_MODES = 3;
int CROPPING = 0;
int KEYSTONE = 1;
int ROTATION = 2;

SimpleOpenNI  context;

import deadpixel.keystone.*;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;

int cropLeft = 0; 
int cropRight = 0;
int cropTop = 0;
int cropBottom = 0;
boolean cropping = false;


float angleXCalibration = 0;
float angleZCalibration = 0;

int mode = 0;


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
    // ks.load();

    offscreen = createGraphics(width, height, P3D);
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

    offscreen.pushMatrix();
    //offscreen.scale(width*1.0/depthImage.width, height*1.0/depthImage.height);
    offscreen.image(depthImage, 0, 0, width, height);
    offscreen.popMatrix();

    for (int i = 0; i < realWorldMap.length; i++) {
        PVector v = new PVector(realWorldMap[i].y, realWorldMap[i].z);
        v.rotate(angleXCalibration);
        realWorldMap[i].z = v.y;
        realWorldMap[i].y = v.x;
        
        v = new PVector(realWorldMap[i].x, realWorldMap[i].z);
        v.rotate(angleZCalibration);
        realWorldMap[i].z = v.y;
        realWorldMap[i].x = v.x;
    }

    if (mode == ROTATION) {
        // Draw z
       float sW = width*1.0/croppedWidth;
        float sH = height*1.0/croppedHeight;
        // println(width, croppedWidth, sW, sH);
/*
        for (int i = 0; i < croppedWidth; i+=5 ) {
            for (int j = 0; j < croppedHeight; j+=5 ) {
                PVector p = realWorldMap[j*croppedWidth+i];

                color c = color(map(p.z, 700, 800, 0, 255));
                offscreen.fill(c);
                offscreen.scale(1);
                offscreen.noStroke();
                offscreen.rect(i*sW, j*sH, 5*sW, 5*sH);
            }
        }
*/
        // Draw four depths
        int x1 = int(croppedWidth*0.1);
        int y1 = int(croppedHeight*0.1);

        int x2 = croppedWidth-x1;
        int y2 = y1;

        int x3 = x1;
        int y3 = croppedHeight-y1;

        int x4 = x2;
        int y4 = y3;
        offscreen.fill(255, 0, 0);
        offscreen.ellipse(x1*sW, y1*sH, 10, 10);
        offscreen.text(realWorldMap[x1+y1*croppedWidth].z+"", 200, 200);
        
        offscreen.ellipse(x2*sW, y2*sH, 10, 10);
        offscreen.text(realWorldMap[x2+y2*croppedWidth].z+"", width-200, 200);
        
        offscreen.ellipse(x3*sW, y3*sH, 10, 10);
        offscreen.text(realWorldMap[x3+y3*croppedWidth].z+"", 200, height-200);
        
        offscreen.ellipse(x4*sW, y4*sH, 10, 10);
        offscreen.text(realWorldMap[x4+y4*croppedWidth].z+"", width-200, height-200);
    }
    if (mode == CROPPING) {
        offscreen.stroke(#ff0000);
        offscreen.line(0, cropTop, width, cropTop);
        offscreen.line(0, height-cropBottom, width, height-cropBottom);
        offscreen.line(cropLeft, 0, cropLeft, height);
        offscreen.line(width-cropRight, 0, width-cropRight, height);
    } 


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
    offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 25, 25);
    offscreen.fill(255, 0, 0);
    offscreen.textSize(63);
    offscreen.text(""+realWorldMap[mY*croppedWidth+mX].z, surfaceMouse.x, surfaceMouse.y);


    offscreen.endDraw();

    background(0);
    surface.render(offscreen);

    if (mode == CROPPING) {
        textSize(50);
        text("CROPPING", width/2-textWidth("CROPPING")/2, height/2);
        text("<q/a>: move top border", width/2, 50);
        text("<w/s>: move bottom border", width/2, 100);
        text("<e/d>: move left border", width/2, 150);
        text("<r/f>: move right border", width/2, 200);        
        
    } else if (mode == KEYSTONE) {
        textSize(50);
        text("KEYSTONE", width/2-textWidth("KEYSTONE")/2, height/2);
        text("drag corners", width/2, 50);
    } else if (mode == ROTATION) {
        textSize(50);
        text("ROTATION", width/2-textWidth("ROTATION")/2, height/2);
        textSize(40);
        text("Rot X: "+angleXCalibration, width/2, height/2+50);
        text("Rot Y: "+angleZCalibration, width/2, height/2+150);
        
          text("<z/x>: rotate around X", width/2, 50);
        text("<c/v>: rotate around Y", width/2, 100);
      
    }
    textSize(40);
    text("<Left/Right>: Change mode", 100, height/2-100);
    text("<k>: Save calibration", 100, height/2);
    text("<l>: Load calibration", 100, height/2+100);
    
}

void keyPressed() {
    if ( key == CODED ) {
        if (keyCode == LEFT) {
            mode = (mode-1)%NUM_MODES;
        } else if (keyCode == RIGHT) {
            mode = (mode+1)%NUM_MODES;
        }
    } else if (key == 'k' ) {
        ks.save();
        String [] config = new String[6];
        config[0] = cropTop+"";
        config[1] = cropRight+"";
        config[2] = cropBottom+"";
        config[3] = cropLeft+"";
        config[4] = angleXCalibration+"";
        config[5] = angleZCalibration+"";
        println("Saving config:");
        println(config);
        saveStrings("config.txt", config);
        
    } else if (key == 'l') {
        ks.load();
        String[] config = loadStrings("config.txt");
        println("Loaded config:");
        println(config);
        cropTop = int(config[0]);
        cropRight = int(config[1]);
        cropBottom = int(config[2]);
        cropLeft = int(config[3]);
        angleXCalibration = float(config[4]);
        angleZCalibration = float(config[5]);
        
    }
    
    if (mode == ROTATION) {
        if (key == 'z') {
            angleXCalibration += TWO_PI/360.0;
        } else if (key == 'x') {
            angleXCalibration -= TWO_PI/360.0;
        } else if (key == 'c'){
            angleZCalibration += TWO_PI/360.0;
        } else if (key == 'v') {
            angleZCalibration -= TWO_PI/360.0;
        }
    }else    if (mode == CROPPING) {
        if ( key == 'q' ) {
            if (cropTop > 0) cropTop--;
        } else if ( key== 'a') {
            cropTop++;
        } else if ( key == 'w' ) {
            if (cropBottom > 0) cropBottom--;
        } else if ( key== 's') {
            cropBottom++;
        } else if ( key == 'e' ) {
            if (cropLeft > 0) cropLeft--;
        } else if ( key== 'd') {
            cropLeft++;
        } else if ( key == 'r' ) {
            if (cropRight > 0) cropRight--;
        } else if ( key== 'f') {
            cropRight++;
        }
    } else if (mode == KEYSTONE) {
        ks.startCalibration();
        /*switch(key) {
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
        }*/
    }
    
    if (mode != KEYSTONE) {
        ks.stopCalibration();
    }
}
