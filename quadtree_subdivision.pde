/**
 * Quadtree Subdivision – Production-Ready Prototype with CMYK & Export Support
 * and Cached Processed Snapshot, plus fix for pixelation and line patterns:
 * 
 * We now explicitly pass the PGraphics object (processedPG) to the Quadtree,
 * so that all drawing of pixelation and line patterns occurs on the offscreen
 * buffer. Then we display the offscreen buffer in draw().
 *
 * This application supports multiple modes:
 *   1) Pixelation (quantized subdivisions)
 *   2) Pattern overlays for subdivisions
 *   3) CMYK mode that converts the processed output into 4 channels
 * 
 * We have a tab-based UI (MainTab, PixelationTab, PatternsTab, CMYKTab).
 * - If currentThreshold == 0 => no background image is drawn.
 * - All text is forced to black.
 * - We rely on setAutoDraw(false) and manually call cp5.draw() in draw().
 *
 * Author: [Your Name]
 * Date: [Today's Date]
 */

//////////////////////////////
// Constants and Globals
//////////////////////////////

final int SIDEBAR_WIDTH = 250;
final int APP_WIDTH     = 1200;
final int APP_HEIGHT    = 1000;
final int IMAGE_WIDTH   = APP_WIDTH - SIDEBAR_WIDTH;
final int IMAGE_HEIGHT  = APP_HEIGHT;

PImage   img;            // The base loaded image
Quadtree quadtree;       // Handles pixelation & pattern logic
boolean  needsUpdate = true;

// Toggles
boolean showPixelation  = true;
boolean showLinePatterns= false;
boolean cmykMode        = false;
boolean overlayCMYK     = false;

// Offscreen buffer & cached result
PGraphics processedPG;
PImage    processedImage;

// CMYK channels
PImage cImg, mImg, yImg, kImg, compositeCMYK;

String baseFileName = "export";

//////////////////////
// GUI (ControlP5)
//////////////////////

import controlP5.*;
ControlP5 cp5;

// We use tabs
Tab tabMain, tabPixelation, tabPatterns, tabCMYK;

Slider        thresholdSlider;
ScrollableList patternTypeList;
Slider        lineThicknessSlider, lineSpacingSlider;

Button exportButton, loadImageButton;

float currentThreshold     = 10;
int   currentPatternType   = 0;
float currentLineThickness = 2; 
float currentLineSpacing   = 2;

/////////////////////////////
// Data Structures & Classes
/////////////////////////////

/**
 * SubdivisionSquare: a region in the quadtree
 * We pass a PGraphics context to drawSquare(pg) so that all drawing
 * goes to the offscreen buffer instead of the main canvas.
 */
class SubdivisionSquare {
  float x, y, w, h;
  color col;
  boolean usePattern;
  int patternType;
  float thickness, spacing;
  
  // Solid color mode
  SubdivisionSquare(float x, float y, float w, float h, color c) {
    this.x=x; 
    this.y=y; 
    this.w=w; 
    this.h=h;
    this.col = c;
    this.usePattern = false;
  }
  
  // Pattern mode
  SubdivisionSquare(float x, float y, float w, float h, int pType, float thick, float sp) {
    this.x=x; 
    this.y=y; 
    this.w=w; 
    this.h=h;
    this.usePattern = true;
    this.patternType = pType;
    this.thickness = thick;
    this.spacing = sp;
    this.col = color(255);
  }
  
  void drawSquare(PGraphics pg) {
    if (usePattern) {
      drawPattern(pg, x, y, w, h, patternType, thickness, spacing);
    } else {
      pg.noStroke();
      pg.fill(col);
      pg.rect(x, y, w, h);
    }
  }
}

/**
 * Quadtree: subdivides based on color variation
 * We'll add a drawQuads(pg) method that takes a PGraphics context.
 */
class Quadtree {
  ArrayList<SubdivisionSquare> squares;
  
  Quadtree() {
    squares = new ArrayList<SubdivisionSquare>();
  }
  
  void clear() {
    squares.clear();
  }
  
  void subdivide(float x, float y, float w, float h, float threshold, 
                 boolean usePatterns, int pType, float thick, float sp) {
    color avgColor = getAverageColorRegion(x, y, w, h);
    float variation = getColorVariationRegion(x, y, w, h, avgColor);
    
    if (variation > threshold && w > 6 && h > 6) {
      float halfW = w/2, halfH = h/2;
      subdivide(x,        y,        halfW, halfH, threshold, usePatterns, pType, thick, sp);
      subdivide(x+halfW,  y,        halfW, halfH, threshold, usePatterns, pType, thick, sp);
      subdivide(x,        y+halfH,  halfW, halfH, threshold, usePatterns, pType, thick, sp);
      subdivide(x+halfW,  y+halfH,  halfW, halfH, threshold, usePatterns, pType, thick, sp);
    } else {
      if (usePatterns) {
        squares.add(new SubdivisionSquare(x, y, w, h, pType, thick, sp));
      } else {
        squares.add(new SubdivisionSquare(x, y, w, h, avgColor));
      }
    }
  }
  
  // We'll pass the PGraphics context to draw
  void drawQuads(PGraphics pg) {
    for (SubdivisionSquare sq : squares) {
      sq.drawSquare(pg);
    }
  }
}

//////////////////////////
// Settings, Setup, Draw
//////////////////////////

void settings(){
  size(APP_WIDTH, APP_HEIGHT, P3D);
}

void setup(){
  img = loadImage("mona_lisa.jpeg");
  if(img==null){
    println("No default image found. Exiting.");
    exit();
  }
  baseFileName="mona_lisa";
  img.resize(IMAGE_WIDTH,IMAGE_HEIGHT);
  img.loadPixels();
  
  processedPG = createGraphics(IMAGE_WIDTH, IMAGE_HEIGHT, P2D);
  quadtree=new Quadtree();
  
  cp5=new ControlP5(this);
  cp5.setAutoDraw(false); // We'll draw cp5 manually in draw()

  // Create tabs
  tabMain       = cp5.addTab("MainTab")       .setLabel("Main").activateEvent(true);
  tabPixelation = cp5.addTab("PixelationTab") .setLabel("Pixelation");
  tabPatterns   = cp5.addTab("PatternsTab")   .setLabel("Patterns");
  tabCMYK       = cp5.addTab("CMYKTab")       .setLabel("CMYK");

  // Pixelation Tab
  cp5.addToggle("ShowPixelation")
    .setPosition(20,20)
    .setSize(70,20)
    .setLabel("Pixelation")
    .setValue(showPixelation)
    .moveTo(tabPixelation.getName());
  
  thresholdSlider=cp5.addSlider("SubdivisionThreshold")
    .setPosition(20,60)
    .setWidth(150)
    .setRange(0,50)  // 0 => no background
    .setValue(currentThreshold)
    .setLabel("Threshold")
    .moveTo(tabPixelation.getName());

  // Patterns Tab
  cp5.addToggle("ShowLinePatterns")
    .setPosition(20,20)
    .setSize(90,20)
    .setLabel("Line Patterns")
    .setValue(showLinePatterns)
    .moveTo(tabPatterns.getName());

  patternTypeList=cp5.addScrollableList("PatternType")
    .setPosition(20,60)
    .setSize(150,100)
    .addItem("Horizontal",0)
    .addItem("Vertical",1)
    .addItem("Diagonal",2)
    .addItem("Crosshatch",3)
    .addItem("Hexagon",4)
    .addItem("Circles",5)
    .setLabel("Pattern Type")
    .setValue(0)
    .moveTo(tabPatterns.getName());

  lineThicknessSlider=cp5.addSlider("LineThickness")
    .setPosition(20,180)
    .setWidth(150)
    .setRange(1,10)
    .setValue(currentLineThickness)
    .setLabel("Line Thick")
    .moveTo(tabPatterns.getName());

  lineSpacingSlider=cp5.addSlider("LineSpacing")
    .setPosition(20,220)
    .setWidth(150)
    .setRange(5,50)
    .setValue(currentLineSpacing)
    .setLabel("Line Spacing")
    .moveTo(tabPatterns.getName());

  // CMYK Tab
  cp5.addToggle("CMYKMode")
    .setPosition(20,20)
    .setSize(70,20)
    .setLabel("CMYK")
    .setValue(cmykMode)
    .moveTo(tabCMYK.getName());

  cp5.addToggle("OverlayCMYK")
    .setPosition(20,60)
    .setSize(70,20)
    .setLabel("Overlay")
    .setValue(overlayCMYK)
    .moveTo(tabCMYK.getName());

  // Main Tab
  exportButton=cp5.addButton("ExportImage")
    .setPosition(20,20)
    .setSize(130,30)
    .setLabel("Export")
    .moveTo(tabMain.getName());

  loadImageButton=cp5.addButton("LoadImage")
    .setPosition(20,60)
    .setSize(130,30)
    .setLabel("Load Image")
    .moveTo(tabMain.getName());

  cp5.addTextlabel("HelpLabel")
    .setPosition(20,110)
    .setText("Help:\n- 0 threshold => no background.\n- Switch tabs for pixelation, patterns, or CMYK.\n- Export => single or 4 images.\n\nFuture:\n- Resizable sidebar.\n- Tooltips.\n- Per-layer.\n- Advanced blending.")
    .moveTo(tabMain.getName());

  // Force all text black
  for (ControllerInterface<?> ci : cp5.getAll()) {
    if(ci instanceof Controller){
      ((Controller<?>) ci).setColorValue(color(0));
    } 
    else if(ci instanceof ControllerGroup){
      ((ControllerGroup<?>) ci).setColorValue(color(0));
    }
  }

  // Hide pattern controls if not toggled
  if(!showLinePatterns){
    patternTypeList.hide();
    lineThicknessSlider.hide();
    lineSpacingSlider.hide();
  }

  // Add Listeners
  cp5.get(Slider.class,"SubdivisionThreshold").addListener(e->{
    currentThreshold = thresholdSlider.getValue();
    needsUpdate=true;
  });
  cp5.get(ScrollableList.class,"PatternType").addListener(e->{
    currentPatternType=(int)patternTypeList.getValue();
    needsUpdate=true;
  });
  cp5.get(Slider.class,"LineThickness").addListener(e->{
    currentLineThickness=lineThicknessSlider.getValue();
    needsUpdate=true;
  });
  cp5.get(Slider.class,"LineSpacing").addListener(e->{
    currentLineSpacing=lineSpacingSlider.getValue();
    needsUpdate=true;
  });
  cp5.get(Toggle.class,"ShowPixelation").addListener(e->{
    showPixelation=cp5.get(Toggle.class,"ShowPixelation").getState();
    needsUpdate=true;
  });
  cp5.get(Toggle.class,"ShowLinePatterns").addListener(e->{
    showLinePatterns=cp5.get(Toggle.class,"ShowLinePatterns").getState();
    if(showLinePatterns){
      patternTypeList.show();
      lineThicknessSlider.show();
      lineSpacingSlider.show();
    } else {
      patternTypeList.hide();
      lineThicknessSlider.hide();
      lineSpacingSlider.hide();
    }
    needsUpdate=true;
  });
  cp5.get(Toggle.class,"CMYKMode").addListener(e->{
    cmykMode=cp5.get(Toggle.class,"CMYKMode").getState();
    needsUpdate=true;
  });
  cp5.get(Toggle.class,"OverlayCMYK").addListener(e->{
    overlayCMYK=cp5.get(Toggle.class,"OverlayCMYK").getState();
    // No reprocessing needed, just changes display
  });
  cp5.get(Button.class,"ExportImage").addListener(e->{
    exportImage();
  });

  // Start with a quadtree update
  updateQuadtree();
  processedPG.beginDraw();
  processedPG.background(255);
  if(currentThreshold==0){
    processedPG.background(255);
  } else {
    processedPG.image(img,0,0,IMAGE_WIDTH,IMAGE_HEIGHT);
  }
  if(!cmykMode && showPixelation){
    quadtree.drawQuads(processedPG);
  }
  processedPG.endDraw();
  processedImage=processedPG.get();
  needsUpdate=false;
}

void draw(){
  background(240);
  // Manually draw controlP5
  cp5.draw();

  if(needsUpdate){
    if(cmykMode){
      updateCMYK();
    }
    else{
      updateQuadtree();
      processedPG.beginDraw();
      processedPG.background(255);
      if(currentThreshold==0){
        processedPG.background(255);
      } else {
        processedPG.image(img,0,0,IMAGE_WIDTH,IMAGE_HEIGHT);
      }
      if(!cmykMode && showPixelation){
        quadtree.drawQuads(processedPG);
      }
      processedPG.endDraw();
      processedImage=processedPG.get();
    }
    needsUpdate=false;
  }

  // Draw final output to the right side
  pushMatrix();
  translate(SIDEBAR_WIDTH,0);
  if(cmykMode){
    if(overlayCMYK){
      if(compositeCMYK!=null){
        image(compositeCMYK,0,0,IMAGE_WIDTH,IMAGE_HEIGHT);
      }
    }
    else{
      if(cImg!=null && mImg!=null && yImg!=null && kImg!=null){
        image(cImg,0,0,IMAGE_WIDTH/2,IMAGE_HEIGHT/2);
        image(mImg,IMAGE_WIDTH/2,0,IMAGE_WIDTH/2,IMAGE_HEIGHT/2);
        image(yImg,0,IMAGE_HEIGHT/2,IMAGE_WIDTH/2,IMAGE_HEIGHT/2);
        image(kImg,IMAGE_WIDTH/2,IMAGE_HEIGHT/2,IMAGE_WIDTH/2,IMAGE_HEIGHT/2);
      }
    }
  }
  else {
    image(processedImage,0,0,IMAGE_WIDTH,IMAGE_HEIGHT);
  }
  popMatrix();
}

////////////////////////
// Quadtree Update Logic
////////////////////////

void updateQuadtree(){
  quadtree.clear();
  if(showPixelation){
    img.loadPixels();
    quadtree.subdivide(
      0,0, 
      IMAGE_WIDTH,IMAGE_HEIGHT, 
      currentThreshold,
      showLinePatterns,
      currentPatternType,
      currentLineThickness,
      currentLineSpacing
    );
  }
}

////////////////////////////
// CMYK Update Logic
////////////////////////////

void updateCMYK(){
  // Re-render to processedPG
  processedPG.beginDraw();
  processedPG.background(255);
  if(currentThreshold==0){
    processedPG.background(255);
  } else {
    processedPG.image(img,0,0,IMAGE_WIDTH,IMAGE_HEIGHT);
  }
  if(showPixelation){
    quadtree.drawQuads(processedPG);
  }
  processedPG.endDraw();
  
  processedImage=processedPG.get();
  
  // Build channel images
  cImg=createImage(IMAGE_WIDTH,IMAGE_HEIGHT,RGB);
  mImg=createImage(IMAGE_WIDTH,IMAGE_HEIGHT,RGB);
  yImg=createImage(IMAGE_WIDTH,IMAGE_HEIGHT,RGB);
  kImg=createImage(IMAGE_WIDTH,IMAGE_HEIGHT,RGB);
  compositeCMYK=createImage(IMAGE_WIDTH,IMAGE_HEIGHT,RGB);
  
  processedImage.loadPixels();
  cImg.loadPixels();
  mImg.loadPixels();
  yImg.loadPixels();
  kImg.loadPixels();
  compositeCMYK.loadPixels();
  
  for(int i=0;i<IMAGE_WIDTH*IMAGE_HEIGHT;i++){
    color orig=processedImage.pixels[i];
    float r=red(orig)/255.0;
    float g=green(orig)/255.0;
    float b=blue(orig)/255.0;
    
    float K=1-max(r,max(g,b));
    float C=(K<1)?(1-r-K)/(1-K):0;
    float M=(K<1)?(1-g-K)/(1-K):0;
    float Y=(K<1)?(1-b-K)/(1-K):0;
    
    int cVal=int(255*(1-C));
    int mVal=int(255*(1-M));
    int yVal=int(255*(1-Y));
    int kVal=int(255*(1-K));
    
    cImg.pixels[i]=color(cVal);
    mImg.pixels[i]=color(mVal);
    yImg.pixels[i]=color(yVal);
    kImg.pixels[i]=color(kVal);
    
    int compVal=int((cVal+mVal+yVal+kVal)/4.0);
    compositeCMYK.pixels[i]=color(compVal);
  }
  
  cImg.updatePixels();
  mImg.updatePixels();
  yImg.updatePixels();
  kImg.updatePixels();
  compositeCMYK.updatePixels();
}

////////////////////////////
// Image Processing Helpers
////////////////////////////

color getAverageColorRegion(float x, float y, float w, float h){
  int sumR=0,sumG=0,sumB=0,count=0;
  for(int i=int(x);i<x+w;i++){
    for(int j=int(y);j<y+h;j++){
      int index=j*IMAGE_WIDTH + i;
      if(i<IMAGE_WIDTH && j<IMAGE_HEIGHT && index<img.pixels.length){
        color c=img.pixels[index];
        sumR+=int(red(c));
        sumG+=int(green(c));
        sumB+=int(blue(c));
        count++;
      }
    }
  }
  if(count==0)return color(255);
  return color(sumR/count,sumG/count,sumB/count);
}

float getColorVariationRegion(float x,float y,float w,float h,color avg){
  float totalVariation=0; 
  int count=0;
  float avgR=red(avg),avgG=green(avg),avgB=blue(avg);
  for(int i=int(x); i<x+w; i++){
    for(int j=int(y); j<y+h; j++){
      int index=j*IMAGE_WIDTH + i;
      if(i<IMAGE_WIDTH && j<IMAGE_HEIGHT && index<img.pixels.length){
        color c=img.pixels[index];
        float variation=dist(red(c),green(c),blue(c), avgR,avgG,avgB);
        totalVariation+=variation;
        count++;
      }
    }
  }
  if(count==0)return 0;
  return totalVariation/count;
}

color generatePatternForRegion(float x,float y,float w,float h,int pType,float thick,float sp){
  color baseColor=getAverageColorRegion(x,y,w,h);
  float factor=0.8+(pType*0.04);
  return color(red(baseColor)*factor, green(baseColor)*factor, blue(baseColor)*factor);
}

void drawPattern(PGraphics pg, float x,float y,float w,float h,int type,float thick,float sp){
  pg.stroke(0);
  pg.strokeWeight(thick);
  pg.noFill();
  
  if(type==0){ // Horizontal
    for(float j=y;j<y+h;j+=sp){
      pg.line(x,j,x+w,j);
    }
  }
  else if(type==1){ // Vertical
    for(float i=x;i<x+w;i+=sp){
      pg.line(i,y,i,y+h);
    }
  }
  else if(type==2){ // Diagonal
    for(float offset=-w;offset<h;offset+=sp){
      pg.line(x, y+max(0,offset), x+min(w,w+offset), y+min(h,offset+w));
    }
  }
  else if(type==3){ // Crosshatch
    for(float j=y;j<y+h;j+=sp){
      pg.line(x,j,x+w,j);
    }
    for(float i=x;i<x+w;i+=sp){
      pg.line(i,y,i,y+h);
    }
  }
  else if(type==4){ // Alternating diagonal
    for(float j=y;j<y+h;j+=sp){
      if(((int)((j-y)/sp))%2==0){
        pg.line(x,j,x+w,j+w);
      }else{
        pg.line(x+w,j,x,j+w);
      }
    }
  }
  else if(type==5){ // Circle grid
    for(float i=x;i<x+w;i+=sp){
      for(float j=y;j<y+h;j+=sp){
        pg.noFill();
        pg.ellipse(i,j,thick*2,thick*2);
      }
    }
  }
}

////////////////////////////
// File Input & Export
////////////////////////////

public void fileSelected(File selection){
  if(selection==null){
    println("No file selected.");
  }else{
    String path=selection.getAbsolutePath();
    println("Loading new image from: "+path);
    PImage newImg=loadImage(path);
    if(newImg==null){
      println("Could not load valid format.");
      return;
    }
    newImg.resize(IMAGE_WIDTH,IMAGE_HEIGHT);
    img=newImg;
    img.loadPixels();
    baseFileName="export_"+nf(millis(),8);
    needsUpdate=true;
  }
}

public void LoadImage(){
  selectInput("Select an image to process:", "fileSelected");
}

void exportImage(){
  // Re-render the processed output
  processedPG.beginDraw();
  processedPG.background(255);
  if(currentThreshold==0){
    processedPG.background(255);
  } else {
    processedPG.image(img,0,0,IMAGE_WIDTH,IMAGE_HEIGHT);
  }
  if(!cmykMode && showPixelation){
    quadtree.drawQuads(processedPG);
  }
  processedPG.endDraw();
  processedImage=processedPG.get();
  
  // If in CMYK mode, refresh channels
  if(cmykMode){
    updateCMYK();
  }
  
  // Create export folder
  String folderName=baseFileName+"_export";
  File exportFolder=new File(dataPath(folderName));
  if(!exportFolder.exists()){
    exportFolder.mkdirs();
  }
  
  if(cmykMode){
    if(cImg!=null && mImg!=null && yImg!=null && kImg!=null){
      cImg.save(folderName+"/"+baseFileName+"_Cyan.jpg");
      mImg.save(folderName+"/"+baseFileName+"_Magenta.jpg");
      yImg.save(folderName+"/"+baseFileName+"_Yellow.jpg");
      kImg.save(folderName+"/"+baseFileName+"_Black.jpg");
      println("CMYK images exported to "+exportFolder.getAbsolutePath());
    }
  }
  else{
    processedImage.save(folderName+"/"+baseFileName+"_Processed.jpg");
    println("Processed image exported to "+exportFolder.getAbsolutePath());
  }
}
