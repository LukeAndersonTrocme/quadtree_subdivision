/* autogenerated by Processing revision 1295 on 2025-02-14 */
import processing.core.*;
import processing.data.*;
import processing.event.*;
import processing.opengl.*;

import controlP5.*;
import java.io.File;

import java.util.HashMap;
import java.util.ArrayList;
import java.io.File;
import java.io.BufferedReader;
import java.io.PrintWriter;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;

public class quadtree_subdivision extends PApplet {

// quadtree_subdivision.pde

 // Needed for file selection

PImage img;
ArrayList<sq> sqs;

// Instantiate the ControlP5 object
ControlP5 cp5;

// GUI elements
Slider thresholdSlider;
Button loadImageButton;

// The threshold we’ll use for the subdivision:
float currentThreshold = 10;

public void setup() {
  /* size commented out by preprocessor */;

  // Load a default image (if desired)
  img = loadImage("1.jpg");
  img.resize(width, height);

  // Initialize array for storing subdivided squares
  sqs = new ArrayList<sq>();

  // Initialize ControlP5
  cp5 = new ControlP5(this);

  // Create a slider for controlling the threshold
  thresholdSlider = cp5.addSlider("SubdivisionThreshold")
    .setPosition(20, 20)
    .setWidth(200)
    .setRange(5, 50)  // Minimum & maximum threshold
    .setValue(currentThreshold)
    .setLabel("Color Variation Threshold");

  // Create a button to load a new image
  loadImageButton = cp5.addButton("LoadImage")
    .setPosition(20, 60)
    .setSize(100, 30)
    .setLabel("Load Image");
}

public void draw() {
  background(255);

  // Retrieve the threshold from the slider
  currentThreshold = thresholdSlider.getValue();

  // Clear the ArrayList each frame and re-generate squares
  sqs.clear();

  // Perform the adaptive subdivision with our current threshold
  adaptiveSubdivision(0, 0, width, height, currentThreshold);

  // Draw each subdivided region
  noStroke();
  for (int i = 0; i < sqs.size(); i++) {
    sq s = sqs.get(i);
    fill(s.c);
    rect(s.x, s.y, s.w, s.h);
  }

  // Display the threshold in the console (optional)
  // print(currentThreshold + " ");
}

// This function is automatically called by ControlP5 when the "LoadImage" button is clicked
public void LoadImage() {
  // Use Processing's file chooser
  selectInput("Select an image to process:", "fileSelected");
}

// Callback for file chooser
public void fileSelected(File selection) {
  if (selection == null) {
    println("No file was selected, or the window was closed.");
  } else {
    String path = selection.getAbsolutePath();
    println("Loading new image from: " + path);

    // Load and resize
    img = loadImage(path);
    if (img == null) {
      println("Could not load the image. Make sure the file is a valid image format.");
      return;
    }
    img.resize(width, height);
  }
}
// adaptiveSubdivision.pde

public void adaptiveSubdivision(float x, float y, float w, float h, float threshold) {
  int avgColor = getAverageColor(x, y, w, h);
  float variation = getColorVariation(x, y, w, h, avgColor);

  if (variation > threshold && w > 6 && h > 6) {
    float halfW = w / 2;
    float halfH = h / 2;

    adaptiveSubdivision(x,      y,      halfW, halfH, threshold);
    adaptiveSubdivision(x+halfW, y,     halfW, halfH, threshold);
    adaptiveSubdivision(x,      y+halfH, halfW, halfH, threshold);
    adaptiveSubdivision(x+halfW, y+halfH, halfW, halfH, threshold);
  } else {
    sqs.add(new sq(x, y, w, h, avgColor));
  }
}

public int getAverageColor(float x, float y, float w, float h) {
  float rSum = 0, gSum = 0, bSum = 0;
  int count = 0;
  for (int i = PApplet.parseInt(x); i < x + w; i++) {
    for (int j = PApplet.parseInt(y); j < y + h; j++) {
      if (i < img.width && j < img.height && i >= 0 && j >= 0) {
        int c = img.get(i, j);
        rSum += red(c);
        gSum += green(c);
        bSum += blue(c);
        count++;
      }
    }
  }
  if (count == 0) return color(255);
  return color(rSum / count, gSum / count, bSum / count);
}

public float getColorVariation(float x, float y, float w, float h, int avgColor) {
  float variation = 0;
  float avgR = red(avgColor);
  float avgG = green(avgColor);
  float avgB = blue(avgColor);

  int validCount = 0;
  for (int i = PApplet.parseInt(x); i < x + w; i++) {
    for (int j = PApplet.parseInt(y); j < y + h; j++) {
      if (i < img.width && j < img.height && i >= 0 && j >= 0) {
        int c = img.get(i, j);
        variation += dist(red(c), green(c), blue(c), avgR, avgG, avgB);
        validCount++;
      }
    }
  }
  if (validCount == 0) return 0;
  return variation / validCount;
}
class sq {
  float x, y, w, h;
  int c;
  public sq(float x, float y, float w, float h, int c) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.c = c;
  }
}


  public void settings() { size(1000, 1000, P3D); }

  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "quadtree_subdivision" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
