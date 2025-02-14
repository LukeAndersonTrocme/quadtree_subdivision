# Quadtree Subdivision

This project recursively divides an image into sections based on color variation. If a section has a high color variation, it will be subdivided further. Once a specified threshold is reached, the average color of that section is saved and later redrawn on the canvas.

## Forked Repository
This is a **fork** of the original project from [`https://github.com/urchinemerald/quadtree_subdivision`](https://github.com/urchinemerald/quadtree_subdivision). The goal of this fork is to further develop and refine the quadtree-based image processing technique, with additional features planned for future versions. For now it's just a wrapper of the original functions from urchinemerald. (Thanks for the cool work!!)

## Adjustable Parameters
- **Subdivision Threshold:** Determines the level of detail in the quadtree division. The threshold is currently controlled by a GUI slider.
- **Load Custom Images:** Users can load their own images into the program via the "Load Image" button.

## Installation & Usage
1. **Download** the pre-built application from the [Releases](https://github.com/LukeAndersonTrocme/quadtree_subdivision) section.
2. **Extract the ZIP file** and open the corresponding folder for your operating system.
3. **Run the application** by double-clicking on the executable `.app` on macOS.

## Development Status
This project is **currently under development**, and new features will be added. The current version serves as a **test run** to set up a playground for future image processing techniques.

### Upcoming Features
- **Pattern-based subdivisions** instead of solid color fills.
- **Additional GUI elements** for more user control.
- **???**

## Compiling from Source
For developers interested in modifying or contributing to the project:
1. Clone the repository:
   ```sh
   git clone https://github.com/LukeAndersonTrocme/quadtree_subdivision.git
   ```
2. Open the project in **Processing** (ensure `ControlP5` library is installed).
3. Run the sketch or export the application from Processing.

## License
This project is licensed under the MIT License. 