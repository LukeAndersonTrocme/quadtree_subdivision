
void adaptiveSubdivision(float x, float y, float w, float h, float threshold) {
  color avgColor = getAverageColor(x, y, w, h);
  float variation = getColorVariation(x, y, w, h, avgColor);

  if (variation > threshold && w > 6 && h > 6) {
    float halfW = w / 2;
    float halfH = h / 2;

    adaptiveSubdivision(x, y, halfW, halfH, threshold);
    adaptiveSubdivision(x + halfW, y, halfW, halfH, threshold);
    adaptiveSubdivision(x, y + halfH, halfW, halfH, threshold);
    adaptiveSubdivision(x + halfW, y + halfH, halfW, halfH, threshold);
  } else {
    sqs.add(new sq(x, y, w, h, avgColor));
  }
}

color getAverageColor(float x, float y, float w, float h) {
  float rSum = 0, gSum = 0, bSum = 0;
  int count = 0;
  for (int i = int(x); i < x + w; i++) {
    for (int j = int(y); j < y + h; j++) {
      if (i < img.width && j < img.height) {
        color c = img.get(i, j);
        rSum += red(c);
        gSum += green(c);
        bSum += blue(c);
        count++;
      }
    }
  }
  return color(rSum / count, gSum / count, bSum / count);
}

float getColorVariation(float x, float y, float w, float h, color avgColor) {
  float variation = 0;
  for (int i = int(x); i < x + w; i++) {
    for (int j = int(y); j < y + h; j++) {
      if (i < img.width && j < img.height) {
        color c = img.get(i, j);
        variation += dist(red(c), green(c), blue(c), red(avgColor), green(avgColor), blue(avgColor));
      }
    }
  }
  return variation / (w * h);
}
