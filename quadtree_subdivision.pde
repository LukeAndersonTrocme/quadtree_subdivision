
PImage img;
ArrayList<sq> sqs;


void setup() {
  size(1000, 1000, P3D);
  img = loadImage("1.jpg");
  img.resize(width, height);
}

void draw() {
  sqs = new ArrayList<sq>();
  float threshold = map(mouseX, 0, width, 5, 50);
  adaptiveSubdivision(0, 0, width, height, threshold);

  for (int i = 0; i < sqs.size(); i++) {
    sq s = sqs.get(i);
    fill(s.c);
    rect(s.x, s.y, s.w, s.h);
  }
  print(threshold);
}
