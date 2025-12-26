// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// It defines a cylindrical structure with specific parameters and points
// The geometry is defined using GMSH syntax and includes circles, lines, and surfaces
// The final volume is created by combining surfaces and defining physical groups
// The geometry is suitable for simulations or visualizations in GMSH
// ArcticBasin.geo
// twnh Jul 2025

// This .geo file errors on meshing but I don't know why.


SetFactory("OpenCASCADE");
// Geometry.Tolerance = 1e-6; // (adjust as needed)
// Mesh.CharacteristicLengthFromCurvature = 1;
// Mesh.MinimumElementsPerTwoPi = 30;


// Parameters for the Arctic Basin geometry
// R  = 1.0e6;    // Radius of the top circles
// H  = -2000;    // Height of the cylinder
R  = 1.0;    // Radius of the top circles
H  = -1.0;    // Height of the cylinder
dH = 0.2*H;    // Height of the top rim
r  = R*0.6;    // Radius of the bottom circle
WP_theta = Pi/10; // Warming patch angle in radians

// Top circle
Circle(1) = {0, 0, 0, R, 0, WP_theta}; 
Circle(2) = {0, 0, 0, R, WP_theta, 0};
out1[] = Extrude {0, 0, dH} { Curve {1}; } ;
// Printf("Extruded tags '%g', '%g', '%g', '%g'", out[0], out[1], out[2], out[3]);
Physical Surface("WarmingPatch") = {out1[1]};
out2[] = Extrude {0, 0, dH} { Curve {2}; } ;
Physical Surface("Wall") = {out2[1]};

// Bottom circle
Circle(11) = {0, 0, H, r, 0, WP_theta};
Circle(12) = {0, 0, H, r, WP_theta, 0};
Curve Loop(13) = {11,12};
Surface(14) = {13};
Physical Surface("Bottom") = {14};

// Circle above slope
Circle(21) = {0 ,0, 0, r, 0, WP_theta};
Circle(22) = {0 ,0, 0, r, WP_theta, 0};
Curve Loop(23) = {21,22};
Surface(24) = {23};
Physical Surface("TopInner") = {24};

// Connecting lines for the top circle to the middle circle
Line(31) = { 6, 10};        // How to get these point tags automatically?  They're from the gmsh app mouse-over at the moment...
out3[] = Extrude {{0,0,1}, {0,0,0}, 2*Pi} { Line {31}; } ;
Physical Surface("Slope") = {out3[1]};

// Freshening patch
Curve Loop(40) = {1,2};
Surface(41) = {40};
BooleanDifference(42) = { Surface{41}; Delete;}{ Surface{24}; };
Physical Surface("FresheningPatch") = {42};

// Combine all the surfaces
Surface Loop(50) = {42,14,24,out1[1],out2[1],out3[1]}; 
// Surface Loop(50) = {42,14,24,2,1,25}; 
Volume(51) = {50};
Physical Volume("Domain") = {51};

// Coherence;