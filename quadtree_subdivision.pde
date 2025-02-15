
// quadtree_subdivision.pde
import controlP5.*;
import java.io.File; // Needed for file selection
ArrayList<Integer> uniqueColors = new ArrayList<>();

PImage img;
ArrayList<sq> sqs;

// Instantiate the ControlP5 object
ControlP5 cp5;

// GUI elements
Slider thresholdSlider;
Button loadImageButton;

// The threshold we’ll use for the subdivision:
float currentThreshold = 10;

void setup() {
  size(1200, 1000, P3D);  // Increased width to accommodate a sidebar

  // Load default image
  img = loadImage("1.jpg");
  img.resize(900, height);  // Ensure the image doesn't take full width

  // Initialize array for storing subdivided regions
  sqs = new ArrayList<sq>();

  // Initialize ControlP5 for GUI
  cp5 = new ControlP5(this);

  int sidebarWidth = 250;  // Sidebar width

  // Subdivision Threshold Slider
  thresholdSlider = cp5.addSlider("SubdivisionThreshold")
    .setPosition(20, 40)
    .setWidth(sidebarWidth - 40)
    .setRange(5, 50)
    .setValue(currentThreshold)
    .setLabel("Color Variation Threshold");

  // Load Image Button
  loadImageButton = cp5.addButton("LoadImage")
    .setPosition(20, 80)
    .setSize(sidebarWidth - 40, 30)
    .setLabel("Load Image");

  // Toggle Button for Color vs. Pattern Mode
  cp5.addToggle("PatternMode")
    .setPosition(20, 130)
    .setSize(50, 20)
    .setLabel("Pattern Mode");

  // Pattern Selection Dropdown
  cp5.addScrollableList("PatternType")
    .setPosition(20, 170)
    .setSize(sidebarWidth - 40, 100)
    .addItem("Horizontal", 0)
    .addItem("Vertical", 1)
    .addItem("Diagonal", 2)
    .addItem("Crosshatch", 3)
    .addItem("Hexagon", 4)
    .addItem("Circles", 5)
    .setLabel("Select Pattern");

  // Line Thickness & Spacing Sliders
  cp5.addSlider("LineThickness")
    .setPosition(20, 280)
    .setWidth(sidebarWidth - 40)
    .setRange(1, 10)
    .setValue(2)
    .setLabel("Line Thickness");

  cp5.addSlider("LineSpacing")
    .setPosition(20, 320)
    .setWidth(sidebarWidth - 40)
    .setRange(5, 50)
    .setValue(20)
    .setLabel("Line Spacing");
}



void draw() {
  background(240);  // Set background for entire canvas

  // --- Draw Sidebar First ---
  fill(220);
  noStroke();
  rect(0, 0, 250, height);  // Left-aligned sidebar (always on the left)

  // --- Retrieve GUI values ---
  currentThreshold = thresholdSlider.getValue();
  boolean usePatterns = cp5.get(Toggle.class, "PatternMode").getState();
  int selectedPattern = int(cp5.get(ScrollableList.class, "PatternType").getValue());
  float lineThickness = cp5.get(Slider.class, "LineThickness").getValue();
  float lineSpacing = cp5.get(Slider.class, "LineSpacing").getValue();

  // --- Draw Subdivided Image (Restrict to Right Side) ---
  pushMatrix();
  translate(250, 0);  // Offset image to the right
  applySubdivision(usePatterns, selectedPattern, lineThickness, lineSpacing);
  popMatrix();
}






// Button-triggered update
public void GeneratePattern() {
  println("GeneratePattern clicked! Updating visualization...");

  boolean usePatterns = cp5.get(Toggle.class, "PatternMode").getState();
  int selectedPattern = int(cp5.get(ScrollableList.class, "PatternType").getValue());
  float lineThickness = cp5.get(Slider.class, "LineThickness").getValue();
  float lineSpacing = cp5.get(Slider.class, "LineSpacing").getValue();

  applySubdivision(usePatterns, selectedPattern, lineThickness, lineSpacing);
}


// Apply the quadtree subdivision with current settings
void applySubdivision(boolean usePatterns, int patternType, float thickness, float spacing) {
  sqs.clear();
  adaptiveSubdivision(0, 0, width, height, currentThreshold, usePatterns, patternType, thickness, spacing);
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

    // Load and resize image (Restrict to right side)
    img = loadImage(path);
    if (img == null) {
      println("Could not load the image. Make sure the file is a valid image format.");
      return;
    }
    img.resize(width - 250, height);
  }
}
