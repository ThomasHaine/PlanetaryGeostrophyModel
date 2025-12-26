// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// It defines a cylindrical structure with specific parameters and points
// The geometry is defined using GMSH syntax and includes circles, lines, and surfaces
// The final volume is created by combining surfaces and defining physical groups
// The geometry is suitable for simulations or visualizations in GMSH
// ArcticBasin.geo
// twnh Jun 2025

SetFactory("OpenCASCADE");

// Parameters for the Arctic Basin geometry
N = 16;
h = 1/N;
R=1.0; // Radius of the top circles
H=-1;    // Height of the cylinder
dH=0.2*H; //Height of the top rim
r=R*0.6; // Radius of the bottom circle

// Top circle
Point(1) = { 0, 0, 0, h}; // Center Point of circle
Point(2) = { R, 0, 0, h}; // Point on the top circle
Point(3) = {-R, 0, 0, h}; // Point on the top circle
Circle(1) = {2, 1, 3};
Circle(2) = {3, 1, 2};

// Middle circle
Point(4) = { 0, 0,dH, h}; // Center Point of circle
Point(5) = { R, 0,dH, h}; // Point on the middle circle
Point(6) = {-R, 0,dH, h}; // Point on the middle circle
Circle(3) = {5, 4, 6};
Circle(4) = {6, 4, 5};

// Bottom circle
Point(7) = { 0, 0, H, h}; // Center Point of circle
Point(8) = { r, 0, H, h}; // Point on the bottom circle
Point(9) = {-r, 0, H, h}; // Point on the bottom circle
Circle(5) = {8, 7, 9};
Circle(6) = {9, 7, 8};

// Circle above slope
Point(11) = { r, 0, 0, h}; // Point on the slope circle
Point(12) = {-r, 0, 0, h}; // Point on the slope circle
Circle(17) = {11, 1,12};
Circle(18) = {12, 1,11};
Line(21) = {3, 12};
Line(22) = {2, 11};

Line Loop(1) = {1, 2};  // Top loop
Line Loop(2) = {3, 4};  // Middle loop
Line Loop(3) = {5, 6};  // Bottom loop

Line(7) = {2, 5};  // Vertical line from top to middle
Line(8) = {3, 6};  // Vertical line from top to middle
Line(9) = {5, 8};  // Vertical line from middle to bottom
Line(10) = {6, 9}; // Vertical line from middle to bottom

Line Loop(40) = {-1, 7, 3, -8}; // Upper wall half line loop
Surface(41) = {40}; // Upper wall half surface
Line Loop(42) = { 2, 7,-4, -8}; // Upper wall half line loop
Surface(43) = {42}; // Upper wall half surface

Line Loop(44) = { 3, 10, -5, -9}; // Slope half line loop
Surface(45) = {44}; // Slope half surface
Line Loop(46) = {-4, 10, 6,-9}; // Slope half line loop
Surface(47) = {46}; // Slope half surface

// Freshening patches
Line Loop(48) = {-2, 21,18, -22}; // Half slope upper surface
Surface(49) = {48}; // Half slope upper surface
Line Loop(50) = {1, 21, -17, -22}; // Half slope upper surface
Surface(51) = {50}; // Half slope upper surface

Plane Surface(30) = {1}; // Top surface
Plane Surface(31) = {3}; // Bottom surface

Surface Loop(32) = {30, 41, 43, 45, 47, 31}; // Combine all the surfaces

Volume(200) = {32}; // Create the volume

// Warming patch
Point(101) = { -R*0.9659, -R*0.2588,  0, h}; // Upper end of patch
Point(102) = { -R*0.9659, -R*0.2588, dH, h}; // Lower end of patch
Line(103) = {101, 102};
Circle(105) = {3, 1, 101};
Circle(106) = {6, 4, 102};
Line Loop(104) = {8,106,-103,-105};     // Warming patch line loop
Plane Surface(107) = {104};             // Warming patch surface

// Physical groups  
//Physical Surface("WarmingPatch") = {107};
//Physical Surface("Top") = {30};
//Physical Surface("Bottom") = {31};    
//Physical Surface("FresheningPatch") = {49,51};  
//Physical Surface("Wall") = {41,43};
//Physical Surface("Slope") = {45,47};
Physical Volume("Domain") = {200};

// At the end of your .geo
// This collects all surface IDs and assigns to a dummy group
allsurf[] = Surface{:};
Physical Surface("AllSurfaces") = allsurf[];
