// quadtree_subdivision.pde
import controlP5.*;
import java.io.File; // Needed for file selection

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
  size(1000, 1000, P3D);

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

void draw() {
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
