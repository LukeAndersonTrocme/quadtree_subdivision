/**
 * Quadtree Subdivision – Production-Ready Prototype with CMYK Support
 * 
 * This application recursively subdivides an image based on its color variation.
 * It supports both a simple color mode and a pattern mode (for quantization).
 * In addition, a CMYK mode is provided:
 *   - When CMYK mode is enabled, the image is converted to CMYK, and four
 *     monochrome (greyscale) images are generated (for Cyan, Magenta, Yellow, and Black).
 *   - The user can view these four images in a 2x2 grid or overlay them into a single composite.
 *
 * Future roadmap ideas:
 *   - Per-layer fill customization for quantized layers.
 *   - More advanced CMYK blending and export features.
 *
 * Improvements over the initial prototype:
 *   - Modular design with encapsulated subdivision logic (Quadtree class)
 *   - Use of constants to avoid magic numbers
 *   - Caching: subdivisions (or CMYK layers) are recalculated only when parameters change
 *   - Optimized image processing using loadPixels() for faster performance
 *   - Basic error handling for image loading
 *
 * Author: [Your Name]
 * Date: [Today's Date]
 */

//////////////////////////////
// Constants and Global Variables
//////////////////////////////

final int SIDEBAR_WIDTH = 250;
final int APP_WIDTH = 1200;
final int APP_HEIGHT = 1000;
final int IMAGE_WIDTH = APP_WIDTH - SIDEBAR_WIDTH;
final int IMAGE_HEIGHT = APP_HEIGHT;

// Global image and processing objects
PImage img;
Quadtree quadtree;
boolean needsUpdate = true;

// Mode toggles for quantization display options:
boolean showPixelation = true;
boolean showLinePatterns = false;
boolean showBackgroundImage = true;

// --- New: CMYK Mode globals ---
boolean cmykMode = false;        // When true, CMYK conversion is performed
boolean overlayCMYK = false;     // When true, composite (overlaid) CMYK is shown instead of 4 panels
PImage cImg, mImg, yImg, kImg, compositeCMYK;

//////////////////////
// GUI Declarations
//////////////////////

import controlP5.*;
ControlP5 cp5;
Slider thresholdSlider;
Button loadImageButton;
ScrollableList patternTypeList;
Slider lineThicknessSlider;
Slider lineSpacingSlider;

// Parameter defaults
float currentThreshold = 10;
int currentPatternType = 0;
float currentLineThickness = 2;
float currentLineSpacing = 20;

/////////////////////////////
// Data Structures & Classes
/////////////////////////////

/**
 * Represents a subdivided region (square) of the image.
 * In color mode, the region stores a fill color.
 * In pattern mode, the region stores parameters for drawing a pattern.
 */
class SubdivisionSquare {
  float x, y, w, h;
  color col;
  boolean usePattern;
  int patternType;
  float thickness;
  float spacing;
  
  // Constructor for solid color mode
  SubdivisionSquare(float x, float y, float w, float h, color col) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.col = col;
    this.usePattern = false;
  }
  
  // Constructor for pattern mode
  SubdivisionSquare(float x, float y, float w, float h, int patternType, float thickness, float spacing) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.usePattern = true;
    this.patternType = patternType;
    this.thickness = thickness;
    this.spacing = spacing;
    // Default background (white) for pattern mode
    this.col = color(255);
  }
  
  void drawSquare() {
    if (usePattern) {
      drawPattern(x, y, w, h, patternType, thickness, spacing);
    } else {
      noStroke();
      fill(col);
      rect(x, y, w, h);
    }
  }
}

/**
 * Encapsulates the quadtree subdivision logic.
 * Future enhancements might separate quantization from fill style.
 */
class Quadtree {
  ArrayList<SubdivisionSquare> squares;
  
  Quadtree() {
    squares = new ArrayList<SubdivisionSquare>();
  }
  
  void clear() {
    squares.clear();
  }
  
  /**
   * Recursively subdivides the given region based on color variation.
   * The parameter "usePatterns" determines if pattern mode is applied.
   */
  void subdivide(float x, float y, float w, float h, float threshold, 
                   boolean usePatterns, int patternType, float thickness, float spacing) {
    color avgColor = getAverageColorRegion(x, y, w, h);
    float variation = getColorVariationRegion(x, y, w, h, avgColor);
    
    if (variation > threshold && w > 6 && h > 6) {
      float halfW = w / 2;
      float halfH = h / 2;
      subdivide(x, y, halfW, halfH, threshold, usePatterns, patternType, thickness, spacing);
      subdivide(x + halfW, y, halfW, halfH, threshold, usePatterns, patternType, thickness, spacing);
      subdivide(x, y + halfH, halfW, halfH, threshold, usePatterns, patternType, thickness, spacing);
      subdivide(x + halfW, y + halfH, halfW, halfH, threshold, usePatterns, patternType, thickness, spacing);
    } else {
      if (usePatterns) {
        squares.add(new SubdivisionSquare(x, y, w, h, patternType, thickness, spacing));
      } else {
        squares.add(new SubdivisionSquare(x, y, w, h, avgColor));
      }
    }
  }
  
  void drawQuads() {
    for (SubdivisionSquare s : squares) {
      s.drawSquare();
    }
  }
}

//////////////////////////
// Settings, Setup, and Draw Methods
//////////////////////////

// Use settings() for the size() call when using P3D
void settings() {
  size(APP_WIDTH, APP_HEIGHT, P3D);
}

void setup() {
  // Load default image and resize to the image area
  img = loadImage("mona_lisa.jpeg");
  if (img == null) {
    println("Default image not found. Exiting.");
    exit();
  }
  img.resize(IMAGE_WIDTH, IMAGE_HEIGHT);
  img.loadPixels();  // Preload pixel data
  
  quadtree = new Quadtree();
  cp5 = new ControlP5(this);
  
  int sidebarWidth = SIDEBAR_WIDTH;
  
  // --- Create GUI Controls in the sidebar ---
  
  // New toggles for multi-mode options:
  cp5.addToggle("ShowPixelation")
     .setPosition(20, 20)
     .setSize(50, 20)
     .setLabel("Pixelation")
     .setValue(showPixelation);
  
  cp5.addToggle("ShowLinePatterns")
     .setPosition(20, 50)
     .setSize(50, 20)
     .setLabel("Line Patterns")
     .setValue(showLinePatterns);
  
  cp5.addToggle("ShowBackground")
     .setPosition(20, 80)
     .setSize(50, 20)
     .setLabel("Background")
     .setValue(showBackgroundImage);
  
  // New toggle for CMYK mode:
  cp5.addToggle("CMYKMode")
     .setPosition(20, 110)
     .setSize(50, 20)
     .setLabel("CMYK")
     .setValue(cmykMode);
  
  // New toggle for overlaying CMYK layers:
  cp5.addToggle("OverlayCMYK")
     .setPosition(20, 140)
     .setSize(50, 20)
     .setLabel("Overlay")
     .setValue(overlayCMYK);
  
  // Threshold slider for quantization (applies in pixelation mode)
  thresholdSlider = cp5.addSlider("SubdivisionThreshold")
     .setPosition(20, 180)
     .setWidth(SIDEBAR_WIDTH - 40)
     .setRange(5, 50)
     .setValue(currentThreshold)
     .setLabel("Threshold");
  
  // Pattern type list (applies in line pattern mode)
  patternTypeList = cp5.addScrollableList("PatternType")
     .setPosition(20, 220)
     .setSize(SIDEBAR_WIDTH - 40, 100)
     .addItem("Horizontal", 0)
     .addItem("Vertical", 1)
     .addItem("Diagonal", 2)
     .addItem("Crosshatch", 3)
     .addItem("Hexagon", 4)
     .addItem("Circles", 5)
     .setLabel("Pattern Type")
     .setValue(0);
  
  // Sliders for line pattern parameters
  lineThicknessSlider = cp5.addSlider("LineThickness")
     .setPosition(20, 330)
     .setWidth(SIDEBAR_WIDTH - 40)
     .setRange(1, 10)
     .setValue(currentLineThickness)
     .setLabel("Line Thickness");
  
  lineSpacingSlider = cp5.addSlider("LineSpacing")
     .setPosition(20, 370)
     .setWidth(SIDEBAR_WIDTH - 40)
     .setRange(5, 50)
     .setValue(currentLineSpacing)
     .setLabel("Line Spacing");
  
  // Help text in the sidebar with roadmap notes
  cp5.addTextlabel("HelpLabel")
    .setPosition(20, 410)
    .setText("Help:\n- Adjust threshold.\n- Toggle pixelation, line patterns, background, and CMYK modes.\n- In CMYK mode, view four panels or an overlay composite.\n\nFuture ideas:\n- Per-layer fill customization\n- Export individual layers");
  
  // Load image button
  loadImageButton = cp5.addButton("LoadImage")
    .setPosition(20, 450)
    .setSize(SIDEBAR_WIDTH - 40, 30)
    .setLabel("Load Image");
  
  // --- Add listeners to update parameters ---
  
  cp5.get(Slider.class, "SubdivisionThreshold").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      currentThreshold = thresholdSlider.getValue();
      needsUpdate = true;
    }
  });
  
  cp5.get(ScrollableList.class, "PatternType").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      currentPatternType = int(patternTypeList.getValue());
      needsUpdate = true;
    }
  });
  
  cp5.get(Slider.class, "LineThickness").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      currentLineThickness = lineThicknessSlider.getValue();
      needsUpdate = true;
    }
  });
  
  cp5.get(Slider.class, "LineSpacing").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      currentLineSpacing = lineSpacingSlider.getValue();
      needsUpdate = true;
    }
  });
  
  cp5.get(Toggle.class, "ShowPixelation").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      showPixelation = cp5.get(Toggle.class, "ShowPixelation").getState();
      needsUpdate = true;
    }
  });
  
  cp5.get(Toggle.class, "ShowLinePatterns").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      showLinePatterns = cp5.get(Toggle.class, "ShowLinePatterns").getState();
      needsUpdate = true;
    }
  });
  
  cp5.get(Toggle.class, "ShowBackground").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      showBackgroundImage = cp5.get(Toggle.class, "ShowBackground").getState();
      // No recomputation needed for background toggle.
    }
  });
  
  cp5.get(Toggle.class, "CMYKMode").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      cmykMode = cp5.get(Toggle.class, "CMYKMode").getState();
      needsUpdate = true;
    }
  });
  
  cp5.get(Toggle.class, "OverlayCMYK").addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      overlayCMYK = cp5.get(Toggle.class, "OverlayCMYK").getState();
      // No recomputation needed for overlay toggle.
    }
  });
  
  updateQuadtree();
  needsUpdate = false;
}

void draw() {
  background(240);
  
  // --- Draw Sidebar ---
  fill(220);
  noStroke();
  rect(0, 0, SIDEBAR_WIDTH, height);
  
  // --- Update processing if parameters changed ---
  if (needsUpdate) {
    if (cmykMode) {
      updateCMYK();
    } else {
      updateQuadtree();
    }
    needsUpdate = false;
  }
  
  // --- Draw image or CMYK layers in the image area ---
  pushMatrix();
  translate(SIDEBAR_WIDTH, 0);
  
  if (cmykMode) {
    // In CMYK mode, show four panels or an overlay composite:
    if (overlayCMYK) {
      // Overlay composite (simple average blend as placeholder)
      if (compositeCMYK != null) {
        image(compositeCMYK, 0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
      }
    } else {
      // 2x2 grid: each image takes half width and half height
      if (cImg != null && mImg != null && yImg != null && kImg != null) {
        image(cImg, 0, 0, IMAGE_WIDTH/2, IMAGE_HEIGHT/2);
        image(mImg, IMAGE_WIDTH/2, 0, IMAGE_WIDTH/2, IMAGE_HEIGHT/2);
        image(yImg, 0, IMAGE_HEIGHT/2, IMAGE_WIDTH/2, IMAGE_HEIGHT/2);
        image(kImg, IMAGE_WIDTH/2, IMAGE_HEIGHT/2, IMAGE_WIDTH/2, IMAGE_HEIGHT/2);
      }
    }
  } else {
    // Normal mode: draw background and quadtree subdivisions
    if (showBackgroundImage) {
      image(img, 0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
    } else {
      fill(255);
      rect(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
    }
    if (showPixelation) {
      quadtree.drawQuads();
    }
  }
  
  popMatrix();
}

////////////////////////
// Quadtree Update Logic
////////////////////////

/**
 * Recomputes the quadtree subdivision using current parameters.
 * This is used in non-CMYK mode.
 */
void updateQuadtree() {
  quadtree.clear();
  if (showPixelation) {
    img.loadPixels();  // Ensure pixel data is current
    quadtree.subdivide(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT, currentThreshold, 
                       showLinePatterns, currentPatternType, currentLineThickness, currentLineSpacing);
  }
}

////////////////////////////
// CMYK Update Logic
////////////////////////////

/**
 * Updates the CMYK images (C, M, Y, K) and a composite overlay.
 * Uses a basic RGB-to-CMYK conversion formula and creates monochrome images.
 */
void updateCMYK() {
  // Initialize new images for each channel
  cImg = createImage(IMAGE_WIDTH, IMAGE_HEIGHT, RGB);
  mImg = createImage(IMAGE_WIDTH, IMAGE_HEIGHT, RGB);
  yImg = createImage(IMAGE_WIDTH, IMAGE_HEIGHT, RGB);
  kImg = createImage(IMAGE_WIDTH, IMAGE_HEIGHT, RGB);
  compositeCMYK = createImage(IMAGE_WIDTH, IMAGE_HEIGHT, RGB);
  
  img.loadPixels();
  cImg.loadPixels();
  mImg.loadPixels();
  yImg.loadPixels();
  kImg.loadPixels();
  compositeCMYK.loadPixels();
  
  for (int i = 0; i < IMAGE_WIDTH * IMAGE_HEIGHT; i++) {
    color orig = img.pixels[i];
    float r = red(orig) / 255.0;
    float g = green(orig) / 255.0;
    float b = blue(orig) / 255.0;
    
    // Compute K channel
    float K = 1 - max(r, max(g, b));
    float C = (K < 1) ? (1 - r - K) / (1 - K) : 0;
    float M = (K < 1) ? (1 - g - K) / (1 - K) : 0;
    float Y = (K < 1) ? (1 - b - K) / (1 - K) : 0;
    
    // Map channel values to grayscale (invert so that higher channel value means darker)
    int cVal = int(255 * (1 - C));
    int mVal = int(255 * (1 - M));
    int yVal = int(255 * (1 - Y));
    int kVal = int(255 * (1 - K));
    
    cImg.pixels[i] = color(cVal);
    mImg.pixels[i] = color(mVal);
    yImg.pixels[i] = color(yVal);
    kImg.pixels[i] = color(kVal);
    
    // Simple composite: average of the four channels (placeholder blend)
    int compVal = int((cVal + mVal + yVal + kVal) / 4.0);
    compositeCMYK.pixels[i] = color(compVal);
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

/**
 * Computes the average color for a region using preloaded pixel data.
 */
color getAverageColorRegion(float x, float y, float w, float h) {
  int sumR = 0, sumG = 0, sumB = 0, count = 0;
  for (int i = int(x); i < x + w; i++) {
    for (int j = int(y); j < y + h; j++) {
      int index = j * IMAGE_WIDTH + i;
      if (i < IMAGE_WIDTH && j < IMAGE_HEIGHT && index < img.pixels.length) {
        color c = img.pixels[index];
        sumR += int(red(c));
        sumG += int(green(c));
        sumB += int(blue(c));
        count++;
      }
    }
  }
  if (count == 0) return color(255);
  return color(sumR / count, sumG / count, sumB / count);
}

/**
 * Computes the average color variation for a region.
 * Variation is defined as the average Euclidean distance in RGB space
 * between each pixel and the region's average color.
 */
float getColorVariationRegion(float x, float y, float w, float h, color avgColor) {
  float totalVariation = 0;
  int count = 0;
  float avgR = red(avgColor), avgG = green(avgColor), avgB = blue(avgColor);
  
  for (int i = int(x); i < x + w; i++) {
    for (int j = int(y); j < y + h; j++) {
      int index = j * IMAGE_WIDTH + i;
      if (i < IMAGE_WIDTH && j < IMAGE_HEIGHT && index < img.pixels.length) {
        color c = img.pixels[index];
        float variation = dist(red(c), green(c), blue(c), avgR, avgG, avgB);
        totalVariation += variation;
        count++;
      }
    }
  }
  if (count == 0) return 0;
  return totalVariation / count;
}

/**
 * Generates a patterned color for a region.
 * This placeholder adjusts brightness based on the pattern type.
 * Future work: Replace with a more complex pattern-fill algorithm.
 */
color generatePatternForRegion(float x, float y, float w, float h, int patternType, float thickness, float spacing) {
  color baseColor = getAverageColorRegion(x, y, w, h);
  float factor = 0.8 + (patternType * 0.04);
  return color(red(baseColor) * factor, green(baseColor) * factor, blue(baseColor) * factor);
}

/**
 * Draws a pattern in the specified rectangular region.
 * Pattern types:
 *   0: Horizontal lines
 *   1: Vertical lines
 *   2: Diagonal lines (top-left to bottom-right)
 *   3: Crosshatch (horizontal + vertical)
 *   4: Alternating diagonal
 *   5: Grid of circles
 */
void drawPattern(float x, float y, float w, float h, int type, float thickness, float spacing) {
  stroke(0);
  strokeWeight(thickness);
  noFill();
  
  if (type == 0) { 
    // Horizontal lines
    for (float j = y; j < y + h; j += spacing) {
      line(x, j, x + w, j);
    }
  } else if (type == 1) {
    // Vertical lines
    for (float i = x; i < x + w; i += spacing) {
      line(i, y, i, y + h);
    }
  } else if (type == 2) {
    // Diagonal lines (top-left to bottom-right)
    for (float offset = -w; offset < h; offset += spacing) {
      line(x, y + max(0, offset), x + min(w, w + offset), y + min(h, offset + w));
    }
  } else if (type == 3) {
    // Crosshatch: horizontal + vertical
    for (float j = y; j < y + h; j += spacing) {
      line(x, j, x + w, j);
    }
    for (float i = x; i < x + w; i += spacing) {
      line(i, y, i, y + h);
    }
  } else if (type == 4) {
    // Alternating diagonal: alternate slope for each row
    for (float j = y; j < y + h; j += spacing) {
      if (((int)((j - y) / spacing)) % 2 == 0) {
        line(x, j, x + w, j + w);
      } else {
        line(x + w, j, x, j + w);
      }
    }
  } else if (type == 5) {
    // Grid of circles
    for (float i = x; i < x + w; i += spacing) {
      for (float j = y; j < y + h; j += spacing) {
        noFill();
        ellipse(i, j, thickness * 2, thickness * 2);
      }
    }
  }
}

////////////////////////////
// File Input Handling
////////////////////////////

/**
 * Handles file selection for loading a new image.
 */
public void fileSelected(File selection) {
  if (selection == null) {
    println("No file was selected, or the window was closed.");
  } else {
    String path = selection.getAbsolutePath();
    println("Loading new image from: " + path);
    PImage newImg = loadImage(path);
    if (newImg == null) {
      println("Could not load the image. Please select a valid image format.");
      return;
    }
    newImg.resize(IMAGE_WIDTH, IMAGE_HEIGHT);
    img = newImg;
    img.loadPixels();
    needsUpdate = true;
  }
}

/**
 * Triggered by the "Load Image" button in the GUI.
 */
public void LoadImage() {
  selectInput("Select an image to process:", "fileSelected");
}
