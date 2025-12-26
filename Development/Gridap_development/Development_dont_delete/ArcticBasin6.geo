// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// It defines a cylindrical structure with specific parameters and points
// The geometry is defined using GMSH syntax and includes circles, lines, and surfaces
// The final volume is created by combining surfaces and defining physical groups
// The geometry is suitable for simulations or visualizations in GMSH
// ArcticBasin.geo
// twnh Jul 2025

// This .geo file works.

SetFactory("OpenCASCADE");

// Parameters for the Arctic Basin geometry

R  = 1.0;    // Radius of the top circles
H  = -1.0;    // Height of the cylinder
dH = 0.2*H;    // Height of the top rim
r  = R*0.6;    // Radius of the bottom circle

Cylinder(1) = {0,0,0, 0,0,dH, R};
Cone ( 10 ) = { 0, 0, dH, 0, 0, -1, R, r };

Physical Surface("Top") = {3};
Physical Surface("Wall") = {1};
Physical Surface("Bottom") = {4};
Physical Surface("Slope") = {2};

// Fuse (BooleanUnion) the two objects
BooleanUnion(11) = { Volume{1}; Delete; }{ Volume{10}; Delete; };  // Delete the original cylinder and cone after union;
Physical Volume("ArcticBasin") = {11}; // The resulting volume after the union
